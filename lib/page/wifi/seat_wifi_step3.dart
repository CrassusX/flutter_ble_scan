import 'package:flutter/material.dart';
import 'seat_wifi_step3_progress.dart';
import 'seat_wifi_step3_setting.dart';

// 二维码扫描成功
class SeatWifiStep3 extends StatefulWidget {
  const SeatWifiStep3({super.key});

  @override
  State<SeatWifiStep3> createState() => SeatWifiStep3State();
}

class SeatWifiStep3State extends State<SeatWifiStep3> {
  bool _isSetting = true;

  _onNextStep() {
    setState(() {
      _isSetting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: //通过ConstrainedBox来确保Stack占满屏幕
          Container(
        constraints: const BoxConstraints.expand(),
        padding: const EdgeInsets.only(top: 100),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'images/seat.png', // 图片路径
                height: 180, // 设置图片高度
              ),
              _isSetting
                  ? SeatWifiStep3Setting(
                      onNext: _onNextStep,
                    )
                  : const SeatWifiStep3Progress()
            ],
          ),
        ),
      ),
    );
  }
}
