import '../models/recognition_result.dart';

/// 模拟识别服务 - 提供生活化的植物识别结果
class MockRecognitionService {
  /// 生成生活化的植物识别结果示例
  static RecognitionResponse generateMockResponse({String? plantType}) {
    switch (plantType) {
      case 'sunflower':
        return _generateSunflowerResult();
      case 'rose':
        return _generateRoseResult();
      case 'cactus':
        return _generateCactusResult();
      case 'bamboo':
        return _generateBambooResult();
      default:
        return _generateCommonPlantResult();
    }
  }

  static RecognitionResponse _generateSunflowerResult() {
    final results = [
      RecognitionResult(
        id: 'sunflower_1',
        name: '向日葵',
        nickname: '太阳花',
        confidence: 0.92,
        description: '一朵永远向着太阳的花，象征着希望和积极向上的态度。黄色的花瓣像太阳一样温暖，是夏天最受欢迎的花朵之一。',
        features: ['黄色大花盘', '高大茎杆', '心形叶片', '花盘会跟随太阳转动'],
        safety: const SafetyInfo(
          level: SafetyLevel.safe,
          description: '完全安全，可以近距离观赏',
          warnings: [],
        ),
        care: const CareInfo(
          difficulty: '简单',
          water: '需要充足水分',
          light: '全日照',
          temperature: '15-25°C',
          tips: [
            '种植时选择向阳的位置',
            '生长期需要大量水分',
            '可以采集瓜子食用',
            '花期可达2-3个月'
          ],
        ),
        season: '夏季(6-9月)',
        locations: ['花园', '田野', '公园', '阳台'],
        funFact: '向日葵的花盘其实由1000-2000朵小花组成，我们平时看到的"花瓣"实际上是外围的舌状花！而且年轻的向日葵确实会跟随太阳转动，这个现象叫做"向日性"。',
        tags: ['观赏植物', '经济作物', '夏季花卉', '易种植'],
        scientificName: 'Helianthus annuus',
        family: '菊科向日葵属',
      ),
    ];

    return RecognitionResponse.success(
      results: results,
      method: RecognitionMethod.local,
    );
  }

  static RecognitionResponse _generateRoseResult() {
    final results = [
      RecognitionResult(
        id: 'rose_1',
        name: '月季花',
        nickname: '月月红',
        confidence: 0.87,
        description: '被誉为"花中皇后"的经典花卉，四季开花，花色丰富。是爱情和美丽的象征，也是很多城市的市花。',
        features: ['层叠花瓣', '带刺茎杆', '复叶', '花香浓郁'],
        safety: const SafetyInfo(
          level: SafetyLevel.caution,
          description: '茎杆有刺，触碰时需要小心',
          warnings: ['茎杆有尖刺，容易划伤皮肤', '修剪时建议佩戴手套'],
        ),
        care: const CareInfo(
          difficulty: '适中',
          water: '适量浇水',
          light: '半日照',
          temperature: '10-25°C',
          tips: [
            '定期修剪枯枝促进开花',
            '春季施肥效果最佳',
            '注意预防蚜虫和黑斑病',
            '冬季需要防寒保护'
          ],
        ),
        season: '全年(春夏最盛)',
        locations: ['花园', '公园', '阳台', '庭院'],
        funFact: '月季花的香味不仅好闻，还有天然的杀菌作用！而且不同颜色的月季代表不同的花语：红色代表热恋，粉色代表初恋，白色代表纯洁。',
        tags: ['观赏植物', '香花植物', '庭院花卉', '切花材料'],
        scientificName: 'Rosa chinensis',
        family: '蔷薇科蔷薇属',
      ),
      RecognitionResult(
        id: 'rose_2',
        name: '玫瑰花',
        confidence: 0.73,
        description: '经典的爱情花卉，花瓣厚实，香味浓郁。常用于制作精油和香水。',
        features: ['厚实花瓣', '强烈香味', '茎刺密集'],
        safety: const SafetyInfo(
          level: SafetyLevel.caution,
          description: '茎杆有密集尖刺',
          warnings: ['茎刺比月季更密集更尖锐'],
        ),
        season: '春夏季',
        locations: ['花园', '温室'],
        tags: ['香料植物', '观赏植物'],
        scientificName: 'Rosa rugosa',
        family: '蔷薇科蔷薇属',
      ),
    ];

    return RecognitionResponse.success(
      results: results,
      method: RecognitionMethod.local,
    );
  }

  static RecognitionResponse _generateCactusResult() {
    final results = [
      RecognitionResult(
        id: 'cactus_1',
        name: '仙人掌',
        nickname: '仙巴掌',
        confidence: 0.95,
        description: '沙漠中的生存专家，以其顽强的生命力和独特的外形而著名。是最好养的植物之一，几乎不需要特别照料。',
        features: ['厚实肉质茎', '尖锐刺毛', '无叶片', '开黄色小花'],
        safety: const SafetyInfo(
          level: SafetyLevel.caution,
          description: '全身布满尖刺，触碰需要小心',
          warnings: ['刺毛细小且尖锐，扎进皮肤不易拔出', '移植时必须戴厚手套', '刺毛可能引起皮肤过敏'],
        ),
        care: const CareInfo(
          difficulty: '极简单',
          water: '很少浇水',
          light: '全日照',
          temperature: '5-35°C',
          tips: [
            '每月浇水1-2次即可',
            '冬季几乎不用浇水',
            '喜欢透气性好的沙质土壤',
            '可以放在阳光最充足的地方'
          ],
        ),
        season: '全年(春夏生长旺盛)',
        locations: ['阳台', '办公室', '室内', '花园'],
        funFact: '仙人掌的刺其实是退化的叶片！这样可以减少水分流失。而且仙人掌开花时非常美丽，有些品种的花朵比植物本身还要大！',
        tags: ['多肉植物', '室内植物', '耐旱植物', '新手友好'],
        scientificName: 'Opuntia dillenii',
        family: '仙人掌科仙人掌属',
      ),
    ];

    return RecognitionResponse.success(
      results: results,
      method: RecognitionMethod.local,
    );
  }

  static RecognitionResponse _generateBambooResult() {
    final results = [
      RecognitionResult(
        id: 'bamboo_1',
        name: '竹子',
        nickname: '青竹',
        confidence: 0.89,
        description: '中国传统文化中的"君子"植物，象征着坚韧不拔、虚心有节的品格。生长速度极快，用途广泛。',
        features: ['中空竹杆', '竹节明显', '细长叶片', '丛生或散生'],
        safety: const SafetyInfo(
          level: SafetyLevel.safe,
          description: '安全无毒，可以放心接触',
          warnings: [],
        ),
        care: const CareInfo(
          difficulty: '简单',
          water: '喜欢湿润',
          light: '半阴至全日照',
          temperature: '5-35°C',
          tips: [
            '生长速度快，需要定期修剪',
            '喜欢湿润但不能积水',
            '春季是最佳种植时间',
            '可以用竹叶泡茶清热解毒'
          ],
        ),
        season: '全年(春夏生长最快)',
        locations: ['庭院', '公园', '山地', '河边'],
        funFact: '有些竹子的生长速度能达到每天35厘米，是世界上生长最快的植物！而且竹子开花后会死亡，但有些竹种要几十年甚至上百年才开一次花。',
        tags: ['观赏植物', '经济植物', '传统文化', '环保材料'],
        scientificName: 'Bambuseae',
        family: '禾本科竹亚科',
      ),
    ];

    return RecognitionResponse.success(
      results: results,
      method: RecognitionMethod.local,
    );
  }

  static RecognitionResponse _generateCommonPlantResult() {
    final results = [
      RecognitionResult(
        id: 'green_plant_1',
        name: '绿萝',
        nickname: '黄金葛',
        confidence: 0.78,
        description: '最受欢迎的室内观叶植物之一，被称为"生命之花"。净化空气效果好，养护简单，适合新手。',
        features: ['心形叶片', '攀援茎', '气生根', '叶面光泽'],
        safety: const SafetyInfo(
          level: SafetyLevel.caution,
          description: '轻微毒性，不要误食',
          warnings: ['汁液有轻微毒性', '避免儿童和宠物误食', '修剪时建议戴手套'],
        ),
        care: const CareInfo(
          difficulty: '极简单',
          water: '见干见湿',
          light: '散射光',
          temperature: '15-25°C',
          tips: [
            '可以水培也可以土培',
            '定期向叶片喷水增加湿度',
            '剪下来的枝条可以扦插繁殖',
            '放在明亮但避免直射的位置'
          ],
        ),
        season: '全年',
        locations: ['室内', '办公室', '卫生间', '客厅'],
        funFact: '绿萝有"甲醛克星"的称号，一盆绿萝在10平米的房间内可以吸收87%的甲醛！而且它还能24小时释放氧气。',
        tags: ['室内植物', '净化空气', '观叶植物', '新手友好'],
        scientificName: 'Epipremnum aureum',
        family: '天南星科绿萝属',
      ),
      RecognitionResult(
        id: 'pothos_1',
        name: '常春藤',
        confidence: 0.65,
        description: '经典的攀援观叶植物，叶形优美，适应性强。',
        features: ['掌状裂叶', '攀援能力强', '常绿'],
        safety: const SafetyInfo(
          level: SafetyLevel.caution,
          description: '有轻微毒性',
          warnings: ['避免误食'],
        ),
        season: '全年',
        locations: ['室内', '庭院'],
        tags: ['攀援植物', '观叶植物'],
        scientificName: 'Hedera helix',
        family: '五加科常春藤属',
      ),
    ];

    return RecognitionResponse.success(
      results: results,
      method: RecognitionMethod.local,
    );
  }

  /// 生成识别失败的响应
  static RecognitionResponse generateErrorResponse() {
    return RecognitionResponse.error(
      error: '图片太模糊了，建议在光线充足的环境下重新拍摄，并确保植物特征清晰可见。',
      method: RecognitionMethod.local,
    );
  }

  /// 生成空结果响应
  static RecognitionResponse generateEmptyResponse() {
    return RecognitionResponse.success(
      results: [],
      method: RecognitionMethod.local,
    );
  }

  /// 根据置信度和安全等级生成合适的用户提示
  static String generateUserGuidance(RecognitionResult result) {
    final guidance = StringBuffer();
    
    // 置信度指导
    if (result.confidence < 0.6) {
      guidance.write('识别结果仅供参考，建议从不同角度再次拍摄。');
    } else if (result.confidence >= 0.9) {
      guidance.write('识别结果非常可靠！');
    } else {
      guidance.write('识别结果比较可靠，可以作为参考。');
    }
    
    // 安全性指导
    switch (result.safety.level) {
      case SafetyLevel.toxic:
      case SafetyLevel.dangerous:
        guidance.write('\n⚠️ 重要提醒：这种植物有毒性，请勿触摸或食用，远离儿童和宠物。');
        break;
      case SafetyLevel.caution:
        guidance.write('\n⚠️ 注意：此植物需要小心处理，请注意安全。');
        break;
      case SafetyLevel.safe:
        guidance.write('\n✅ 好消息：这种植物是安全的，可以放心观赏。');
        break;
      case SafetyLevel.unknown:
        guidance.write('\n❓ 安全信息未确认，建议谨慎处理。');
        break;
    }
    
    return guidance.toString();
  }
}