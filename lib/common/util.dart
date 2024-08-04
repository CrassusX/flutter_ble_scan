import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        Container(
          // color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  minWidth: 280.rpx
                ),
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
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Text(
                  'wifi名称：${name}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 30),
              Container(
                height: 40,
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    hintText: inputPlaceHolder,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // textEditingController.dispose();
                        Navigator.of(context).pop("cancel"); // 关闭提示框
                        // completer.completeError("用户 cancel");
                      },
                      style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor),),
                      child: Text('取消'),
                    ),
                  ),
                  SizedBox(width: 30),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 处理确定按钮点击事件
                        String value = textEditingController.text;// 关闭提示框
                        Navigator.of(context).pop("$value");
                        // textEditingController.dispose();
                        // completer.complete(value);
                      },
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor),),
                      child: Text('确定'),
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
  // return completer.future;
}
