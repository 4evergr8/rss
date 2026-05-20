import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 引入缓存图片库
import 'package:rss/view/reader.dart';
import 'package:rss/widget.dart';
import 'package:url_launcher/url_launcher.dart'; // 用于外部浏览器打开链接
import 'package:rss/database.dart';
import 'package:rss/service/download.dart'; // 引入下载服务
import 'package:rss/service/rss.dart';     // 引入解析服务

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

  // 下拉刷新当前单个订阅源的核心逻辑
  Future<void> _refreshCurrentFeed() async {
    // 1. 触发你现有的全局动画开始
    final cancelLoading = await showLoadingDialogGlobal();

    try {
      // 2. 下载当前订阅源的 XML
      final xmlText = await downloadXmlFromServer(widget.feed.feedUrl);

      // 3. 解析文章
      final parsedArticles = parseRssArticles(xmlText);

      // 4. 增：利用批量入库方法写入文章（如果 guid 冲突则自动替代去重）
      await _db.batch((batch) {
        batch.insertAll(
          _db.articles,
          parsedArticles.map((item) => ArticlesCompanion(
            guid: drift.Value(item['guid']!),
            title: drift.Value(item['title']!),
            feedUrl: drift.Value(widget.feed.feedUrl),
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

      // 5. 改：更新当前订阅源的 lastUpdated 时间戳为当前的最新秒数
      final nowTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      await (_db.update(_db.feeds)..where((tbl) => tbl.feedUrl.equals(widget.feed.feedUrl)))
          .write(FeedsCompanion(lastUpdated: drift.Value(nowTimestamp)));

      // 6. 刷新洗涤完毕后，重新拉取本地数据库填充 UI
      await _loadArticles();

    } catch (e) {
      showErrorSnackBarGlobal('刷新订阅源失败: $e');
    } finally {
      // 7. final 分支雷打不动闭合全局动画
      cancelLoading();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // 预留添加页面跳转
            },
          ),
        ],
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
          physics: const AlwaysScrollableScrollPhysics(), // 确保内容少时也能触发下拉手势
          itemCount: _articles.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final article = _articles[index];
            final summary = _getSummary(article.description, article.content);
            final dateText = _formatTimestamp(article.date);

            // 定义右侧图片的固定尺寸
            const double imageWidth = 110.0;
            const double imageHeight = 80.0;

            return InkWell(
              onTap: () => _handleArticleTap(article),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 左边部分：占满剩余宽度
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标题：最多显示两行，超出截断
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: article.isRead == 'false'
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 描述：填满标题与作者之间的空白，超出截断
                            Expanded(
                              child: Text(
                                summary,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: colorScheme.onSurfaceVariant.withOpacity(
                                    article.isRead == 'false' ? 1.0 : 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 作者
                            Text(
                              article.author.isNotEmpty ? '作者: ${article.author}' : '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 右边部分：固定宽度，高度由内部组件（图片+日期）撑起并限制整个控件高度
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 具备断网本地缓存能力的图片组件
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: article.enclosure,
                              width: imageWidth,
                              height: imageHeight,
                              fit: BoxFit.cover, // 保持原图比例裁剪缩放，不变形
                              alignment: Alignment.center,
                              placeholder: (context, url) => Container(
                                width: imageWidth,
                                height: imageHeight,
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                  ),
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
                          const SizedBox(height: 6),

                          // 日期
                          Text(
                            dateText,
                            style: TextStyle(fontSize: 11, color: colorScheme.outline),
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
          _loadArticles();
        },
      ),
    );
  }
}