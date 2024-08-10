import 'package:flutter/material.dart';
import 'package:flutter_ble_scan/controller/setting_wifi_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '/common/FitTool.dart';
import '/controller/AllControllerBinding.dart';
import '/dio/dio.dart';
import '/routers/routers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  await GetStorage.init();
  Get.lazyPut(() => GetSettingWifiService());
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
    var maxsize = MediaQuery.of(context).size;
    print("myapp build: width: ${maxsize.width} height: ${maxsize.height}");
    FitTool.init(
        maxsize.width < maxsize.height ? maxsize.width : maxsize.height);
    ApiService.init();
    // login();
    if (maxsize.width < 1) {
      print("maxsize.width ${maxsize.width}");
      return Container();
    } else {
      print("maxsize.width ${maxsize.width}");
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        initialBinding: AllControllerBinding(),
        theme: ThemeData(
          primaryColor: Colors.blue,
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
              color: Colors.blue, foregroundColor: Colors.white),
        ),
        onGenerateRoute: onGenerateRoute,
        initialRoute: "/seatWifiStep1",
        // home: MyApp(),
      );
    }
  }
}
