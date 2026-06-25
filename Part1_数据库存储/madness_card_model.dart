/// =====================================================
/// 文件：lib/models/madness_card_model.dart
/// 功能：发疯卡片数据模型
/// 描述：定义 MadnessCard 类，包含字段、toMap、fromMap 工厂方法
/// =====================================================

/// 发疯卡片数据模型
class MadnessCard {
  /// 自增主键，插入前为 null
  final int? id;

  /// 表情符号（必填）
  final String emoji;

  /// 渐变起始颜色，十六进制字符串（如 '#FF6B6B'）
  final String startColor;

  /// 渐变结束颜色，十六进制字符串
  final String endColor;

  /// 用户输入或 AI 生成的"发疯语录"
  final String userText;

  /// 创建日期，精确到秒
  final DateTime createDate;

  const MadnessCard({
    this.id,
    required this.emoji,
    required this.startColor,
    required this.endColor,
    required this.userText,
    required this.createDate,
  });

  /// 将模型转为 Map，用于数据库存储
  /// DateTime 转为 millisecondsSinceEpoch 以 INTEGER 形式入库
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'emoji': emoji,
      'startColor': startColor,
      'endColor': endColor,
      'userText': userText,
      'createDate': createDate.millisecondsSinceEpoch,
    };
  }

  /// 从数据库 Map 构建 MadnessCard 实例
  /// 将毫秒时间戳转回 DateTime
  factory MadnessCard.fromMap(Map<String, dynamic> map) {
    return MadnessCard(
      id: map['id'] as int?,
      emoji: map['emoji'] as String,
      startColor: map['startColor'] as String,
      endColor: map['endColor'] as String,
      userText: map['userText'] as String,
      createDate: DateTime.fromMillisecondsSinceEpoch(map['createDate'] as int),
    );
  }

  @override
  String toString() {
    return 'MadnessCard(id: $id, emoji: $emoji, userText: $userText, createDate: $createDate)';
  }
}
