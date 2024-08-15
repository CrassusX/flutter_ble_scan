import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

AppBar headerBar(VoidCallback? onPressed, String? title) {
  return AppBar(
    title: Text(
      title ?? "",
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    automaticallyImplyLeading: false,
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.white,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: onPressed,
    ),
    systemOverlayStyle: const SystemUiOverlayStyle(
      // Status bar color
      statusBarColor: Colors.white,
      // Status bar brightness (optional)
      statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
      statusBarBrightness: Brightness.light, // For iOS (dark icons)
    ),
  );
}

showAlertDialog(BuildContext context, VoidCallback callBack) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            content: const Text('请开启"位置"权限, 用于获取Wi-Fi名称'),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消')),
              TextButton(
                  onPressed: () {
                    callBack();
                    Navigator.pop(context);
                  },
                  child: const Text('去开启')),
            ],
          ));
}

var showAlert = false;
showSwitchDialog(BuildContext context, VoidCallback callBack, String wifiName) {
  if (showAlert) {
    return;
  }
  showAlert = true;
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            content: Text("检测到当前网络与设置Wi-Fi不同,  是否使用'$wifiName'作为Wi-Fi名称"),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    showAlert = false;
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.grey),
                  )),
              TextButton(
                  onPressed: () {
                    callBack();
                    showAlert = false;
                    Navigator.pop(context);
                  },
                  child: const Text('确定')),
            ],
          ));
}

class WrapScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  const WrapScaffold({super.key, this.title, required this.child});

  void _popBack() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: headerBar(_popBack, title),
      body: ConstrainedBox(
          constraints: const BoxConstraints.expand(), child: child),
    );
  }
}
