import 'package:dio/dio.dart';
import 'package:get/get.dart';

class ApiService {
  static Dio dio = Dio();

  static void init() {
    // 添加全局配置，如基础URL、拦截器等
    dio.options.baseUrl = "http://wxconfig.he-info.cn";
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 8);
    // 添加其他配置...

    // 添加拦截器（可选）
    // dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (options, handler) {
    //     print("---> ${options.method}, ${options.path}, ${options.data}");
    //     options.headers['token'] = Get.find<GlobalController>().token.value;
    //     return handler.next(options);
    //   },
    //   onResponse: (response, handler) {
    //     // 在响应处理前的操作，例如解析响应数据
    //     if (response.realUri.toString().contains("/login")) {
    //       String? token = response.headers.value('token');
    //       if (token != null) {
    //         print("token = ${token}");
    //         Get.find<GlobalController>().token.value = token;
    //       }
    //     }
    //     print("<--- ${response.statusCode}, ${response.data}");
    //     if (response.data is Map && response.data['code'] != null) {
    //       if (response.data['code'] == 1) {
    //         return handler.next(response);
    //       } else {
    //         return handler.reject(DioException.badResponse(
    //             statusCode: 403,
    //             requestOptions: response.requestOptions,
    //             response: response));
    //       }
    //     } else if (response.data is List) {
    //       return handler.next(response);
    //     }
    //   },
    //   onError: (e, handler) {
    //     // 错误处理，例如打印错误信息
    //     print("DioError: $e");
    //     return handler.reject(e);
    //   },
    // ));
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
