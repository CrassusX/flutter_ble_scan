import 'package:flutter/material.dart';
import 'seat_wifi_step3_child.dart';

// 二维码扫描成功
class SeatWifiStep3 extends StatelessWidget {
  final Map? data;
  const SeatWifiStep3({super.key, this.data});

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
