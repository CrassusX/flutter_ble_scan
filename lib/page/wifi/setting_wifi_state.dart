import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

class SettingWifiState extends StatefulWidget {
  const SettingWifiState({super.key});

  @override
  SettingWifiStateState createState() => SettingWifiStateState();
}

class SettingWifiStateState extends State<SettingWifiState> {
  double progress = 10; // 进度百分比，范围为0到1

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VerticalPageControl(
          progress: progress,
        ),
        SvgPicture.asset(
          'images/wifi4.svg', // 图片路径
          height: 50, // 设置图片高度
        ),
        VerticalProgressTip(
          progress: progress,
        )
      ],
    );
  }
}

class VerticalPageControl extends StatefulWidget {
  final double progress; // 进度百分比，范围为0到1
  const VerticalPageControl({super.key, this.progress = 0});

  @override
  State<VerticalPageControl> createState() => VerticalPageControlState();
}

class VerticalPageControlState extends State<VerticalPageControl> {
  late Timer _timer;
  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentProgress += 10; // 每次增加10%
        if (_currentProgress >= 100) {
          _currentProgress = 100; // 限制进度不超过100%
          _timer.cancel(); // 停止定时器
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // 在组件销毁时取消定时器
    super.dispose();
  }

  Color getColor(int index) {
    double percentage = _currentProgress / 100; // 将进度数值转换为百分比
    if (percentage >= 1.0) {
      return Colors.green; // 进度100%时，所有圆点为绿色
    } else {
      if ((percentage * 3).ceil() >= index + 1) {
        return Colors.green; // 根据进度百分比来切换圆点颜色
      } else {
        return Colors.grey;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: getColor(index),
          ),
        );
      }),
    );
  }
}

class VerticalProgressTip extends StatelessWidget {
  final double progress; // 进度百分比，范围为0到1
  const VerticalProgressTip({super.key, this.progress = 0});

  bool get hasComplete => progress >= 100;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text.rich(
        TextSpan(
            text: "$progress",
            style: TextStyle(
                color: hasComplete
                    ? const Color.fromARGB(255, 80, 179, 146)
                    : Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold),
            children: const [
              TextSpan(
                  text: '%',
                  style: TextStyle(fontSize: 16, color: Colors.black))
            ]),
      ),
      hasComplete
          ? FilledButton.tonal(
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStatePropertyAll(Colors.grey.shade300)),
              onPressed: () {},
              child: const Text('完成',
                  style: TextStyle(
                      color: Color.fromARGB(255, 80, 179, 146), fontSize: 16)))
          : Text(
              '请确保无线网络畅通',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
    ]);
  }
}
