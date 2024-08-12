import 'package:flutter/material.dart';

class SeatWifiStep3Setting extends StatefulWidget {
  const SeatWifiStep3Setting({super.key});

  @override
  SeatWifiStep3SettingState createState() => SeatWifiStep3SettingState();
}

class SeatWifiStep3SettingState extends State<SeatWifiStep3Setting> {
  double progress = 10; // 进度百分比，范围为0到1

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [Text("网络设置")],
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.wifi, color: Colors.black),
              suffixIcon: Icon(Icons.arrow_forward_ios),
              hintText: '请选择WIFI',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock, color: Colors.black),
              hintText: '请输入密码',
            ),
          )
        ],
      ),
    );
  }
}
