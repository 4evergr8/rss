import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:rss/view/reader.dart';
import 'package:rss/widget.dart';
import 'package:url_launcher/url_launcher.dart'; // 用于外部浏览器打开链接

import '../database.dart';

final _db = AppDatabase();

class ArticleListScreen extends StatefulWidget {
  final Feed feed; // 从上一页传递过来的订阅源完整数据

  const ArticleListScreen({super.key, required this.feed});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  // 页面自身控制的底栏状态：0 代表只看未读，1 代表看所有
  int _currentSubIndex = 0;
  List<Article> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  // 纯异步获取文章列表数据
  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      // 基础查询：筛选属于当前订阅源的文章
      final query = _db.select(_db.articles)..where((tbl) => tbl.feedUrl.equals(widget.feed.feedUrl));

      // 如果切换到了“未读”标签，增加未读条件过滤
      if (_currentSubIndex == 0) {
        query.where((tbl) => tbl.isRead.equals('false'));
      }

      // 按照发布时间进行降序排序（最新发布的在最上面）
      query.orderBy([(tbl) => drift.OrderingTerm(expression: tbl.date, mode: drift.OrderingMode.desc)]);

      final data = await query.get();
      setState(() {
        _articles = data;
        _isLoading = false;
      });
    } catch (e) {
      _isLoading = false;
      // 调用你的全局错误提示
      showErrorSnackBarGlobal('加载文章失败: $e');
    }
  }

  // 处理文本摘要显示：优先使用描述，没有就截取正文
  String _getSummary(String description, String content) {
    if (description.trim().isNotEmpty) {
      return description.replaceAll(RegExp(r'<[^>]*>'), '').trim(); // 简单剔除HTML标签
    }
    if (content.trim().isNotEmpty) {
      final plainContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      return plainContent.length > 80 ? '${plainContent.substring(0, 80)}...' : plainContent;
    }
    return '无内容摘要';
  }

  // 处理时间戳转换显示
  String _formatTimestamp(String timestampStr) {
    try {
      final seconds = int.parse(timestampStr);
      final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestampStr;
    }
  }

  // 点击文章条目的核心逻辑
  Future<void> _handleArticleTap(Article article) async {
    // 1. 先在本地数据库将这篇文章修改、标记为已读
    try {
      await (_db.update(
        _db.articles,
      )..where((tbl) => tbl.guid.equals(article.guid))).write(const ArticlesCompanion(isRead: drift.Value('true')));
    } catch (e) {
      debugPrint('标记已读失败: $e');
    }

    // 2. 根据该订阅源的展示模式选择不同出路
    if (widget.feed.displayMode == 'web') {
      // web模式：直接唤起手机上的外部浏览器
      final uri = Uri.parse(article.link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showErrorSnackBarGlobal('无法打开网页链接: ${article.link}');
      }
      // 外部打开后，直接刷新一下列表（如果是未读页，该行会自动消失）
      _loadArticles();
    } else {
      // 默认模式（或者list/content模式）：跳转到你规划的下一页阅读界面
      // 这里把当前点击的文章、完整的文章列表、以及当前所在的索引都传过去，方便阅读页切歌
      if (!mounted) return;
      final currentIndex = _articles.indexOf(article);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReaderScreen(
            allArticles: _articles, // 传递当前视图下的文章静态快照
            initialIndex: currentIndex, // 传递当前点击的位置
          ),
        ),
      );

      // 从阅读页返回后，外层列表重新刷新，刚才读过的文章就会自动消失（未读页）或变灰（全部页）
      _loadArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feed.title),
        // 按照规划，在文章列表等外围页面时，顶栏依然保留添加订阅按钮
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // 这里的 AddFeedScreen 是之前写的添加页面
              // Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddFeedScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
          ? const Center(child: Text('当前分类下没有文章'))
          : ListView.separated(
              itemCount: _articles.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final article = _articles[index];
                final summary = _getSummary(article.description, article.content);
                final dateText = _formatTimestamp(article.date);

                return InkWell(
                  onTap: () => _handleArticleTap(article),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Text(
                          article.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // 如果是未读，字体颜色加深；已读则变浅灰色灰化
                            color: article.isRead == 'false'
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 描述/摘要
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant.withOpacity(article.isRead == 'false' ? 1.0 : 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // enclosure 插图（如果链接不为空，则用网络组件加载显示，没有就不占位）
                        if (article.enclosure.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              article.enclosure,
                              cacheHeight: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(), // 加载失败也不破坏布局
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // 日期和作者
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              article.author.isNotEmpty ? '作者: ${article.author}' : '',
                              style: TextStyle(fontSize: 11, color: colorScheme.outline),
                            ),
                            Text(dateText, style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      // 底部专属切换栏：未读/全部
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.blur_on), label: '未读内容'),
          BottomNavigationBarItem(icon: Icon(Icons.blur_circular), label: '全部内容'),
        ],
        currentIndex: _currentSubIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.secondary,
        onTap: (index) {
          setState(() {
            _currentSubIndex = index;
          });
          _loadArticles(); // 切换底栏标签时重新查询本地数据库
        },
      ),
    );
  }
}
