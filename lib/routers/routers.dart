import 'package:flutter/cupertino.dart';
import '../page/connected/wifi.dart';
import '../page/index.dart';
import '../page/login.dart';
import '../page/test.dart';

var routes = {
  "/login": (contxt) => const login(),
  "/index": (contxt) => const index(),
  "/test": (context) => const testone(),
  "/wifi": (context) => const Wifi()
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