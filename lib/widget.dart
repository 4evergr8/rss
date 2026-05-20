import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rss/main.dart';
import 'package:rss/view/add.dart';
import 'package:rss/view/feed.dart';
import 'package:rss/view/settings.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // 3 个核心页面栏位（未读、所有、星标）
  // 统一复用同一个 RssFeedScreen 页面组件，通过 feedType 参数进行数据查询区分
  // feedType 对应关系: 0 = 未读, 1 = 所有, 2 = 星标
  static final List<Widget> _widgetOptions = <Widget>[
    const RssFeedScreen(feedType: 0), // 未读
    const RssFeedScreen(feedType: 1), // 所有
    const RssFeedScreen(feedType: 2), // 星标
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
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '未读订阅' : _selectedIndex == 1 ? '所有订阅' : '星标订阅'),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddFeedScreen()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
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
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: '星标',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.secondary,
        backgroundColor: colorScheme.surface,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
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