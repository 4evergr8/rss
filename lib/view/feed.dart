import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:rss/database.dart';
import 'package:rss/service/download.dart';
import 'package:rss/service/rss.dart';
import 'package:rss/view/article.dart';
import 'package:rss/widget.dart';

final _db = AppDatabase();

class RssFeedScreen extends StatefulWidget {
  final int feedType;

  const RssFeedScreen({super.key, required this.feedType});

  @override
  State<RssFeedScreen> createState() => _RssFeedScreenState();
}

class _RssFeedScreenState extends State<RssFeedScreen> {
  Map<String, List<Feed>> _groupedFeeds = {};
  Map<String, int> _unreadCounts = {};
  bool _isLoadingData = true;

  // 静态变量：生命周期随进程，完全杀死启动时为 true，软件内切换重建时保持 false
  static bool _isAppColdLaunched = true;

  // 进度条状态控制变量
  String _currentRefreshingTitle = '';
  String _refreshProgress = '';

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();

    // 识别冷启动：只有完全杀死后第一次进入才会执行
    if (_isAppColdLaunched) {
      _isAppColdLaunched = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshAllFeeds();
      });
    }
  }

  Future<void> _loadDatabaseData() async {
    try {
      final allFeeds = await _db.select(_db.feeds).get();
      final Map<String, int> counts = {};
      final List<Feed> filteredFeeds = [];

      for (var feed in allFeeds) {
        final query = _db.select(_db.articles)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl));

        if (widget.feedType == 0) {
          query.where((tbl) => tbl.status.equals('0').not() & tbl.status.equals('1').not());
        } else if (widget.feedType == 2) {
          query.where((tbl) => tbl.status.equals('1'));
        }

        final matchedArticles = await query.get();

        if ((widget.feedType == 0 || widget.feedType == 2) && matchedArticles.isEmpty) {
          continue;
        }

        counts[feed.feedUrl] = matchedArticles.length;
        filteredFeeds.add(feed);
      }

      final rawGrouped = filteredFeeds.groupListsBy((feed) {
        final category = feed.category.trim();
        return category.isEmpty ? '未分组' : category;
      });

      final otherCategoryNames = rawGrouped.keys.where((k) => k != '未分组').toList()..sort();
      final Map<String, List<Feed>> sortedGrouped = {};

      if (rawGrouped.containsKey('未分组')) {
        final unclassifiedFeeds = rawGrouped['未分组']!;
        unclassifiedFeeds.sort((a, b) => a.title.compareTo(b.title));
        sortedGrouped['未分组'] = unclassifiedFeeds;
      }

      for (var categoryName in otherCategoryNames) {
        final feedsInGroup = rawGrouped[categoryName]!;
        feedsInGroup.sort((a, b) => a.title.compareTo(b.title));
        sortedGrouped[categoryName] = feedsInGroup;
      }

      setState(() {
        _groupedFeeds = sortedGrouped;
        _unreadCounts = counts;
        _isLoadingData = false;
      });
    } catch (e) {
      showErrorSnackBarGlobal('加载本地数据错误: $e');
    }
  }

  Future<void> _refreshAllFeeds() async {
    final cancelLoading = await showLoadingDialogGlobal();

    try {
      final allFeeds = await _db.select(_db.feeds).get();
      if (allFeeds.isEmpty) return;

      final sortedFeeds = List<Feed>.from(allFeeds);
      sortedFeeds.sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));

      final int totalCount = sortedFeeds.length;

      for (int i = 0; i < totalCount; i++) {
        final feed = sortedFeeds[i];

        // 实时更新当前正在刷新的订阅源信息及进度
        setState(() {
          _currentRefreshingTitle = feed.title;
          _refreshProgress = '${i + 1}/$totalCount';
        });

        try {
          final xmlText = await downloadXmlFromServer(feed.feedUrl);

          final parsedData = parseRss(xmlText);
          final List<Map<String, String>> parsedArticles = List<Map<String, String>>.from(parsedData['articles']);

          final String siteUrl = parsedData['siteUrl'] ?? '';
          final String iconUrl = parsedData['iconUrl'] ?? '';

          if (parsedArticles.isNotEmpty) {
            await _db.batch((batch) {
              for (var item in parsedArticles) {
                batch.insert(
                  _db.articles,
                  ArticlesCompanion(
                    guid: drift.Value(item['guid']!),
                    title: drift.Value(item['title']!),
                    feedUrl: drift.Value(feed.feedUrl),
                    link: drift.Value(item['link']!),
                    description: drift.Value(item['description']!),
                    content: drift.Value(item['content']!),
                    enclosure: drift.Value(item['enclosure']!),
                    author: drift.Value(item['author']!),
                    date: drift.Value(item['date']!),
                  ),
                  mode: drift.InsertMode.insertOrIgnore,
                );
              }
            });
          }

          final nowTimestamp = (DateTime.now().millisecondsSinceEpoch).toString();
          await (_db.update(_db.feeds)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl))).write(
            FeedsCompanion(
              lastUpdated: drift.Value(nowTimestamp),
              siteUrl: drift.Value(siteUrl),
              iconUrl: drift.Value(iconUrl),
            ),
          );
        } catch (singleError) {
          showErrorSnackBarGlobal('更新订阅源 [${feed.title}] 失败，已终止后续刷新: $singleError');
          break;
        }
      }

      // 哪怕中途有源失败退出了，依然把前面已经成功更新的数据加载到 UI 上
      await _loadDatabaseData();
    } catch (e) {
      showErrorSnackBarGlobal('刷新队列发生致命异常: $e');
    } finally {
      // 刷新结束，重置进度显示状态
      setState(() {
        _currentRefreshingTitle = '';
        _refreshProgress = '';
      });
      cancelLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    // 抽出公共的进度提示挂件
    Widget? progressBanner;
    if (_currentRefreshingTitle.isNotEmpty) {
      progressBanner = Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '正在刷新: $_currentRefreshingTitle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _refreshProgress,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    if (_groupedFeeds.isEmpty) {
      return Column(
        children: [
          if (progressBanner != null) progressBanner,
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAllFeeds,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Text(
                      '没有匹配的订阅源\n下拉可以触发同步刷新',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, height: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (progressBanner != null) progressBanner,
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAllFeeds,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _groupedFeeds.keys.length,
              itemBuilder: (context, groupIndex) {
                final categoryName = _groupedFeeds.keys.elementAt(groupIndex);
                final feedsInGroup = _groupedFeeds[categoryName] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    shape: const Border(),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
                    title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${feedsInGroup.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    initiallyExpanded: true,
                    children: feedsInGroup.map((feed) {
                      final count = _unreadCounts[feed.feedUrl] ?? 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withAlpha(20),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: feed.iconUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: feed.iconUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.rss_feed, size: 18, color: Theme.of(context).colorScheme.primary),
                                  )
                                : Icon(Icons.rss_feed, size: 18, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        title: Text(
                          feed.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: count > 0 ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: count > 0
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ArticleListScreen(feed: feed, initialFeedType: widget.feedType),
                            ),
                          );
                          _loadDatabaseData();
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
