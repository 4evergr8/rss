import 'dart:io';

import 'package:xml/xml.dart';

/// 纯函数：传入 XML 文本，直接返回包含 title, siteUrl, iconUrl 和 articles 列表的 Map 键值对
Map<String, dynamic> parseRss(String xmlString) {
  try {
    final document = XmlDocument.parse(xmlString);
    final channel = document.findAllElements('channel').firstOrNull;

    if (channel == null) {
      throw '该订阅源不是标准的 RSS 2.0 格式（未找到 channel 标签）。\n收到的内容：\n$xmlString';
    }

    // 解析订阅源元数据
    final feedTitle = channel.findElements('title').firstOrNull?.innerText ?? '未命名订阅源';
    final feedSiteUrl = channel.findElements('link').firstOrNull?.innerText ?? '';
    final feedIconUrl = channel.findElements('image').firstOrNull?.findElements('url').firstOrNull?.innerText ?? '';

    // 解析文章列表数据
    final List<Map<String, String>> articlesList = [];
    final items = channel.findElements('item');

    for (var item in items) {
      final guid = item.findElements('guid').firstOrNull?.innerText ?? '';
      final title = item.findElements('title').firstOrNull?.innerText ?? '无标题';
      final link = item.findElements('link').firstOrNull?.innerText ?? '';
      final description = item.findElements('description').firstOrNull?.innerText ?? '';
      final content = item.findElements('content:encoded').firstOrNull?.innerText ?? item.findElements('content').firstOrNull?.innerText ?? '';

      // 解析 enclosure 媒体链接
      final enclosureNode = item.findElements('enclosure').firstOrNull;
      final enclosure = enclosureNode?.getAttribute('url') ?? '';

      final author = item.findElements('dc:creator').firstOrNull?.innerText ?? item.findElements('author').firstOrNull?.innerText ?? '';

      // 调用时间戳洗涤逻辑
      final rawDate = item.findElements('pubDate').firstOrNull?.innerText;
      final dateTimestamp = _parseDateToTimestamp(rawDate);

      // 如果 guid 为空，用链接兜底，确保主键不为空
      final finalGuid = guid.isNotEmpty ? guid : link;

      articlesList.add({
        'guid': finalGuid.trim(),
        'title': title.trim(),
        'link': link.trim(),
        'description': description.trim(),
        'content': content.trim(),
        'enclosure': enclosure.trim(),
        'author': author.trim(),
        'date': dateTimestamp,
        'isRead': 'false',
      });
    }

    return {
      'title': feedTitle.trim(),
      'siteUrl': feedSiteUrl.trim(),
      'iconUrl': feedIconUrl.trim(),
      'articles': articlesList,
    };
  } catch (e) {
    if (e.toString().contains('未找到 channel 标签')) {
      rethrow;
    }
    throw '解析 XML 发生错误: $e\n收到的内容：\n$xmlString';
  }
}

/// 内部辅助函数：清洗时间戳为10位秒级字符串
String _parseDateToTimestamp(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }
  try {
    return (DateTime.parse(rawDate).millisecondsSinceEpoch ~/ 1000).toString();
  } catch (_) {
    try {
      return (HttpDate.parse(rawDate).millisecondsSinceEpoch ~/ 1000).toString();
    } catch (_) {
      return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    }
  }
}