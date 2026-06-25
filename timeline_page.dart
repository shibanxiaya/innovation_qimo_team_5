/// =====================================================
/// 文件：lib/screens/timeline_page.dart
/// 功能：发疯时光轴 - 查看历史发疯记录
/// 描述：简易当月日历网格 + 按日期查询记录列表 + 删除功能
/// =====================================================

import 'package:flutter/material.dart';
import '../models/madness_card_model.dart';
import '../services/madness_database.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  // ============ 状态 ============

  /// 当前选中的日期
  late DateTime _selectedDate;

  /// 当前显示的月份
  late DateTime _currentMonth;

  /// 当月日历天数
  List<DateTime> _monthDays = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _currentMonth = DateTime(now.year, now.month, 1);
    _generateMonthDays();
  }

  /// ============ 生成当月所有日历格子 ============
  void _generateMonthDays() {
    _monthDays = [];
    // 当月第一天
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // 当月最后一天
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // 补充上月末尾天数（使日历从周一开始）
    final startWeekday = firstDay.weekday; // DateTime.monday=1
    for (int i = 1; i < startWeekday; i++) {
      _monthDays.add(firstDay.subtract(Duration(days: startWeekday - i)));
    }

    // 当月所有天数
    for (int i = 0; i < lastDay.day; i++) {
      _monthDays.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }

    // 补充下月天数（填满6行）
    while (_monthDays.length < 42) {
      final last = _monthDays.last;
      _monthDays.add(last.add(const Duration(days: 1)));
    }
  }

  /// 切换到上个月
  void _prevMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _generateMonthDays();
    });
  }

  /// 切换到下个月
  void _nextMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _generateMonthDays();
    });
  }

  /// ============ UI ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '📅 发疯日历',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ======== 日历头部 ========
          _buildCalendarHeader(),
          // ======== 星期标题行 ========
          _buildWeekdayRow(),
          // ======== 日历网格 ========
          Expanded(
            flex: 1,
            child: _buildCalendarGrid(),
          ),
          // ======== 选中日期的记录列表 ========
          Expanded(
            flex: 2,
            child: _buildRecordList(),
          ),
        ],
      ),
    );
  }

  /// ======== 日历头部（月份切换） ========
  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _prevMonth,
          ),
          Text(
            '${_currentMonth.year}年 ${_currentMonth.month}月',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  /// ======== 星期标题行 ========
  Widget _buildWeekdayRow() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: day == '六' || day == '日'
                      ? Colors.white54
                      : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ======== 日历网格 (7列) ========
  Widget _buildCalendarGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: _monthDays.length,
        itemBuilder: (context, index) {
          final day = _monthDays[index];
          final isCurrentMonth = day.month == _currentMonth.month;
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isToday = day.year == DateTime.now().year &&
              day.month == DateTime.now().month &&
              day.day == DateTime.now().day;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.purple.withOpacity(0.6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isToday && !isSelected
                    ? Border.all(color: Colors.purpleAccent.withOpacity(0.5))
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isCurrentMonth ? Colors.white : Colors.white24,
                    fontSize: 14,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ======== 选中日期的发疯记录列表 ========
  Widget _buildRecordList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${_selectedDate.month}月${_selectedDate.day}日 · 发疯记录',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MadnessCard>>(
              future:
                  DatabaseService().getCardsByDate(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '加载失败: ${snapshot.error}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final cards = snapshot.data ?? [];

                if (cards.isEmpty) {
                  return const Center(
                    child: Text(
                      '这一天没有发疯，太正常了！',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _buildCardItem(card);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ======== 单条发疯记录卡片 ========
  Widget _buildCardItem(MadnessCard card) {
    final displayText = card.userText.length > 10
        ? '${card.userText.substring(0, 10)}...'
        : card.userText;

    final timeStr =
        '${card.createDate.hour.toString().padLeft(2, '0')}:${card.createDate.minute.toString().padLeft(2, '0')}';

    final Color startColor =
        Color(int.parse(card.startColor.replaceFirst('#', '0xFF')));

    return Card(
      elevation: 2,
      color: Colors.black54,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: startColor.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Text(
          card.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          displayText,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          timeStr,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmDelete(card),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// ======== 确认删除对话框 ========
  void _confirmDelete(MadnessCard card) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('确认删除',
              style: TextStyle(color: Colors.white)),
          content: Text(
            '确定要删除这条发疯记录吗？\n\n"${card.userText}"',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await DatabaseService().deleteCard(card.id!);
                  Navigator.of(dialogContext).pop();
                  // 刷新列表
                  setState(() {});
                } catch (e) {
                  print('❌ 删除失败: $e');
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('删除失败: $e')),
                    );
                  }
                }
              },
              child: const Text('删除',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

}
