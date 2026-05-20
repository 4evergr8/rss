import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rss/main.dart';
import 'package:rss/view/add.dart';
import 'package:rss/view/feed.dart';



class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // 3 个核心页面栏位（未读、所有、设置）
  // 未读和所有复用同一个页面组件，通过参数 showUnreadOnly 进行数据查询区分
  static final List<Widget> _widgetOptions = <Widget>[
    const RssFeedScreen(showUnreadOnly: true),  // 未读
    const RssFeedScreen(showUnreadOnly: false), // 所有
    const SettingsScreen(),                     // 设置
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // 顶栏：只有在非设置页面（未读、所有）时才显示添加订阅按钮
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '未读订阅' : _selectedIndex == 1 ? '所有订阅' : '软件设置'),
        backgroundColor: colorScheme.surface,
        actions: _selectedIndex != 2
            ? [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // 跳转至添加订阅界面
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddFeedScreen()),
              );
            },
          ),
        ]
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 禁止手势左右滑动切换
        children: _widgetOptions,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mark_as_unread_outlined),
            activeIcon: Icon(Icons.mark_as_unread),
            label: '未读',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed_outlined),
            activeIcon: Icon(Icons.rss_feed),
            label: '所有',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.secondary,
        backgroundColor: colorScheme.surface,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // 确保 3 个标签平分且不挤压
      ),
    );
  }
}

// ==================== 临时的占位页面组件 ====================



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('设置页面'));
  }
}



// ==================== 保留现有的全局组件 ====================

Future<VoidCallback> showLoadingDialogGlobal() async {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return () {};

  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (_) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: Theme.of(navigatorKey.currentContext!).colorScheme.primaryContainer,
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  return () => overlayEntry.remove();
}

void showErrorSnackBarGlobal(String message) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;

  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: message));
        },
        child: Text(message),
      ),
    ),
  );
}