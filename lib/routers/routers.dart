import 'package:flutter/cupertino.dart';
import 'package:flutter_ble_scan/page/wifi/seat_wifi_step1.dart';
import 'package:flutter_ble_scan/page/wifi/seat_wifi_step2.dart';
import 'package:flutter_ble_scan/page/wifi/seat_wifi_step3.dart';
import 'package:flutter_ble_scan/scan/scanner_overlay.dart';
import '../page/connected/wifi.dart';
import '../page/index.dart';
import '../page/login.dart';

var routes = {
  "/login": (contxt) => const Login(),
  "/index": (contxt) => const index(),
  "/wifi": (context) => const Wifi(),
  "/qrScan": (context) => const QrcodeScanner(),
  "/qrScanSuccess": (context) => const SeatWifiStep2(),
  "/settingWifi": (context) => const SeatWifiStep3(),
  "/seatWifiStep1": (context) => const SeatWifiStep1(),
  "/seatWifiStep2": (context) => const SeatWifiStep2(),
  "/seatWifiStep3": (context) => const SeatWifiStep3(),

};

//2、配置onGenerateRoute  固定写法  这个方法也相当于一个中间件，这里可以做权限判断
var onGenerateRoute = (RouteSettings settings) {
  final String? name = settings.name; //  /news 或者 /search
  final Function? pageContentBuilder =
      routes[name]; //  Function = (contxt) { return const NewsPage()}

  if (pageContentBuilder != null) {
    if (settings.arguments != null) {
      final Route route = CupertinoPageRoute(
          builder: (context) =>
              pageContentBuilder(context, arguments: settings.arguments));
      return route;
    } else {
      final Route route =
          CupertinoPageRoute(builder: (context) => pageContentBuilder(context));

      return route;
    }
  }
  return null;
};
