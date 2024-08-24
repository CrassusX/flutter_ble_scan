import 'package:dio/dio.dart';

class ApiService {
  static Dio dio = Dio();

  static void init() {
    // 添加全局配置，如基础URL、拦截器等
    dio.options.baseUrl = "http://wxconfig.he-info.cn";
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 8);
  }

  static Future<Map<String, dynamic>?> getDeviceInfo(String deviceNo) async {
    String path =
        'http://124.71.178.182:1101/woosleep-system/woosleep-system/device/main/getByDeviceNo/$deviceNo';
    try {
      var response = await dio.post(path);

      if (response.statusCode == 200) {
        var responseData = response.data;
        return responseData;
      } else {
        return null; // 返回空Map或者其他默认值
      }
    } catch (e) {
      return null; // 返回空Map或者其他默认值
    }
  }
}
