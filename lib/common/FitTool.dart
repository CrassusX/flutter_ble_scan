import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FitTool {
  static double rpx = 0;
  static bool isInit = false;
  static init(double v) {
    if (v < 1) {
      return;
    }
    if (isInit == false) {
      isInit = true;
      rpx = v / 750.0;
    }
  }

  static double getPx(double size) {
    return rpx * size * 2.0;
  }

  static double getRpx(double size) {
    return rpx * size;
  }
}

extension FitInt on int {
  double get px {
    return FitTool.getPx(toDouble());
  }

  double get rpx {
    return FitTool.getRpx(toDouble());
  }
}

extension FitDouble on double {
  double get px {
    return FitTool.getPx(this);
  }

  double get rpx {
    return FitTool.getRpx(this);
  }
}

showToast(String msg, {Color color = Colors.black87}) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14.0);
}
