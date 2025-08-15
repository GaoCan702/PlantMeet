import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/error_demo_screen.dart';
import 'screens/embedded_model_manager_screen.dart';
import 'screens/mnn_chat_config_screen.dart';
import 'screens/cloud_service_config_screen.dart';
import 'screens/model_chat_test_screen.dart';
import 'services/app_state.dart';
import 'services/database_service.dart';
import 'services/database.dart';
import 'services/onboarding_service.dart';
import 'services/embedded_model_service.dart';
import 'services/model_storage_manager.dart';
import 'services/device_capability_detector.dart';
import 'services/simple_model_downloader.dart';
import 'services/gemma_inference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库服务
  final database = AppDatabase();
  final databaseService = DatabaseService(database);

  // 初始化应用内模型服务
  final storageManager = ModelStorageManager();
  final capabilityDetector = DeviceCapabilityDetector();
  final simpleDownloader = SimpleModelDownloader(storageManager);
  final inferenceService = GemmaInferenceService(
    storageManager,
    capabilityDetector,
  );
  final embeddedModelService = EmbeddedModelService(
    storageManager: storageManager,
    capabilityDetector: capabilityDetector,
    downloader: simpleDownloader,
    inferenceService: inferenceService,
  );

  // 初始化应用状态
  final appState = AppState(databaseService: databaseService);

  // 仅初始化应用状态，延后模型初始化
  await appState.initialize();

  // 检查是否显示新手引导
  final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => appState),
        ChangeNotifierProvider(create: (context) => embeddedModelService),
      ],
      child: PlantMeetApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );

  // 首帧渲染后再初始化本地模型服务，避免阻塞冷启动
  WidgetsBinding.instance.addPostFrameCallback((_) {
    embeddedModelService.initialize();
  });
}

class PlantMeetApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const PlantMeetApp({super.key, required this.hasSeenOnboarding});

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
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
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
        '/embedded-model-manager': (context) =>
            const EmbeddedModelManagerScreen(),
        '/mnn-chat-config': (context) => const MNNChatConfigScreen(),
        '/cloud-service-config': (context) => const CloudServiceConfigScreen(),
        '/model-chat-test': (context) => const ModelChatTestScreen(),
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
