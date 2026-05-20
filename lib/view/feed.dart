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
  // feedType 对应关系: 0 = 未读, 1 = 所有, 2 = 星标
  final int feedType;

  const RssFeedScreen({super.key, required this.feedType});

  @override
  State<RssFeedScreen> createState() => _RssFeedScreenState();
}

class _RssFeedScreenState extends State<RssFeedScreen> {
  Map<String, List<Feed>> _groupedFeeds = {};
  Map<String, int> _unreadCounts = {};
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();
  }

  Future<void> _loadDatabaseData() async {
    try {
      final allFeeds = await _db.select(_db.feeds).get();
      final Map<String, int> counts = {};
      final List<Feed> filteredFeeds = [];

      for (var feed in allFeeds) {
        final query = _db.select(_db.articles)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl));

        if (widget.feedType == 0) {
          // 仅统计和筛选未读状态的文章（status 不为 0 且不为 1）
          query.where((tbl) => tbl.status.equals('0').not() & tbl.status.equals('1').not());
        } else if (widget.feedType == 2) {
          // 仅统计和筛选星标状态的文章（status 为 1）
          query.where((tbl) => tbl.status.equals('1'));
        }

        final matchedArticles = await query.get();

        // 如果是未读或星标模式，且该订阅源下没有匹配的文章，则在主页列表隐藏该订阅源
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

      for (var feed in sortedFeeds) {
        try {
          final xmlText = await downloadXmlFromServer(feed.feedUrl);

          // 修改后：调用合并后的平铺函数
          final parsedData = parseRss(xmlText);
          final List<Map<String, String>> parsedArticles = List<Map<String, String>>.from(parsedData['articles']);

          // 有值覆盖，没有不覆盖：检查解析值是否有效，无效则沿用本地数据库已有的值
          final String? parsedSite = parsedData['siteUrl'];
          final String? parsedIcon = parsedData['iconUrl'];

          final String siteUrl = (parsedSite != null && parsedSite.trim().isNotEmpty)
              ? parsedSite.trim()
              : feed.siteUrl;

          final String iconUrl = (parsedIcon != null && parsedIcon.trim().isNotEmpty)
              ? parsedIcon.trim()
              : feed.iconUrl;

          for (var item in parsedArticles) {
            final existing = await (_db.select(
              _db.articles,
            )..where((tbl) => tbl.guid.equals(item['guid']!))).getSingleOrNull();

            if (existing != null) {
              await (_db.update(_db.articles)..where((tbl) => tbl.guid.equals(item['guid']!))).write(
                ArticlesCompanion(
                  title: drift.Value(item['title']!),
                  feedUrl: drift.Value(feed.feedUrl),
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
                  feedUrl: drift.Value(feed.feedUrl),
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
          await (_db.update(_db.feeds)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl))).write(
            FeedsCompanion(
              lastUpdated: drift.Value(nowTimestamp),
              siteUrl: drift.Value(siteUrl),
              iconUrl: drift.Value(iconUrl),
            ),
          );
        } catch (singleError) {
          debugPrint('更新订阅源 [${feed.title}] 失败，已跳过: $singleError');
          continue;
        }
      }

      await _loadDatabaseData();
    } catch (e) {
      showErrorSnackBarGlobal('刷新队列发生致命异常: $e');
    } finally {
      cancelLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedFeeds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshAllFeeds,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(child: Text('没有匹配的订阅源\n下拉可以触发同步刷新')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAllFeeds,
      child: ListView.builder(
        itemCount: _groupedFeeds.keys.length,
        itemBuilder: (context, groupIndex) {
          final categoryName = _groupedFeeds.keys.elementAt(groupIndex);
          final feedsInGroup = _groupedFeeds[categoryName] ?? [];

          return ExpansionTile(
            title: Text('$categoryName (${feedsInGroup.length})'),
            initiallyExpanded: true,
            children: feedsInGroup.map((feed) {
              final count = _unreadCounts[feed.feedUrl] ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: feed.iconUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: feed.iconUrl,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => const Icon(Icons.rss_feed),
                      )
                    : const Icon(Icons.rss_feed),
                title: Text(feed.title),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: count > 0 ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: count > 0 ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey,
                    ),
                  ),
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ArticleListScreen(
                        feed: feed,
                        initialFeedType: widget.feedType, // 传入当前主界面的相同模式
                      ),
                    ),
                  );
                  _loadDatabaseData();
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
