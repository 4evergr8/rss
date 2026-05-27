import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rss/database.dart';
import 'package:rss/service/download.dart';
import 'package:rss/service/rss.dart';
import 'package:rss/widget.dart';
import 'package:xml/xml.dart' as xml;

var _db = AppDatabase();

class AddFeedScreen extends StatefulWidget {
  const AddFeedScreen({super.key});

  @override
  State<AddFeedScreen> createState() => _AddFeedScreenState();
}

class _AddFeedScreenState extends State<AddFeedScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _siteUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController(text: '');
  final TextEditingController _iconUrlController = TextEditingController();

  // 新增：编辑区域专用的订阅链接文本控制器
  final TextEditingController _editFeedUrlController = TextEditingController();

  bool _hasLoaded = false;
  String _selectedDisplayMode = 'content';

  Future<void> _pasteClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      setState(() {
        _urlController.text = clipboardData!.text!;
      });
    }
  }

  Future<void> _fetchAndParseFeed() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) {
      showErrorSnackBarGlobal('请输入链接后再解析');
      return;
    }

    final cancelLoading = await showLoadingDialogGlobal();

    try {
      final xmlText = await downloadXmlFromServer(inputUrl);
      final parsedData = parseRss(xmlText);

      // 提取解析出的 feedUrl
      final String parsedFeedUrl = parsedData['feedUrl'] ?? '';

      setState(() {
        _titleController.text = parsedData['title'] ?? '';
        _siteUrlController.text = parsedData['siteUrl'] ?? '';
        _iconUrlController.text = parsedData['iconUrl'] ?? '';
        // 如果返回结果中包含有效的 feedUrl 则使用它，否则使用用户最初输入的链接兜底
        _editFeedUrlController.text = parsedFeedUrl.isNotEmpty ? parsedFeedUrl : inputUrl;
        _hasLoaded = true;
      });
    } catch (error) {
      showErrorSnackBarGlobal(error.toString());
    } finally {
      cancelLoading();
    }
  }

  Future<void> _importOpmlFile() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['opml', 'xml']);

      if (result == null || result.files.single.path == null) {
        return;
      }

      final cancelLoading = await showLoadingDialogGlobal();
      int importCount = 0;

      try {
        final file = File(result.files.single.path!);
        final xmlText = await file.readAsString(encoding: utf8);

        final document = xml.XmlDocument.parse(xmlText);
        final bodyNode = document.findAllElements('body').firstOrNull;

        if (bodyNode == null) {
          throw Exception('未找到有效的 OPML body 节点');
        }

        final List<FeedsCompanion> feedsToInsert = [];
        _parseOutlineNodes(bodyNode.children, '', feedsToInsert);

        if (feedsToInsert.isEmpty) {
          throw Exception('未在文件中找到任何可导入的订阅源');
        }

        await _db.batch((batch) {
          for (final feed in feedsToInsert) {
            batch.insert(_db.feeds, feed, mode: drift.InsertMode.insertOrReplace);
          }
        });

        importCount = feedsToInsert.length;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功导入 $importCount 个订阅源！')));
          Navigator.of(context).pop();
        }
      } catch (error) {
        showErrorSnackBarGlobal('解析或导入失败: $error');
      } finally {
        cancelLoading();
      }
    } catch (e) {
      showErrorSnackBarGlobal('选择文件失败: $e');
    }
  }

  void _parseOutlineNodes(Iterable<xml.XmlNode> nodes, String currentCategory, List<FeedsCompanion> resultList) {
    for (final node in nodes) {
      if (node is xml.XmlElement && node.name.local == 'outline') {
        final xmlUrl = node.getAttribute('xmlUrl')?.trim();
        final textAttr = node.getAttribute('text')?.trim();
        final titleAttr = node.getAttribute('title')?.trim();
        final htmlUrl = node.getAttribute('htmlUrl')?.trim() ?? '';

        final String displayName = (textAttr != null && textAttr.isNotEmpty) ? textAttr : (titleAttr ?? '未命名订阅源');

        if (xmlUrl != null && xmlUrl.isNotEmpty) {
          resultList.add(
            FeedsCompanion(
              feedUrl: drift.Value(xmlUrl),
              siteUrl: drift.Value(htmlUrl),
              title: drift.Value(displayName),
              category: drift.Value(currentCategory),
              iconUrl: const drift.Value(''),
              lastUpdated: const drift.Value('0'),
              displayMode: drift.Value(_selectedDisplayMode),
            ),
          );
        } else {
          if (node.childElements.isNotEmpty) {
            _parseOutlineNodes(node.childElements, displayName, resultList);
          }
        }
      }
    }
  }

  Future<void> _importSqliteFile() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result == null || result.files.single.path == null) {
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认覆盖数据库'),
          content: const Text('导入外部数据库将完全覆盖并替换当前的所有订阅数据，此操作不可逆。是否继续？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认覆盖', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final cancelLoading = await showLoadingDialogGlobal();

      try {
        final selectedFile = File(result.files.single.path!);
        final dbDir = await getApplicationDocumentsDirectory();
        final targetPath = p.join(dbDir.path, 'app_database.sqlite');

        await _db.close();

        await selectedFile.copy(targetPath);

        _db = AppDatabase();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据库覆盖导入成功！')));
          Navigator.of(context).pop();
        }
      } catch (error) {
        showErrorSnackBarGlobal('导入数据库失败: $error');
      } finally {
        cancelLoading();
      }
    } catch (e) {
      showErrorSnackBarGlobal('选择文件失败: $e');
    }
  }

  Future<void> _saveToDatabase() async {
    final cancelLoading = await showLoadingDialogGlobal();

    try {
      await _db
          .into(_db.feeds)
          .insertOnConflictUpdate(
            FeedsCompanion(
              // 注意：此处保存时，主键 feedUrl 使用编辑区域经过修改或兜底的 _editFeedUrlController
              feedUrl: drift.Value(_editFeedUrlController.text.trim()),
              siteUrl: drift.Value(_siteUrlController.text.trim()),
              title: drift.Value(_titleController.text.trim()),
              category: drift.Value(_categoryController.text.trim()),
              iconUrl: drift.Value(_iconUrlController.text.trim()),
              lastUpdated: const drift.Value('0'),
              displayMode: drift.Value(_selectedDisplayMode),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('订阅保存成功！')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      showErrorSnackBarGlobal('保存失败: $error');
    } finally {
      cancelLoading();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _siteUrlController.dispose();
    _categoryController.dispose();
    _iconUrlController.dispose();
    _editFeedUrlController.dispose(); // 妥善释放新控制器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    InputDecoration customInputDecoration(String labelText, IconData prefixIcon) {
      return InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, size: 20, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新订阅', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: customInputDecoration('订阅链接', Icons.link),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 52,
                          child: IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.paste),
                            onPressed: _pasteClipboard,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _fetchAndParseFeed,
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('解析订阅源', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _importOpmlFile,
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('导入 OPML 文件', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.colorScheme.error),
                        foregroundColor: theme.colorScheme.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _importSqliteFile,
                      icon: const Icon(Icons.storage_rounded),
                      label: const Text('导入并覆盖本地数据库 (.sqlite)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            if (_hasLoaded) ...[
              Card(
                margin: const EdgeInsets.symmetric(vertical: 12),
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
                        '订阅源配置',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      // 新增：编辑最终订阅链接的 TextField，支持自定义修改
                      TextField(
                        controller: _editFeedUrlController,
                        maxLines: null,
                        decoration: customInputDecoration('订阅链接', Icons.rss_feed),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        maxLines: null,
                        decoration: customInputDecoration('显示名称', Icons.title),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _siteUrlController,
                        maxLines: null,
                        decoration: customInputDecoration('网站链接', Icons.language),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _categoryController,
                        maxLines: null,
                        decoration: customInputDecoration('分组名', Icons.folder_open),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _iconUrlController,
                        maxLines: null,
                        decoration: customInputDecoration('图标链接', Icons.image_search),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDisplayMode,
                        decoration: customInputDecoration('显示方式', Icons.switch_access_shortcut),
                        dropdownColor: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(value: 'content', child: Text('content 模式 (内置阅读器)')),
                          DropdownMenuItem(value: 'web', child: Text('web 模式 (外部浏览器)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDisplayMode = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveToDatabase,
                        icon: const Icon(Icons.save_alt),
                        label: const Text('保存订阅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
