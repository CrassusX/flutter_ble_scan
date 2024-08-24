import 'package:flutter/material.dart';
import 'package:flutter_ble_scan/common/common_widget.dart';
import 'package:flutter_ble_scan/controller/setting_wifi_service.dart';
import 'package:flutter_ble_scan/event/device_info.dart';
import 'package:get/get.dart';

import 'seat_wifi_step3.dart';

// 二维码扫描成功
class SeatWifiStep2 extends StatelessWidget {
  final String? deviceId;
  const SeatWifiStep2({super.key, this.deviceId});

  @override
  Widget build(BuildContext context) {
    String? assetPath = GetSettingWifiService.to.deviceType.assetPath;
    return WrapScaffold(
      child: //通过ConstrainedBox来确保Stack占满屏幕
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'images/success.png', // 图片路径
                  height: 100, // 设置图片高度
                ),
                const Text(
                  '扫码完成',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  height: Get.height * 0.1,
                ),
                if (assetPath != null)
                  Image.asset(
                    assetPath, // 图片路径
                    height: 80, // 设置图片高度
                  ),
                Text(
                  GetSettingWifiService.to.deviceType.atName, // 或 智能睡测仪
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '设备号：$deviceId',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 16,
                ),
                FilledButton.tonal(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll(Colors.grey.shade300)),
                    onPressed: () {
                      Get.to(() => const SeatWifiStep3());
                    },
                    child: const Text('确认无误，下一步',
                        style: TextStyle(
                            color: Color.fromARGB(255, 80, 179, 146),
                            fontSize: 16)))
              ],
            ),
          ),
    );
  }
}
