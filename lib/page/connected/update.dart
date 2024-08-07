import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/util.dart';
import '../../controller/GlobalController.dart';
import '../../dio/dio.dart';
import '../../event/UpdateEvent.dart';
import 'package:flutter_ble_scan/lib/ble.dart' as ble;

class UpgradeWidget extends StatefulWidget {
  const UpgradeWidget({super.key});

  @override
  UpgradeWidgetState createState() => UpgradeWidgetState();
}

class UpgradeWidgetState extends State<UpgradeWidget> {
  List<String> fileList = [];
  int fileIndex = -1;
  int speedIndex = 0;
  List<int> speedList = [100, 150, 200, 250, 300, 400, 500, 1000];
  TextEditingController textEditingController = TextEditingController();
  List<int> currentFile = [];

  @override
  void initState() {
    super.initState();
    showFileList();
    textEditingController.text = "/root/mtd/update";
  }

  showFileList() {
    fileIndex = -1;
    ApiService.dio.get("/ble/api/upload/fileList").then((value) {
      setState(() {
        fileList = value.data["data"].cast<String>();
      });
    }).catchError((e) {
      // print("文件列表获取失败 $e");
      // showToast("文件列表获取失败 $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildInputRow("升级路径：", textEditingController.text),
        buildPickerRow(1, "升级速度：", speedList),
        buildPickerRow(2, "升级固件：", fileList),
        buildButtonRow(),
      ],
    );
  }

  Widget buildInputRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Expanded(
          child: TextField(
            textAlign: TextAlign.right,
            controller: textEditingController,
          ),
        ),
      ],
    );
  }

  Widget buildPickerRow(int type, String label, List items) {
    List<DropdownMenuItem<int>> arr = [];
    if (type == 2) {
      arr.add(const DropdownMenuItem<int>(
        value: -1,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text("请选择升级固件"),
        ),
      ));
    }

    for (int i = 0; i < items.length; i++) {
      arr.add(DropdownMenuItem<int>(
        value: i,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(items[i].toString()),
        ),
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Expanded(
          child: DropdownButton(
            isExpanded: true, // 设置isExpanded为true
            value: type == 1 ? speedIndex : fileIndex,
            onChanged: (int? newValue) {
              setState(() {
                if (type == 1) {
                  speedIndex = newValue!;
                } else {
                  fileIndexChange(newValue!);
                }
              });
            },
            items: arr,
          ),
        ),
      ],
    );
  }

  Widget buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: showFileList,
          child: const Text('刷新文件列表'),
        ),
        ElevatedButton(
          onPressed: () => update(true),
          child: const Text('断点升级'),
        ),
        ElevatedButton(
          onPressed: () => update(false),
          child: const Text('升级'),
        ),
      ],
    );
  }

  void fileIndexChange(int newIndex) {
    setState(() {
      fileIndex = newIndex;
    });
    if (fileIndex < 0) {
      return;
    }
    LoadingDialog.show("文件下载中");
    ApiService.dio
        .get<List<int>>(
            "/ble/api/upload/downFile?filename=${fileList[fileIndex]}",
            options: Options(responseType: ResponseType.bytes))
        .then((v) {
      currentFile = v.data as List<int>;
      LoadingDialog.hide();
    }).catchError((e) {
      print("downFile error: $e");
      LoadingDialog.hide();
    });
  }

  void update(bool isBreak) {
    toSendString(currentFile, isBreak);
  }

  String calculateCRC16Modbus(List<int> data) {
    const int poly = 0xA001;
    int crc = 0xFFFF;

    for (int byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc >>= 1;
          crc ^= poly;
        } else {
          crc >>= 1;
        }
      }
    }
    // Convert the CRC16 integer value to a hexadecimal string with correct byte order
    String crcString = crc.toRadixString(16).toUpperCase();
    // Pad the CRC string with zeros if needed to ensure correct length
    crcString = crcString.padLeft(4, '0');

    // Swap bytes if necessary (assuming little-endian byte order)
    crcString = crcString.substring(2, 4) + crcString.substring(0, 2);

    return crcString;
  }

  onMessageCode3(d) {
    UpdateEvent updateEvent = UpdateEvent();
    if (d is String) {
      updateEvent.code = 1;
      updateEvent.dataString = d;
    } else {
      updateEvent.code = 2;
      updateEvent.data = d;
    }
    Get.find<GlobalController>().eventBus.fire(updateEvent);
  }

  void toSendString(List<int> data, bool isBreak) {
    var jvalue = Get.find<GlobalController>().updateDevice['sendSuccess'];
    int jindu = jvalue ?? 0;
    Get.find<GlobalController>()
        .connectedDeviceProp
        ?.write3OfString("blog disable");
    int packctNum = ble.mcuMax;
    if (Platform.isIOS) {
      packctNum = 150;
    }
    String crc16 = calculateCRC16Modbus(currentFile);
    int step = ((packctNum - 12 - 7 - 61) * 0.75).floor() - 1;
    int x = 0;
    // ignore: unused_local_variable
    int startIndex = 0;
    List<String> updateArr = [];
    String startString =
        "${data.length},$crc16,${speedList[speedIndex]},startDeviceUpdate:${(data.length / step).ceil()}";
    print(startString);
    onMessageCode3(startString);

    for (int i = 0; i < data.length; i = i + step, x++) {
      int start = x * step;
      int end = x * step + step;

      if (end > data.length) {
        end = data.length;
      }

      String sendDate =
          'mmx path="${textEditingController.text}" write base64 len=${end - start} offset=$start data=';
      List<int> ab = data.sublist(start, end);
      String sendData2 = base64Encode(ab);
      sendDate += sendData2;
      updateArr.add(sendDate);
    }

    updateArr.add("reboot");

    if (isBreak) {
      if (jindu > 300) {
        jindu = jindu - 300;
      } else {
        jindu = 0;
      }
      onMessageCode3("startIndex:$jindu");
      updateArr.removeRange(0, jindu);
    }
    onMessageCode3(updateArr);
  }
}
