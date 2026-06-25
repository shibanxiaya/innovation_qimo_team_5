/// =====================================================
/// 文件：lib/screens/stats_page.dart
/// 功能：发疯周报 - 情绪统计与饼图
/// 描述：统计7天内Emoji使用频率，fl_chart饼图展示，
///        支持生成长图保存到相册
/// =====================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/madness_card_model.dart';
import '../services/madness_database.dart';
import '../utils/screenshot_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // ============ 状态 ============

  /// 本周卡片数据
  List<MadnessCard> _weeklyCards = [];

  /// Emoji -> 出现次数
  Map<String, int> _emojiCount = {};

  /// 是否正在加载
  bool _isLoading = true;

  /// 用于截图长图的 GlobalKey
  final GlobalKey _reportKey = GlobalKey();

  // ============ Emoji 颜色映射 ============
  static const Map<String, Color> _emojiColors = {
    '🤯': Color(0xFFE74C3C), // 红色系
    '😤': Color(0xFFFF6B35), // 橙色系
    '🥵': Color(0xFFFF9F43), // 暖橙
    '🤪': Color(0xFF9B59B6), // 紫色系
    '😭': Color(0xFF3498DB), // 蓝色系
    '🥳': Color(0xFFF1C40F), // 黄色系
    '🤬': Color(0xFFC0392B), // 深红
    '😎': Color(0xFF2ECC71), // 绿色系
    '🫠': Color(0xFF95A5A6), // 灰色系
    '🤡': Color(0xFFE67E22), // 棕色系
  };

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  /// ============ 加载本周数据 ============
  Future<void> _loadWeeklyData() async {
    try {
      setState(() => _isLoading = true);

      final now = DateTime.now();
      // 往前推7天
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // 获取所有卡片，手动筛选7天内的
      final allCards = await DatabaseService().getAllCards();

      _weeklyCards = allCards.where((card) {
        return card.createDate.isAfter(sevenDaysAgo) ||
            card.createDate
                .isAtSameMomentAs(sevenDaysAgo);
      }).toList();

      // 统计 Emoji 出现次数
      _emojiCount = {};
      for (final card in _weeklyCards) {
        _emojiCount[card.emoji] = (_emojiCount[card.emoji] ?? 0) + 1;
      }

      setState(() => _isLoading = false);
      print(
          '📊 本周发疯统计数据已加载: ${_weeklyCards.length} 条记录, ${_emojiCount.length} 种情绪');
    } catch (e) {
      print('❌ 加载本周统计数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// ============ UI ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '📊 发疯周报',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWeeklyData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            )
          : _weeklyCards.isEmpty
              ? _buildEmptyState()
              : _buildReportContent(),
    );
  }

  /// ======== 空状态 ========
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.emoji_emotions_outlined,
              size: 60,
              color: Colors.purpleAccent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '本周还没发疯，快去创作吧！',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '回到首页，选择表情，写下你的发疯语录',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// ======== 报告内容（可截图区域） ========
  Widget _buildReportContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: RepaintBoundary(
        key: _reportKey,
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ---- 标题 ----
            const Text(
              '📊 本周发疯情绪占比',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${DateTime.now().subtract(const Duration(days: 7)).toString().substring(0, 10)} ~ ${DateTime.now().toString().substring(0, 10)}',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ---- 饼图 ----
            SizedBox(
              height: 240,
              child: _weeklyCards.isEmpty
                  ? const Center(
                      child: Text('暂无数据',
                          style: TextStyle(color: Colors.white54)),
                    )
                  : PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // ---- 统计详情 ----
            _buildStatsDetail(),

            const SizedBox(height: 24),

            // ---- 生成周报长图按钮 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                onPressed: () => _saveReportToGallery(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('生成周报长图'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ======== 构建饼图扇区 ========
  List<PieChartSectionData> _buildPieChartSections() {
    final total = _emojiCount.values.fold<int>(0, (sum, c) => sum + c);
    if (total == 0) return [];

    return _emojiCount.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = _emojiColors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        radius: 60,
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  /// ======== 统计详情列表 ========
  Widget _buildStatsDetail() {
    final total = _emojiCount.values.fold<int>(0, (sum, c) => sum + c);

    // 按次数降序排列
    final sortedEntries = _emojiCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '情绪分布详情',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 汇总行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('本周总计', style: TextStyle(color: Colors.white54)),
              Text(
                '$total 次发疯记录',
                style: const TextStyle(
                    color: Colors.purpleAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),

          // 各 Emoji 详情
          ...sortedEntries.map((entry) {
            final percentage = total > 0
                ? (entry.value / total * 100).toStringAsFixed(1)
                : '0';
            final color = _emojiColors[entry.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value} 次',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// ======== 保存周报长图 ========
  Future<void> _saveReportToGallery(BuildContext context) async {
    try {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 正在生成周报长图...'),
          duration: Duration(seconds: 1),
        ),
      );

      final success = await ScreenshotHelper.captureAndSave(_reportKey);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🖼️ 周报长图已保存！')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ 桌面端已保存到本地文件')),
          );
        }
      }
    } catch (e) {
      print('❌ 保存周报长图失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 保存失败: $e')),
        );
      }
    }
  }
}
