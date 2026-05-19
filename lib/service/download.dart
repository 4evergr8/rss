import 'package:http/http.dart' as http;

/// 纯函数：传入链接，下载文本内容。仅处理下载过程中的网络错误与非200状态码，超时时间为10秒。
Future<String> downloadXmlFromServer(String url) async {
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; MyRssReader/1.0.0; +contact@example.com) Dart/3.11',
        'Accept': 'application/xml, text/xml, application/rss+xml, application/atom+xml, */*',
      },
    ).timeout(const Duration(seconds: 10));

    // 如果状态码不是 200，视为请求失败，并附带状态码与响应体
    if (response.statusCode != 200) {
      throw '请求失败，服务器返回状态码：${response.statusCode}\n返回内容：\n${response.body}';
    }

    return response.body;
  } catch (e) {
    // 捕获超时、断网等底层网络连接硬错误，并直接向上抛出详细信息
    throw '网络下载发生错误: $e';
  }
}