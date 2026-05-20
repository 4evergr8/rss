import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database.dart';

final _db = AppDatabase();

class ReaderScreen extends StatefulWidget {
  final List<Article> allArticles;
  final int initialIndex;

  const ReaderScreen({super.key, required this.allArticles, required this.initialIndex});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int _currentIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _markAsRead(_currentIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(int index) async {
    if (index < 0 || index >= widget.allArticles.length) return;
    final article = widget.allArticles[index];

    if (article.status != '0' && article.status != '1') {
      try {
        await (_db.update(
          _db.articles,
        )..where((tbl) => tbl.guid.equals(article.guid))).write(const ArticlesCompanion(status: drift.Value('0')));

        setState(() {
          widget.allArticles[index] = article.copyWith(status: '0');
        });
      } catch (e) {
        debugPrint('阅读器标记已读失败: $e');
      }
    }
  }

  Future<void> _toggleStar() async {
    if (_currentIndex < 0 || _currentIndex >= widget.allArticles.length) return;
    final article = widget.allArticles[_currentIndex];

    final isStarred = article.status == '1';
    final newStatus = isStarred ? '0' : '1';

    try {
      await (_db.update(
        _db.articles,
      )..where((tbl) => tbl.guid.equals(article.guid))).write(ArticlesCompanion(status: drift.Value(newStatus)));

      setState(() {
        widget.allArticles[_currentIndex] = article.copyWith(status: newStatus);
      });
    } catch (e) {
      debugPrint('切换星标状态失败: $e');
    }
  }

  void _changeArticle(int newIndex) {
    if (newIndex >= 0 && newIndex < widget.allArticles.length) {
      setState(() {
        _currentIndex = newIndex;
      });
      _scrollController.jumpTo(0);
      _markAsRead(newIndex);
    }
  }

  Future<void> _launchInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法打开链接: $url')));
      }
    }
  }

  String _formatTimestamp(String timestampStr) {
    try {
      final seconds = int.parse(timestampStr);
      final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestampStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.allArticles.isEmpty) {
      return const Scaffold(body: Center(child: Text('没有可读的文章')));
    }

    final currentArticle = widget.allArticles[_currentIndex];
    final bool isFirst = _currentIndex == 0;
    final bool isLast = _currentIndex == widget.allArticles.length - 1;
    final bool isStarred = currentArticle.status == '1';

    final String mainContent = currentArticle.content.trim().isNotEmpty
        ? currentArticle.content
        : currentArticle.description;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentArticle.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (currentArticle.author.isNotEmpty) ...[
                        Icon(Icons.person_outline, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentArticle.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(currentArticle.date),
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              color: colorScheme.surfaceContainerLow,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: mainContent.isNotEmpty
                    ? HtmlWidget(
                  mainContent,
                  textStyle: TextStyle(
                    fontSize: 16.0,
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
                  onTapUrl: (url) async {
                    await _launchInBrowser(url);
                    return true;
                  },
                )
                    : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      '此文章没有可显示的文本内容',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              color: isFirst ? colorScheme.outline.withAlpha(76) : colorScheme.primary,
              onPressed: isFirst ? null : () => _changeArticle(_currentIndex - 1),
            ),
            IconButton(
              icon: Icon(isStarred ? Icons.star : Icons.star_border),
              color: isStarred ? Colors.amber : colorScheme.primary,
              onPressed: _toggleStar,
            ),
            IconButton(
              icon: const Icon(Icons.language),
              color: colorScheme.primary,
              onPressed: currentArticle.link.isNotEmpty ? () => _launchInBrowser(currentArticle.link) : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              color: isLast ? colorScheme.outline.withAlpha(76) : colorScheme.primary,
              onPressed: isLast ? null : () => _changeArticle(_currentIndex + 1),
            ),
          ],
        ),
      ),
    );
  }
}