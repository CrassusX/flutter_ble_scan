import 'package:flutter/material.dart';
import 'package:flutter_ble_scan/common/util.dart';
import 'package:flutter_ble_scan/controller/setting_wifi_service.dart';

// 二维码扫描成功
class SeatWifiStep1 extends StatefulWidget {
  const SeatWifiStep1({
    super.key,
  });

  @override
  State<SeatWifiStep1> createState() => _SeatWifiStep1State();
}

class _SeatWifiStep1State extends State<SeatWifiStep1> {
  bool _hasChecked = false;

  _onChecked(bool? value) {
    setState(() {
      _hasChecked = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    var scanAsset = _hasChecked
        ? 'images/qr_scan_enable.png'
        : 'images/qr_scan_disable.png';
    return Scaffold(
      body: //通过ConstrainedBox来确保Stack占满屏幕
          ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap:
                    _hasChecked ? GetSettingWifiService.to.onGoScanWifi : null,
                child: Image.asset(
                  scanAsset, // 图片路径
                  height: 100, // 设置图片高度
                ),
              ), // 图片
              const SizedBox(height: 16), // 间距
              const Text('请确认蓝牙开后状态后点击扫码'), // 文字描述
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _hasChecked
                    ? Text("请确保设备处于通电状态", style: TextStyle(color: greyColor))
                    : const SizedBox(
                        height: 20,
                      ),
              ),
              const SizedBox(height: 40), // 间距
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _hasChecked,
                    onChanged: _onChecked,
                    fillColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return normalColor;
                      }
                      return greyColor;
                    }),
                  ), // 复选框
                  InkWell(
                      onTap: () => _onChecked(!_hasChecked),
                      child: const Text('确认蓝牙已开后')), // 文字描述
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
