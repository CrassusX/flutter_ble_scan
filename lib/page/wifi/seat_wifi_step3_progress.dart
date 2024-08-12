import 'dart:async';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_scan/common/util.dart';

class SeatWifiStep3Progress extends StatefulWidget {
  const SeatWifiStep3Progress({super.key});

  @override
  SeatWifiStep3ProgressState createState() => SeatWifiStep3ProgressState();
}

class SeatWifiStep3ProgressState extends State<SeatWifiStep3Progress> {
  double progress = 10; // 进度百分比，范围为0到1

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 10),
              child: VerticalPageControl(
                hasComplete: progress >= 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.asset(
                'images/wifi.png', // 图片路径
                height: 50, // 设置图片高度
              ),
            ),
          ],
        ),
        SizedBox(
          height: 220,
          child: VerticalProgressTip(
            progress: progress,
          ),
        )
      ],
    );
  }
}

class VerticalPageControl extends StatefulWidget {
  final bool hasComplete; // 进度百分比，范围为0到1

  const VerticalPageControl({super.key, this.hasComplete = false});

  @override
  State<VerticalPageControl> createState() => VerticalPageControlState();
}

class VerticalPageControlState extends State<VerticalPageControl> {
  late Timer _timer;
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant VerticalPageControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasComplete != widget.hasComplete && widget.hasComplete) {
      setState(() {
        _timer.cancel();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentPage = (_currentPage + 1) % 3; // 循环变化页面索引
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // 在组件销毁时取消定时器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Transform.rotate(
        angle: 1.5708, // 旋转90度，即将视图变为垂直方向
        child: DotsIndicator(
          dotsCount: 3,
          position: _currentPage,
          decorator: DotsDecorator(
            color: widget.hasComplete
                ? normalColor
                : Colors.grey, // Inactive color
            activeColor: normalColor,
          ),
        ),
      ),
    );
  }
}

class VerticalProgressTip extends StatelessWidget {
  final double progress; // 进度百分比，范围为0到1
  final Function()? onCompleted;
  const VerticalProgressTip({super.key, this.progress = 0, this.onCompleted});

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
                fontSize: 42,
                fontWeight: FontWeight.bold),
            children: const [
              TextSpan(
                  text: '%',
                  style: TextStyle(fontSize: 20, color: Colors.black))
            ]),
      ),
      Text(hasComplete ? "配网已完成" : "设备联网中...",
          style: const TextStyle(color: Colors.grey, fontSize: 16)),
      const SizedBox(
        height: 20,
      ),
      hasComplete
          ? FilledButton.tonal(
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStatePropertyAll(Colors.grey.shade300)),
              onPressed: onCompleted,
              child: const Text('完成',
                  style: TextStyle(
                      color: Color.fromARGB(255, 80, 179, 146), fontSize: 16)))
          : const Text(
              '请确保无线网络畅通',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
            ),
    ]);
  }
}
