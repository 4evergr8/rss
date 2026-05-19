import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rss/database.dart';
import 'package:rss/service/download.dart';
import 'package:rss/service/rss.dart';
import 'package:rss/widget.dart';

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
  final TextEditingController _categoryController = TextEditingController(text: '默认');
  final TextEditingController _iconUrlController = TextEditingController();

  // 状态：是否成功获取到了 XML 元数据
  bool _hasLoaded = false;

  // 点击粘贴按钮触发的函数
  Future<void> _pasteClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      setState(() {
        _urlController.text = clipboardData!.text!;
      });
    }
  }

  // 点击“解析订阅源”按钮触发的函数
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
              displayMode: const drift.Value('list'),
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
