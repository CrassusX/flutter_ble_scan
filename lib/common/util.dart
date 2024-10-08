import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ble_scan/event/device_info.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import '../common/FitTool.dart';

Color stringToColor(String hexColor) {
  String formattedColor = hexColor.replaceAll("#", "");
  int colorValue = int.parse("0xFF$formattedColor");
  return Color(colorValue);
}

showToast(String msg, {Color color = Colors.black87}) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 1,
    backgroundColor: color,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}

class LoadingDialog {
  static show(String name) {
    Get.dialog(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(minWidth: 280.rpx),
              decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(255, 255, 255, 1),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        decoration: TextDecoration.none),
                  )
                ],
              ),
            )
          ],
        ),
        barrierDismissible: false,
        barrierColor: Colors.transparent);
  }

  static hide() {
    Get.back();
  }
}

Future showInputCustomDialog(BuildContext context,
    {String name = "", String inputPlaceHolder = '请输入wifi密码'}) async {
  // Completer<String> completer = Completer<String>();
  TextEditingController textEditingController = TextEditingController();
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Text(
                  'wifi名称：$name',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 40,
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 13),
                  enabled: false,
                  decoration: InputDecoration(
                    filled: true,
                    hintText: inputPlaceHolder,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        // 清除输入框的内容
                        // 这里的 controller 是 TextEditingController 对象
                        textEditingController.clear();
                      },
                    ),
                  ),
                  controller: textEditingController,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop("cancel"); // 关闭提示框
                      },
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(
                            Theme.of(context).primaryColor),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 处理确定按钮点击事件
                        String value = textEditingController.text; // 关闭提示框
                        Navigator.of(context).pop(value);
                      },
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all(Colors.white),
                        backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).primaryColor),
                      ),
                      child: const Text('确定'),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// 底部弹框显示
showCustomBottomSheet(BuildContext ctx, Widget child, {double factor = 0.8}) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
    ),
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: factor,
        child: child,
      );
    },
  );
}

(bool, DeviceType) isSuccessfulScan(String? code) {
  if (code == null || code.length < 2) {
    return (false, DeviceType.unknown); // 扫码失败，码长度不足
  }

  String firstLetter = code.substring(0, 1);
  if (firstLetter == 'Z' ||
      firstLetter == 'D' ||
      firstLetter == 'T' ||
      firstLetter == 'Y' ||
      firstLetter == 'X' ||
      firstLetter == 'M') {
    DeviceType type = DeviceTypeEx.fromName(firstLetter);
    return (true, type); // 扫码成功
  } else {
    return (false, DeviceType.unknown); // 扫码失败，不符合设备码前缀要求
  }
}

Color get normalColor => colorFromHex('#77B9A8');
Color get greyColor => Colors.grey.shade600;
Color get greyColor100 => Colors.grey.shade100;

Color colorFromHex(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor'; // 添加透明度值FF
  }
  return Color(int.parse(hexColor, radix: 16));
}
