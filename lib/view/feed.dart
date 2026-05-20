import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:collection/collection.dart'; // 用于分组函数 groupListsBy
import 'package:cached_network_image/cached_network_image.dart'; // 引入缓存图片库
import 'package:rss/database.dart';
import 'package:rss/service/download.dart';
import 'package:rss/service/rss.dart';
import 'package:rss/view/article.dart';
import 'package:rss/widget.dart';

final _db = AppDatabase();

class RssFeedScreen extends StatefulWidget {
  final bool showUnreadOnly; // true 显示未读页面，false 显示所有页面

  const RssFeedScreen({super.key, required this.showUnreadOnly});

  @override
  State<RssFeedScreen> createState() => _RssFeedScreenState();
}

class _RssFeedScreenState extends State<RssFeedScreen> {
  // 分组后的数据结构 Map<分组名, 订阅源列表>
  Map<String, List<Feed>> _groupedFeeds = {};

  // 存储每个订阅源对应的未读数量 Map<订阅源链接, 未读数>
  Map<String, int> _unreadCounts = {};

  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();
  }

  // 从数据库普通读取数据并刷到 UI
  Future<void> _loadDatabaseData() async {
    try {
      // 1. 查出全部订阅源
      final allFeeds = await _db.select(_db.feeds).get();

      // 2. 统计每条订阅源的未读/总数量（根据 showUnreadOnly 条件进行筛选统计）
      final Map<String, int> counts = {};
      final List<Feed> filteredFeeds = [];

      for (var feed in allFeeds) {
        // 构建条件查询语句
        final query = _db.select(_db.articles)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl));
        if (widget.showUnreadOnly) {
          query.where((tbl) => tbl.isRead.equals('false'));
        }

        final matchedArticles = await query.get();

        // 如果是未读页面，且该源一条未读都没有，则不显示该源
        if (widget.showUnreadOnly && matchedArticles.isEmpty) {
          continue;
        }

        counts[feed.feedUrl] = matchedArticles.length;
        filteredFeeds.add(feed);
      }

      // 3. 将扁平的订阅源列表按照 category（分组名）进行归类归集
      final grouped = filteredFeeds.groupListsBy((feed) => feed.category);

      setState(() {
        _groupedFeeds = grouped;
        _unreadCounts = counts;
        _isLoadingData = false;
      });
    } catch (e) {
      showErrorSnackBarGlobal('加载本地数据错误: $e');
    }
  }

  // 串行队列下拉刷新核心逻辑
  Future<void> _refreshAllFeeds() async {
    // 1. 触发你现有的全局动画开始
    final cancelLoading = await showLoadingDialogGlobal();

    try {
      // 2. 一次性捞出当前所有的订阅源
      final allFeeds = await _db.select(_db.feeds).get();
      if (allFeeds.isEmpty) return;

      // 3. 按照 lastUpdated 的数字字符串升序排序（最久没更新的排在最前面）
      final sortedFeeds = List<Feed>.from(allFeeds);
      sortedFeeds.sort((a, b) => a.lastUpdated.compareTo(b.lastUpdated));

      // 4. 开始依次循环抓取更新（每个源只尝试处理一次）
      for (var feed in sortedFeeds) {
        try {
          // 下载
          final xmlText = await downloadXmlFromServer(feed.feedUrl);
          // 解析文章
          final parsedArticles = parseRssArticles(xmlText);

          // 增：利用批量入库方法写入文章（如果 guid 冲突则自动替代去重）
          await _db.batch((batch) {
            batch.insertAll(
              _db.articles,
              parsedArticles.map((item) => ArticlesCompanion(
                guid: drift.Value(item['guid']!),
                title: drift.Value(item['title']!),
                feedUrl: drift.Value(feed.feedUrl),
                link: drift.Value(item['link']!),
                description: drift.Value(item['description']!),
                content: drift.Value(item['content']!),
                enclosure: drift.Value(item['enclosure']!),
                author: drift.Value(item['author']!),
                date: drift.Value(item['date']!),
                isRead: drift.Value(item['isRead']!),
              )).toList(),
              mode: drift.InsertMode.insertOrReplace,
            );
          });

          // 改：更新当前订阅源的 lastUpdated 时间戳为当前的最新秒数
          final nowTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
          await (_db.update(_db.feeds)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl)))
              .write(FeedsCompanion(lastUpdated: drift.Value(nowTimestamp)));

        } catch (singleError) {
          // 某个独立的源更新失败（如404、超时），不中断大队，继续更新下一个
          debugPrint('更新订阅源 [${feed.title}] 失败，已跳过: $singleError');
          continue;
        }
      }

      // 5. 所有的源刷新洗涤完毕后，重新拉取本地数据库填充 UI
      await _loadDatabaseData();

    } catch (e) {
      showErrorSnackBarGlobal('刷新队列发生致命异常: $e');
    } finally {
      // 6. final 分支雷打不动闭合全局动画
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

    // 外层使用标准的 RefreshIndicator 包装包裹，提供下拉手势
    return RefreshIndicator(
      onRefresh: _refreshAllFeeds,
      child: ListView.builder(
        itemCount: _groupedFeeds.keys.length,
        itemBuilder: (context, groupIndex) {
          final categoryName = _groupedFeeds.keys.elementAt(groupIndex);
          final feedsInGroup = _groupedFeeds[categoryName] ?? [];

          // 使用可折叠的 ExpansionTile 展现分组壳
          return ExpansionTile(
            title: Text('$categoryName (${feedsInGroup.length})'),
            initiallyExpanded: true, // 默认展开
            children: feedsInGroup.map((feed) {
              final count = _unreadCounts[feed.feedUrl] ?? 0;

              // 具体订阅条目
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: feed.iconUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: feed.iconUrl,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  // 加载过程中的占位组件
                  placeholder: (context, url) => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  // 出错时的回退组件
                  errorWidget: (context, url, error) => const Icon(Icons.rss_feed),
                )
                    : const Icon(Icons.rss_feed),
                title: Text(feed.title),
                // 右侧显示条目数量
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
                  // 跳转到文章列表页，并将当前点击的订阅源完整数据（feed）传递过去
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ArticleListScreen(feed: feed),
                    ),
                  );
                  // 从文章列表页返回后（可能在里面消耗了未读数或切换了状态），重新刷新当前订阅页的本地数据
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