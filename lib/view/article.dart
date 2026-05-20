import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:rss/database.dart';
import 'package:rss/service/download.dart';
import 'package:rss/service/rss.dart';
import 'package:rss/view/reader.dart';
import 'package:rss/widget.dart';
import 'package:url_launcher/url_launcher.dart';

final _db = AppDatabase();

class ArticleListScreen extends StatefulWidget {
  final Feed feed;
  final int initialFeedType; // 接收外部传入的初始模式 (0 = 未读, 1 = 所有, 2 = 星标)

  const ArticleListScreen({super.key, required this.feed, required this.initialFeedType});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  // 0 代表未读，1 代表所有，2 代表星标
  int _currentSubIndex = 0;
  List<Article> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentSubIndex = widget.initialFeedType; // 初始化为传入的模式
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final query = _db.select(_db.articles)..where((tbl) => tbl.feedUrl.equals(widget.feed.feedUrl));

      if (_currentSubIndex == 0) {
        // 未读：过滤掉 0（已读）和 1（星标）
        query.where((tbl) => tbl.status.equals('0').not() & tbl.status.equals('1').not());
      } else if (_currentSubIndex == 2) {
        // 星标：仅保留 1（星标）
        query.where((tbl) => tbl.status.equals('1'));
      }

      query.orderBy([(tbl) => drift.OrderingTerm(expression: tbl.date, mode: drift.OrderingMode.desc)]);

      final data = await query.get();
      setState(() {
        _articles = data;
        _isLoading = false;
      });
    } catch (e) {
      _isLoading = false;
      showErrorSnackBarGlobal('加载文章失败: $e');
    }
  }

  Future<void> _refreshCurrentFeed() async {
    final cancelLoading = await showLoadingDialogGlobal();

    try {
      final xmlText = await downloadXmlFromServer(widget.feed.feedUrl);

      // 调用合并后的平铺函数
      final parsedData = parseRss(xmlText);
      final List<Map<String, String>> parsedArticles = List<Map<String, String>>.from(parsedData['articles']);

      // 提取解析到的新值
      final String? parsedSite = parsedData['siteUrl'];
      final String? parsedIcon = parsedData['iconUrl'];

      // 逻辑：如果解析到了非空字段就覆盖新值，否则严格保留原本数据库里的值
      final String siteUrl = (parsedSite != null && parsedSite.trim().isNotEmpty)
          ? parsedSite.trim()
          : widget.feed.siteUrl;

      final String iconUrl = (parsedIcon != null && parsedIcon.trim().isNotEmpty)
          ? parsedIcon.trim()
          : widget.feed.iconUrl;

      for (var item in parsedArticles) {
        final existing = await (_db.select(
          _db.articles,
        )..where((tbl) => tbl.guid.equals(item['guid']!))).getSingleOrNull();

        if (existing != null) {
          await (_db.update(_db.articles)..where((tbl) => tbl.guid.equals(item['guid']!))).write(
            ArticlesCompanion(
              title: drift.Value(item['title']!),
              feedUrl: drift.Value(widget.feed.feedUrl),
              link: drift.Value(item['link']!),
              description: drift.Value(item['description']!),
              content: drift.Value(item['content']!),
              enclosure: drift.Value(item['enclosure']!),
              author: drift.Value(item['author']!),
              date: drift.Value(item['date']!),
            ),
          );
        } else {
          await _db
              .into(_db.articles)
              .insert(
                ArticlesCompanion(
                  guid: drift.Value(item['guid']!),
                  title: drift.Value(item['title']!),
                  feedUrl: drift.Value(widget.feed.feedUrl),
                  link: drift.Value(item['link']!),
                  description: drift.Value(item['description']!),
                  content: drift.Value(item['content']!),
                  enclosure: drift.Value(item['enclosure']!),
                  author: drift.Value(item['author']!),
                  date: drift.Value(item['date']!),
                  status: const drift.Value('2'),
                ),
              );
        }
      }

      final nowTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      await (_db.update(_db.feeds)..where((tbl) => tbl.feedUrl.equals(widget.feed.feedUrl))).write(
        FeedsCompanion(
          lastUpdated: drift.Value(nowTimestamp),
          siteUrl: drift.Value(siteUrl),
          iconUrl: drift.Value(iconUrl),
        ),
      );

      await _loadArticles();
    } catch (e) {
      showErrorSnackBarGlobal('刷新订阅源失败: $e');
    } finally {
      cancelLoading();
    }
  }

  String _getSummary(String description, String content) {
    if (description.trim().isNotEmpty) {
      return description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }
    if (content.trim().isNotEmpty) {
      final plainContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      return plainContent.length > 80 ? '${plainContent.substring(0, 80)}...' : plainContent;
    }
    return '无内容摘要';
  }

  String _formatTimestamp(String timestampStr) {
    try {
      final seconds = int.parse(timestampStr);
      final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestampStr;
    }
  }

  Future<void> _handleArticleTap(Article article) async {
    try {
      final newStatus = article.status == '1' ? '1' : '0';
      await (_db.update(
        _db.articles,
      )..where((tbl) => tbl.guid.equals(article.guid))).write(ArticlesCompanion(status: drift.Value(newStatus)));
    } catch (e) {
      debugPrint('标记已读失败: $e');
    }

    if (widget.feed.displayMode == 'web') {
      final uri = Uri.parse(article.link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showErrorSnackBarGlobal('无法打开网页链接: ${article.link}');
      }
      _loadArticles();
    } else {
      if (!mounted) return;
      final currentIndex = _articles.indexOf(article);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReaderScreen(allArticles: _articles, initialIndex: currentIndex),
        ),
      );

      _loadArticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feed.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
          ? RefreshIndicator(
              onRefresh: _refreshCurrentFeed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(child: Text('当前分类下没有文章\n下拉可以触发同步刷新')),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshCurrentFeed,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _articles.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  final summary = _getSummary(article.description, article.content);
                  final dateText = _formatTimestamp(article.date);

                  final isUnread = article.status != '0' && article.status != '1';

                  const double imageWidth = 110.0;
                  const double imageHeight = 80.0;

                  return InkWell(
                    onTap: () => _handleArticleTap(article),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                          color: isUnread
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        summary,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.3,
                                          color: colorScheme.onSurfaceVariant.withOpacity(isUnread ? 1.0 : 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: article.enclosure,
                                    width: imageWidth,
                                    height: imageHeight,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    placeholder: (context, url) => Container(
                                      width: imageWidth,
                                      height: imageHeight,
                                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: imageWidth,
                                      height: imageHeight,
                                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.broken_image, size: 20, color: colorScheme.outline),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    article.author.isNotEmpty ? article.author : '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: colorScheme.outline),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (article.status == '1') Icon(Icons.star, size: 12, color: colorScheme.primary),
                                    if (article.status == '1') const SizedBox(width: 4),
                                    Text(dateText, style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mark_as_unread_outlined),
            activeIcon: Icon(Icons.mark_as_unread),
            label: '未读',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.rss_feed_outlined), activeIcon: Icon(Icons.rss_feed), label: '所有'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), activeIcon: Icon(Icons.star), label: '星标'),
        ],
        currentIndex: _currentSubIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.secondary,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentSubIndex = index;
          });
          _loadArticles();
        },
      ),
    );
  }
}
