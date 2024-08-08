import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'setting_wifi_state.dart';

// 二维码扫描成功
class SettingWifi extends StatelessWidget {
  final Map? data;
  const SettingWifi({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: //通过ConstrainedBox来确保Stack占满屏幕
          Container(
        constraints: const BoxConstraints.expand(),
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'images/seat.png', // 图片路径
              height: 180, // 设置图片高度
            ),
            const SettingWifiState()
          ],
        ),
      ),
    );
  }
}
