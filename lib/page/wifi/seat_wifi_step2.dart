import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 二维码扫描成功
class SeatWifiStep2 extends StatelessWidget {
 final  String? deviceId;
  const SeatWifiStep2({super.key, this.deviceId});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: //通过ConstrainedBox来确保Stack占满屏幕
          ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Stack(
          alignment: Alignment.center, //指定未定位或部分定位widget的对齐方式
          children: <Widget>[
            Positioned(
              top: -40,
              left: 0,
              right: 0,
              bottom: 0,
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
                  Image.asset(
                    'images/seat.png', // 图片路径
                    height: 80, // 设置图片高度
                  ),
                  const Text(
                    '健康评估垫', // 或 智能睡测仪
                    style: TextStyle(
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
                      onPressed: () {},
                      child: const Text('确认无误，下一步',
                          style: TextStyle(
                              color: Color.fromARGB(255, 80, 179, 146),
                              fontSize: 16)))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
