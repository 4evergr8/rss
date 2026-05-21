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

  try {
    final response = await dio.get<String>(url);

    if (response.statusCode != 200) {
      throw '请求失败，服务器返回状态码：${response.statusCode}\n返回内容：\n${response.data}';
    }

    return response.data ?? '';
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      throw '网络下载发生错误: 连接超时（2秒）';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw '网络下载发生错误: 服务器返回数据超时（10秒）';
    } else if (e.response != null) {
      throw '请求失败，服务器返回状态码：${e.response?.statusCode}\n返回内容：\n${e.response?.data}';
    } else {
      throw '网络下载发生错误: ${e.message}';
    }
  } catch (e) {
    throw '网络下载发生错误: $e';
  }
}