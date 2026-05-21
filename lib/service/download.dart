import 'package:dio/dio.dart';

Future<String> downloadXmlFromServer(String url) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; MyRssReader/1.0.0; +contact@example.com) Dart/3.11',
        'Accept': 'application/xml, text/xml, application/rss+xml, application/atom+xml, */*',
      },
    ),
  );

  final response = await dio.get<String>(url);
  if (response.statusCode != 200) {
    throw '请求失败，服务器返回状态码：${response.statusCode}\n返回内容：\n${response.data}';
  }
  return response.data ?? '';
}
