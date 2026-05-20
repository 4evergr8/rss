import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rss/database.dart';
import 'package:rss/widget.dart';
import 'package:share_plus/share_plus.dart';

final _db = AppDatabase();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Feed> _allFeeds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    try {
      final feeds = await _db.select(_db.feeds).get();
      setState(() {
        _allFeeds = feeds;
        _isLoading = false;
      });
    } catch (e) {
      showErrorSnackBarGlobal('加载订阅列表失败: $e');
    }
  }

  Future<void> _exportOpml() async {
    final cancelLoading = await showLoadingDialogGlobal();
    try {
      if (_allFeeds.isEmpty) {
        throw '没有可导出的订阅源';
      }

      final sb = StringBuffer();
      sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      sb.writeln('<opml version="2.0">');
      sb.writeln('  <head>');
      sb.writeln('    <title>RSS Feeds Export</title>');
      sb.writeln('  </head>');
      sb.writeln('  <body>');

      final groups = <String, List<Feed>>{};
      for (final feed in _allFeeds) {
        final cat = feed.category.trim();
        groups.putIfAbsent(cat, () => []).add(feed);
      }

      groups.forEach((category, feeds) {
        if (category.isEmpty) {
          for (final feed in feeds) {
            sb.writeln('    <outline text="${_escapeXml(feed.title)}" title="${_escapeXml(feed.title)}" type="rss" xmlUrl="${_escapeXml(feed.feedUrl)}" htmlUrl="${_escapeXml(feed.siteUrl)}"/>');
          }
        } else {
          sb.writeln('    <outline text="${_escapeXml(category)}" title="${_escapeXml(category)}">');
          for (final feed in feeds) {
            sb.writeln('      <outline text="${_escapeXml(feed.title)}" title="${_escapeXml(feed.title)}" type="rss" xmlUrl="${_escapeXml(feed.feedUrl)}" htmlUrl="${_escapeXml(feed.siteUrl)}"/>');
          }
          sb.writeln('    </outline>');
        }
      });

      sb.writeln('  </body>');
      sb.writeln('</opml>');

      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, 'feeds_export.opml'));
      await file.writeAsString(sb.toString(), encoding: utf8);

      cancelLoading();
      await Share.shareXFiles([XFile(file.path)], text: '导出 OPML 订阅源');
    } catch (e) {
      cancelLoading();
      showErrorSnackBarGlobal('导出 OPML 失败: $e');
    }
  }

  Future<void> _exportDatabase() async {
    final cancelLoading = await showLoadingDialogGlobal();
    try {
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbDir.path, 'app_database.sqlite'));

      if (!await dbFile.exists()) {
        throw '未找到数据库文件';
      }

      final tempDir = await getTemporaryDirectory();
      final backupFile = File(p.join(tempDir.path, 'rss_backup.sqlite'));
      await dbFile.copy(backupFile.path);

      cancelLoading();
      await Share.shareXFiles([XFile(backupFile.path)], text: '备份数据库文件');
    } catch (e) {
      cancelLoading();
      showErrorSnackBarGlobal('导出数据库失败: $e');
    }
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  void _showEditDialog(Feed feed) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: feed.title);
    final categoryController = TextEditingController(text: feed.category);
    final urlController = TextEditingController(text: feed.feedUrl);
    String displayMode = feed.displayMode;

    InputDecoration dialogInputDeco(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              title: const Text('修改订阅源', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    TextField(controller: titleController, decoration: dialogInputDeco('显示名称')),
                    const SizedBox(height: 12),
                    TextField(controller: categoryController, decoration: dialogInputDeco('分组名')),
                    const SizedBox(height: 12),
                    TextField(controller: urlController, decoration: dialogInputDeco('订阅链接')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: displayMode,
                      decoration: dialogInputDeco('显示方式'),
                      dropdownColor: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 'content', child: Text('content 模式')),
                        DropdownMenuItem(value: 'web', child: Text('web 模式')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => displayMode = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认删除'),
                        content: Text('确定要删除订阅源 [${feed.title}] 吗？\n这将连带删除其关联的所有文章。'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('确定删除', style: TextStyle(color: theme.colorScheme.error)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      final cancelLoading = await showLoadingDialogGlobal();
                      try {
                        await (_db.delete(_db.articles)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl))).go();
                        await (_db.delete(_db.feeds)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl))).go();
                        Navigator.pop(context);
                        _loadFeeds();
                      } catch (e) {
                        showErrorSnackBarGlobal('删除失败: $e');
                      } finally {
                        cancelLoading();
                      }
                    }
                  },
                  child: Text('删除订阅', style: TextStyle(color: theme.colorScheme.error)),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                TextButton(
                  onPressed: () async {
                    final cancelLoading = await showLoadingDialogGlobal();
                    try {
                      await (_db.update(_db.feeds)..where((tbl) => tbl.feedUrl.equals(feed.feedUrl))).write(
                        FeedsCompanion(
                          title: drift.Value(titleController.text.trim()),
                          category: drift.Value(categoryController.text.trim()),
                          feedUrl: drift.Value(urlController.text.trim()),
                          displayMode: drift.Value(displayMode),
                        ),
                      );
                      Navigator.pop(context);
                      _loadFeeds();
                    } catch (e) {
                      showErrorSnackBarGlobal('更新失败: $e');
                    } finally {
                      cancelLoading();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据与订阅管理', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '备份与导出',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _exportOpml,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: const Text('导出为 OPML 文件', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _exportDatabase,
                    icon: const Icon(Icons.storage_rounded),
                    label: const Text('备份本地数据库 (.sqlite)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              '当前已订阅数量 (${_allFeeds.length})',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
            ),
          ),
          _allFeeds.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('暂无任何订阅源', style: TextStyle(color: Colors.grey)),
            ),
          )
              : Column(
            children: _allFeeds.map((feed) {
              final groupText = feed.category.trim().isEmpty ? '未分组' : feed.category.trim();
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    feed.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '[$groupText] ${feed.feedUrl}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  ),
                  trailing: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
                  onTap: () => _showEditDialog(feed),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}