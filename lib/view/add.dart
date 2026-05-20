import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart'; // 新增：用于选择本地 OPML 文件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom; // 新增：用于遍历节点
import 'package:html/parser.dart' as html_parser; // 新增：用于解析 XML 结构
import 'package:rss/database.dart';
import 'package:rss/service/download.dart';
import 'package:rss/service/rss.dart';
import 'package:rss/widget.dart';
import 'package:xml/xml.dart' as xml;

// 全局数据库实例引用
final _db = AppDatabase();

class AddFeedScreen extends StatefulWidget {
  const AddFeedScreen({super.key});

  @override
  State<AddFeedScreen> createState() => _AddFeedScreenState();
}

class _AddFeedScreenState extends State<AddFeedScreen> {
  // 控制器：管理每个输入框的文本
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _siteUrlController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController(text: '');
  final TextEditingController _iconUrlController = TextEditingController();

  // 状态：是否成功获取到了 XML 元数据
  bool _hasLoaded = false;

  // 状态：保存时所选择的显示方式，默认为 'content'
  String _selectedDisplayMode = 'content';

  // 点击粘贴按钮触发的函数
  Future<void> _pasteClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      setState(() {
        _urlController.text = clipboardData!.text!;
      });
    }
  }

  // 点击“解析订阅源”按钮触发 the 函数
  Future<void> _fetchAndParseFeed() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) {
      showErrorSnackBarGlobal('请输入链接后再解析');
      return;
    }

    // 1. 在 try 开始前打开加载动画，并拿到关闭动画的回调函数
    final cancelLoading = await showLoadingDialogGlobal();

    try {
      // 2. 调用纯函数下载
      final xmlText = await downloadXmlFromServer(inputUrl);

      // 3. 调用纯函数解析
      final metadata = parseRssXmlMetadata(xmlText);

      // 4. 将解析出的内容塞进对应的文本控制器中，并展现下方的修改输入框
      setState(() {
        _titleController.text = metadata['title'] ?? '';
        _siteUrlController.text = metadata['siteUrl'] ?? '';
        _iconUrlController.text = metadata['iconUrl'] ?? '';
        _hasLoaded = true;
      });
    } catch (error) {
      // 5. 错误分支：使用你现有的全局组件弹窗报错
      showErrorSnackBarGlobal(error.toString());
    } finally {
      // 6. final 分支：雷打不动地关闭动画
      cancelLoading();
    }
  }


// 修改后：使用标准 xml 库以及新版 file_picker 调用的导入函数
  Future<void> _importOpmlFile() async {
    try {
      // 1. 新版 FilePicker 直接调用静态方法
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result == null || result.files.single.path == null) {
        return; // 用户取消了选择
      }

      final cancelLoading = await showLoadingDialogGlobal();
      int importCount = 0;

      try {
        // 2. 读取文件文本内容
        final file = File(result.files.single.path!);
        final xmlText = await file.readAsString(encoding: utf8);

        // 3. 使用标准 XML 库解析大纲树
        final document = xml.XmlDocument.parse(xmlText);
        final bodyNode = document.findAllElements('body').firstOrNull;

        if (bodyNode == null) {
          throw Exception('未找到有效的 OPML body 节点');
        }

        // 4. 递归遍历所有 xml 节点
        final List<FeedsCompanion> feedsToInsert = [];
        _parseOutlineNodes(bodyNode.children, '', feedsToInsert);

        if (feedsToInsert.isEmpty) {
          throw Exception('未在文件中找到任何可导入的订阅源');
        }

        // 5. 利用 Drift 的 batch 工具单事务批量写入数据库
        await _db.batch((batch) {
          for (final feed in feedsToInsert) {
            batch.insert(
              _db.feeds,
              feed,
              mode: drift.InsertMode.insertOrReplace,
            );
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

  // 修改后：配合 xml 库进行递归解析的辅助函数
  void _parseOutlineNodes(Iterable<xml.XmlNode> nodes, String currentCategory, List<FeedsCompanion> resultList) {
    for (final node in nodes) {
      // 过滤掉空白文本换行节点，只处理标准的元素标签
      if (node is xml.XmlElement && node.name.local == 'outline') {
        final xmlUrl = node.getAttribute('xmlUrl')?.trim();
        final textAttr = node.getAttribute('text')?.trim();
        final titleAttr = node.getAttribute('title')?.trim();
        final htmlUrl = node.getAttribute('htmlUrl')?.trim() ?? '';

        final String displayName = (textAttr != null && textAttr.isNotEmpty)
            ? textAttr
            : (titleAttr ?? '未命名订阅源');

        if (xmlUrl != null && xmlUrl.isNotEmpty) {
          // 叶子节点：这是一个具体的订阅源
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
          // 分类节点：向下递归，并将当前节点的名称作为子节点的分组名
          if (node.children.isNotEmpty) {
            _parseOutlineNodes(node.children, displayName, resultList);
          }
        }
      }
    }
  }
  // 点击最下方“保存”按钮触发的函数
  Future<void> _saveToDatabase() async {
    final cancelLoading = await showLoadingDialogGlobal();

    try {
      // 将修改后的文本写入数据库（如果是新连接则插入，已存在则覆盖更新）
      await _db
          .into(_db.feeds)
          .insertOnConflictUpdate(
            FeedsCompanion(
              feedUrl: drift.Value(_urlController.text.trim()),
              siteUrl: drift.Value(_siteUrlController.text.trim()),
              title: drift.Value(_titleController.text.trim()),
              category: drift.Value(_categoryController.text.trim()),
              iconUrl: drift.Value(_iconUrlController.text.trim()),
              lastUpdated: const drift.Value('0'),
              displayMode: drift.Value(_selectedDisplayMode), // 使用下拉选框的选择值
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('订阅保存成功！')));
        Navigator.of(context).pop(); // 关闭当前添加页面
      }
    } catch (error) {
      showErrorSnackBarGlobal('保存失败: $error');
    } finally {
      cancelLoading();
    }
  }

  @override
  void dispose() {
    // 销毁所有控制器，释放内存
    _urlController.dispose();
    _titleController.dispose();
    _siteUrlController.dispose();
    _categoryController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加新订阅')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 第一部分：链接输入框 + 粘贴按钮
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    maxLines: null, // 允许输入框随文字长度自动增加行数
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(labelText: '订阅链接', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(icon: const Icon(Icons.paste), onPressed: _pasteClipboard),
              ],
            ),
            const SizedBox(height: 16),

            // 解析动作按钮
            FilledButton(onPressed: _fetchAndParseFeed, child: const Text('解析订阅源')),
            const SizedBox(height: 12),

            // 新增：导入 OPML 按钮
            OutlinedButton.icon(
              onPressed: _importOpmlFile,
              icon: const Icon(Icons.file_open),
              label: const Text('导入 OPML 文件'),
            ),

            // 第二部分：解析成功后，展开的可编辑输入框
            if (_hasLoaded) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              TextField(
                controller: _titleController,
                maxLines: null, // 自动扩展行数
                decoration: const InputDecoration(labelText: '显示名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _siteUrlController,
                maxLines: null, // 自动扩展行数
                decoration: const InputDecoration(labelText: '网站链接', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _categoryController,
                maxLines: null, // 自动扩展行数
                decoration: const InputDecoration(labelText: '分组名', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _iconUrlController,
                maxLines: null, // 自动扩展行数
                decoration: const InputDecoration(labelText: '图标链接', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // 显示方式下拉选框
              DropdownButtonFormField<String>(
                value: _selectedDisplayMode,
                decoration: const InputDecoration(labelText: '显示方式', border: OutlineInputBorder()),
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

              // 最终保存按钮
              FilledButton.icon(onPressed: _saveToDatabase, icon: const Icon(Icons.save), label: const Text('保存订阅')),
            ],
          ],
        ),
      ),
    );
  }
}
