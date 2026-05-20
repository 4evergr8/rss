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

      // 修改后：改用最新的合并平铺解析函数
      final parsedData = parseRss(xmlText);
      final List<Map<String, String>> parsedArticles = List<Map<String, String>>.from(parsedData['articles']);

      // 强制覆盖：最新解析结果不为空则覆盖，否则写为空字符串覆盖旧数据
      final String siteUrl = parsedData['siteUrl'] ?? '';
      final String iconUrl = parsedData['iconUrl'] ?? '';

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
        title: Text(widget.feed.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    '当前分类下没有文章\n下拉可以触发同步刷新',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.outline, height: 1.5, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshCurrentFeed,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _articles.length,
          separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withOpacity(0.4)),
          itemBuilder: (context, index) {
            final article = _articles[index];
            final summary = _getSummary(article.description, article.content);
            final dateText = _formatTimestamp(article.date);

            final isUnread = article.status != '0' && article.status != '1';
            final hasImage = article.enclosure.trim().isNotEmpty;

            const double imageWidth = 96.0;
            const double imageHeight = 72.0;

            return InkWell(
              onTap: () => _handleArticleTap(article),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUnread) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0, right: 6.0),
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Expanded(
                                    child: Text(
                                      article.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                        height: 1.3,
                                        color: isUnread
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurface.withOpacity(0.45),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isUnread
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasImage) ...[
                          const SizedBox(width: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                                alignment: Alignment.center,
                                child: Icon(Icons.broken_image_outlined, size: 20, color: colorScheme.outline.withOpacity(0.6)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            article.author.isNotEmpty ? article.author : widget.feed.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnread ? colorScheme.outline : colorScheme.outline.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (article.status == '1') ...[
                              Icon(Icons.star_rounded, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 11,
                                color: isUnread ? colorScheme.outline : colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3), width: 1)),
        ),
        child: BottomNavigationBar(
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
              icon: Icon(Icons.star_outline_rounded),
              activeIcon: Icon(Icons.star_rounded),
              label: '星标',
            ),
          ],
          currentIndex: _currentSubIndex,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          onTap: (index) {
            if (_currentSubIndex == index) return;
            setState(() {
              _currentSubIndex = index;
            });
            _loadArticles();
          },
        ),
      ),
    );
  }
}