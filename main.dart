/// =====================================================
/// 文件：lib/main.dart
/// 功能：应用入口 · 主框架
/// 描述：MultiProvider 注册、MaterialApp 路由配置、
///        IndexedStack + BottomNavigationBar 三Tab布局
/// =====================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/madness_provider.dart';
import 'screens/home_page.dart';
import 'screens/preview_page.dart';
import 'screens/timeline_page.dart';
import 'screens/stats_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodayMadnessApp());
}

/// ============ 应用根组件 ============
class TodayMadnessApp extends StatelessWidget {
  const TodayMadnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MadnessProvider()),
      ],
      child: MaterialApp(
        title: '今日份发疯',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.purple,
        ),
        // 路由配置
        initialRoute: '/',
        routes: {
          '/': (context) => const MainShell(),
          '/preview': (context) => const PreviewPage(),
        },
      ),
    );
  }
}

/// ============ 主框架 Shell (底部导航) ============
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// 当前选中的 Tab 索引
  int _currentIndex = 0;

  /// 页面列表（使用 IndexedStack 保持页面状态）
  static const List<Widget> _pages = [
    HomePage(),
    TimelinePage(),
    StatsPage(),
  ];

  /// 切换 Tab
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.black87,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '发疯创作',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: '发疯历史',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: '发疯周报',
          ),
        ],
      ),
    );
  }
}
