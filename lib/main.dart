import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/error_demo_screen.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';
import 'services/database.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final database = AppDatabase();
  final databaseService = DatabaseService(database);
  final appState = AppState(databaseService: databaseService);
  
  await appState.initialize();
  
  // 检查是否显示新手引导
  final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => appState,
      child: PlantMeetApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class PlantMeetApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const PlantMeetApp({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantMeet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      initialRoute: hasSeenOnboarding ? '/home' : '/onboarding',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/gallery': (context) => const GalleryScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/error-demo': (context) => const ErrorDemoScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/plant-detail') {
          final speciesId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => PlantDetailScreen(speciesId: speciesId),
          );
        }
        return null;
      },
    );
  }
}