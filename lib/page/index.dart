import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_scan/scan/scanner_overlay.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../common/FitTool.dart';
import '../common/util.dart';
import '../controller/GlobalController.dart';
import '../event/DisConnectedEvent.dart';
import '../event/UpdateEvent.dart';
import '../lib/ble.dart' as ble;
import '../lib/Websocket.dart';
import '../page/connected/connected.dart';

class index extends StatefulWidget {
  const index({super.key});

  @override
  State<index> createState() => _indexState();
}

class _indexState extends State<index> {
  String id = "";
  double _rssichange = -70.0;
  TextEditingController findInputC = TextEditingController();
  bool isText = false;
  FocusNode _focusNode = FocusNode();
  List devices = [];
  bool isConnected = false;
  ble.ConnectedDeviceProp? currentConnectedDeviceProp;
  late WebsocketProp websocketProp;
  String ip = "wxconfig.he-info.cn";
  late BuildContext currentContext;
  bool isShowLoading = false;
  var updateDevice = Get.find<GlobalController>().updateDevice;
  Timer? updateDeviceTimer;
  List<String> updateDeviceSendArr = [];
  late StreamSubscription updateSubscription;
  GlobalKey global_connect = GlobalKey();
  // String ip = "192.168.1.86:8086";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    findInputC.text = "a";
    isText = true;
    ble.findInput = findInputC.text;
    ble.start(findCall);
    websocketProp = WebsocketProp();
    getId().then((value) {
      print("then getid $value");
      websocketProp.nickName = value;
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      websocketProp.initState("ws://${ip}/ws/wx", {
        "message": onMessage,
        "open": () {
          websocketProp.heartCheck();
          websocketProp.sendWebSocketMessageCodeN(1, {
            "nickName": websocketProp.nickName,
            "avatarUrl": websocketProp.avatarUrl
          });
        }
      });
    });
    updateSubscription =
        Get.find<GlobalController>().eventBus.on<UpdateEvent>().listen((event) {
      if (event.code == 1) {
        onMessageCode3(event.dataString, local: true);
      } else {
        onMessageCode3(event.data, local: true);
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _focusNode.dispose();
    findInputC.dispose();
    ble.closeAll();
    updateSubscription.cancel();
  }

  Future getId() async {
    GetStorage box = GetStorage();
    String? id_ = box.read("id");
    print('read id=${id_}');
    if (id_ == null) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      id_ =
          androidInfo.model + DateTime.now().millisecondsSinceEpoch.toString();
      box.write("id", id_).catchError((e) {
        print(e);
      });
    }
    id = id_;
    print('id=${id}');
    return id_;
  }

  /*
  * code 1 用户id; js收到时为用户列表，发送为用户id
  * code 2 设备日志
  * code 3 指令升级
  * code 4 其他指令
  * code 5 升级进度，当前成功的个数
  * code 6 打开或者断开蓝牙连接；空值为断开蓝牙连接
  * code 7 设备过滤参数 信号值、模糊匹配;空值为从微信端获取参数
  * code 8 扫描的设备列表；空值为获取设备列表
  * code 100 重置
  */
  void onMessage(String message) {
    Map<String, dynamic> d = jsonDecode(message);
    if (d['code'] != 8) {
      print(message);
    }

    switch (d['code']) {
      case 3:
        onMessageCode3(d['data']);
        break;
      case 4:
        currentConnectedDeviceProp?.write3OfString(d['data'], success: () {
          websocketProp.sendWebSocketMessageCodeN(4, d['data']);
        });
        break;
      case 6:
        if (d['data'] != null) {
          devices.forEach((device) {
            if (device['id'] == d['data']['deviceId']) {
              toConnectToDevice(device['device']);
            }
          });
        } else {
          onDisConnected();
        }
        break;
      case 7:
        print(d['data']);
        if (d['data'] != null) {
          String findInput = d['data']['findInput'];
          double rssichange = double.parse("${d['data']['rssichange']}");
          setState(() {
            findInputC.text = findInput;
            _rssichange = rssichange;
          });
          ble.findInput = findInput;
          ble.rssichange = rssichange;
          ble.find();
        } else {
          websocketProp.sendWebSocketMessageCodeN(
            7,
            {
              "findInput": findInputC.text,
              "rssichange": _rssichange,
            },
          );
        }
        break;
      case 8:
        List arr = [];
        devices.forEach((element) {
          String adData =
              element['adData'] != null ? jsonEncode(element['adData']) : '';
          arr.add({
            "name": element["name"],
            "RSSI": element["rssi"],
            "deviceId": element["id"],
            "adData": adData,
            "connectable": element["connectable"]
          });
        });
        websocketProp.sendWebSocketMessageCodeN(8, arr);
        break;
      case 100:
        print("100 restart");
        // Assuming you have Flutter navigation logic here
        // For example:
        // Navigator.of(context).pushReplacementNamed('/Login');
        break;
      default:
        break;
    }
  }

  void onMessageCode3(var data, {bool local = false}) {
    RegExp regex = RegExp(r'startDeviceUpdate:[0-9]*');
    if (data is String && regex.hasMatch(data)) {
      updateDevice['sum'] = int.parse(data.split(':')[1]);
      List<String> other = data.split(',');
      updateDevice['updateFileSize'] = int.parse(other[0]);
      updateDevice['fileCrc16'] = other[1];
      int timeInter = 500;
      int speed = (double.parse(other[2]) / (1000 / timeInter) * 1.2).ceil();
      int maxSendSum = 400;
      print("update speed: $speed");
      updateDevice['sendSuccess'] = 0;
      updateDevice['sendLoading'] = 0;
      updateDeviceSendArr = [];
      if (updateDeviceTimer != null) {
        updateDeviceTimer?.cancel();
        updateDeviceTimer = null;
      }
      updateDevice['isUpdate'] = true;
      updateDeviceTimer =
          Timer.periodic(Duration(milliseconds: timeInter), (timer) {
        int othersum = updateDeviceSendArr.length;
        print(
            "${updateDevice['sendLoading']} ${updateDevice['sendSuccess']} $othersum");
        if (updateDevice['sendLoading'] - updateDevice['sendSuccess'] <
                maxSendSum &&
            othersum > 0) {
          int len = speed;
          if (othersum < len) {
            len = updateDeviceSendArr.length;
          }
          for (int j = 0; j < len; j++) {
            updateDevice['sendLoading']++;
            String v = updateDeviceSendArr.removeAt(0);
            if (v.contains("mmx")) {
              currentConnectedDeviceProp?.write3OfString(v, success: () {
                updateDevice['sendSuccess']++;
              }, fail: () {
                onDisConnected();
              });
            } else {
              currentConnectedDeviceProp?.write3OfString(v, success: () {
                if (!local) {
                  websocketProp.sendWebSocketMessageCodeN(
                      5, updateDevice['sendSuccess']);
                }
              }, fail: () {
                onDisConnected();
              });
            }
          }
        }
        bool b = updateDevice['sum'] != 0 &&
            updateDevice['sum'] == updateDevice['sendSuccess'];
        b = b || !isConnected;
        if (b) {
          if (!local) {
            websocketProp.sendWebSocketMessageCodeN(
                5, updateDevice['sendSuccess']);
          }
          updateDeviceTimer?.cancel();
          updateDeviceTimer = null;
          updateDevice['isUpdate'] = false;
          print('update timer close');
        }
        if (!local) {
          websocketProp.sendWebSocketMessageCodeN(
              5, updateDevice['sendSuccess']);
        }
      });
      return;
    }
    if (data is String && data.contains("startIndex")) {
      updateDevice['sendSuccess'] = int.parse(data.split(":")[1]);
      updateDevice['sendLoading'] = updateDevice['sendSuccess'];
      return;
    }
    List<String> arr;
    if (local) {
      arr = data;
    } else {
      arr = List<String>.from(json.decode(data));
    }
    if (arr != null) {
      print("arr.length add ${arr.length}");
      updateDeviceSendArr.addAll(arr);
      if (arr[arr.length - 1] == "reboot" &&
          currentConnectedDeviceProp?.deviceType == 2) {
        updateDeviceSendArr.removeLast();
        updateDeviceSendArr.add("blog enable");
        updateDeviceSendArr.add(
            "vota reboot path=/root/mtd/update size=${updateDevice['updateFileSize']} crc16=${updateDevice['fileCrc16']}");
      }
    }
  }

  void findCall(List l) {
    setState(() {
      devices = l;
      // print("list update");
    });
  }

  Widget getSlider() {
    return Row(
      children: [
        Text("信号强度"),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.grey,
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withOpacity(0.3),
              activeTickMarkColor: Theme.of(context).primaryColor,
              inactiveTickMarkColor: Colors.grey,
            ),
            child: Slider(
              value: _rssichange,
              min: -100,
              max: -10,
              divisions: 18, // 设置刻度数量，可以模拟最小步长
              onChanged: (value) {
                setState(() {
                  _rssichange = value;
                });
                ble.rssichange = value;
                websocketProp.sendWebSocketMessageCodeN(
                  7,
                  {
                    "findInput": findInputC.text,
                    "rssichange": _rssichange.toInt(),
                  },
                );
              },
            ),
          ),
        ),
        Text("${_rssichange.round()}"),
      ],
    );
  }

  Widget getInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("模糊搜索"),
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 20.rpx),
            height: 50,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    isText = false;
                  } else {
                    isText = true;
                  }
                });
                ble.findInput = value;
                websocketProp?.sendWebSocketMessageCodeN(
                  7,
                  {
                    "findInput": findInputC.text,
                    "rssichange": _rssichange,
                  },
                );
              },
              focusNode: _focusNode,
              controller: findInputC,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                border: UnderlineInputBorder(),
                fillColor: Colors.transparent,
                filled: true,
                hintText: '输入关键字',
                contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  color: isText ? null : Colors.transparent,
                  onPressed: () {
                    findInputC.clear();
                    setState(() {
                      isText = false;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  toConnectToDevice(device) {
    if (isShowLoading) {
      return;
    }
    print("isShowLoading = true $device");
    isShowLoading = true;
    showLoading();
    ble.connectToDevice(
      {
        "device": device,
        'success': (ble.ConnectedDeviceProp deviceProp) {
          hideLoading();
          currentConnectedDeviceProp = deviceProp;
          Get.find<GlobalController>().connectedDeviceProp = deviceProp;
          deviceProp.write3OfString("blog enable");
          deviceProp.write3OfString("blog rlmax=128");
          Timer(const Duration(microseconds: 300), () {
            String log = "";
            Function logAdd = (l) {
              log += l;
            };
            deviceProp.receiveLogArr.add(logAdd);
            deviceProp.encodeType = 1;
            deviceProp.deviceType = 1;
            Timer.periodic(const Duration(milliseconds: 300), (timer) {
              if (timer.tick > 20) {
                timer.cancel();
              }
              if (log.contains("GB2312") || log.contains("UTF-8")) {
                timer.cancel();
                if (log.contains('CHARSET:UTF-8')) {
                  deviceProp.encodeType = 2;
                }
                if (log.contains('TARGET:ESPXX')) {
                  deviceProp.deviceType = 2;
                }
              } else {
                deviceProp.read6();
              }
            });
            websocketProp.sendWebSocketMessageCodeN(6, deviceProp.id);
          });
          setState(() {
            isConnected = true;
          });
          (global_connect.currentState as ConnectedState).init();
        },
        'fail': (e) {
          hideLoading();
          print(e);
        },
        "stateChange": (state, device) {
          // print('stateChange Device ${device.name} $state');
          // if (state == BluetoothDeviceState.disconnected) {
          onDisConnected();
          // }
        }
      },
    );
  }

  Widget buildOne(String label, dynamic value) {
    return Row(
      children: [
        Text(label),
        SizedBox(width: 2.0),
        Text(value.toString()),
        SizedBox(width: 16.0),
      ],
    );
  }

  Widget getDeviceList() {
    return Expanded(
      child: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          var item = devices[index];
          List<Widget> arr = [
            Text("名称：${item['name']}"),
            Row(
              children: [
                Text("信号：${item['rssi']}"),
                SizedBox(
                  width: 50.rpx,
                ),
                Text("${item['connectable'] == true ? '可连接' : '不可连接'}"),
                SizedBox(
                  width: 50.rpx,
                ),
                if (item['adData'] != null) Text("sn：${item['adData']?['sn']}"),
              ],
            ),
            Text("蓝牙地址：${item['id']}"),
          ];
          if (item['adData'] != null) {
            arr.add(buildOne("mac:", item['adData']['deviceId']));
            if (item['adData']?.containsKey('net') == true) {
              arr.add(
                Row(
                  children: [
                    buildOne("网络:", item['adData']['net']),
                    buildOne("传感器:", item['adData']['flag']),
                    buildOne("版本:", item['adData']['version']),
                  ],
                ),
              );
            }
            if (item['adData']?.containsKey('qsn')) {
              List<Widget> a = [
                buildOne("在床离床:", item['adData']['isbed']),
                buildOne("广播帧:", item['adData']['qsn']),
              ];
              if (item['adData']['other'] != null) {
                a.add(buildOne("其他:", item['adData']['other']));
              }
              arr.add(Row(
                children: a,
              ));
            }
            arr.add(Row(
              children: [
                buildOne("呼吸:", item['adData']['b']),
                buildOne("心率:", item['adData']['h']),
                buildOne("体动:", item['adData']['t']),
              ],
            ));
          }
          arr.add(const Divider());
          return InkWell(
            key: ValueKey(devices[index]['id']),
            onTap: () {
              toConnectToDevice(devices[index]['device']);
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: arr,
              ),
            ),
          );
        },
      ),
    );
  }

  void showLoading({String text = "连接中"}) {
    // isShowLoading = true;
    LoadingDialog.show(text);
    // showDialog(
    //   context: context,
    //   barrierDismissible: true, //点击遮罩不关闭对话框
    //   builder: (context) {
    //     return AlertDialog(
    //       content: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: <Widget>[
    //           const CircularProgressIndicator(),
    //           Padding(
    //             padding: const EdgeInsets.only(top: 26.0),
    //             child: Text(text),
    //           )
    //         ],
    //       ),
    //     );
    //   },
    // );
  }

  void hideLoading() {
    isShowLoading = false;
    // Navigator.of(context).pop();
    LoadingDialog.hide();
  }

  onDisConnected() {
    Get.find<GlobalController>().eventBus.fire(DisConnectedEvent(
        "${currentConnectedDeviceProp?.id} disconnect on eventBus"));
    if (currentConnectedDeviceProp != null) {
      ble.disconnect(currentConnectedDeviceProp!);
    }
    setState(() {
      isConnected = false;
    });
    websocketProp.sendWebSocketMessageCodeN(6, "");
    Get.find<GlobalController>().connectedDeviceProp = null;
  }

  void _toQrCode() async {
    String? code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerWithOverlay(),
      ),
    );
    // _counter = code ?? '';
    // setState(() {

    // });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onPanDown: (e) {
            _focusNode.unfocus();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Center(child: Text("蓝牙主页")),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _toQrCode,
              tooltip: "add",
              child: const Icon(Icons.add),
            ),
            body: Padding(
              padding: EdgeInsets.all(20),
              child: Column(children: [
                getSlider(),
                getInput(),
                // ElevatedButton(
                //   onPressed: () {
                //     setState(() {
                //       isConnected = true;
                //     });
                //   },
                //   child: Text("ttttt"),
                // ),
                getDeviceList()
              ]),
            ),
          ),
        ),
        Offstage(
          offstage: isConnected == false,
          child: Connected(
            key: global_connect,
            onDisConnected: onDisConnected,
            websocketProp: websocketProp,
          ),
        ),
      ],
    );
  }
}
