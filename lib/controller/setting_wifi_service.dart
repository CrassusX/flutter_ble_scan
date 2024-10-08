// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_ble_scan/common/store_manger.dart';
import 'package:flutter_ble_scan/common/util.dart';
import 'package:flutter_ble_scan/dio/dio.dart';
import 'package:flutter_ble_scan/event/device_info.dart';
import 'package:flutter_ble_scan/lib/Websocket.dart';
import 'package:flutter_ble_scan/page/wifi/seat_wifi_step2.dart';
import 'package:get/get.dart';
import 'package:flutter_ble_scan/lib/ble.dart' as ble;

const String ip = "wxconfig.he-info.cn";
const String bleWifiInfo = 'bleWifiInfo';

class GetSettingWifiService extends GetxService {
  // 单利初始化
  static GetSettingWifiService get to => Get.find();

  final RxList mBleList = [].obs;

  final WebsocketProp mWebsocket = WebsocketProp();

  WifiInfoParams mWifiParams = WifiInfoParams();

  DeviceType deviceType = DeviceType.unknown;

  ble.ConnectedDeviceProp? currentConnectedDeviceProp;

  @override
  void onInit() async {
    await StoreManger.getInstance().init();
    _readWifiInfo();
    getId().then((value) => mWebsocket.nickName = value ?? '');

    mWebsocket.initState("ws://$ip/ws/wx", {
      "message": _handleMessage,
      "open": () {
        mWebsocket.heartCheck();
        mWebsocket.sendWebSocketMessageCodeN(1, {
          "nickName": mWebsocket.nickName,
          "avatarUrl": mWebsocket.avatarUrl
        });
      }
    });

    everAll([deviceInfoRx, mBleList], (callback) {
      if (deviceInfoRx.value?.data?.macAddress != null &&
          mBleList.isNotEmpty &&
          isConnected == false) {
        // 查找的mac 地址连接
        var macAddrss = deviceInfoRx.value?.data?.getMacAddrss;
        var device = mBleList.value
            .firstWhereOrNull((element) => element?['id'] == macAddrss);
        if (device != null) {
          _connectBle(device['device']);
        }
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    onDisconnectBle();
    super.onClose();
  }

  Future<void> onCloseBleConnected() async {
    await ble.closeAll();
  }

  _readWifiInfo() {
    String? decodeStr = StoreManger.getInstance().getString(bleWifiInfo);
    mWifiParams = WifiInfoParams.decode(decodeStr);
  }

  onSaveWifiInfo(bool isRemember, Map wifiInfo, String password) {
    mWifiParams = WifiInfoParams(
      isRemember: isRemember,
      wifi: wifiInfo,
      password: password,
    );
    if (isRemember == true) {
      final encodeStr = WifiInfoParams.encode(mWifiParams);
      StoreManger.getInstance().setString(bleWifiInfo, encodeStr);
    }
  }

  final deviceInfoRx = Rx<DeviceInfo?>(null);

  // 第一步，去扫描页面
  void onGoScanWifi() async {
    // 先断开现有的蓝牙连接
    await onCloseBleConnected();
    _startScanBle();
    var code = await Get.toNamed('/qrScan');
    if (code != null) {
      var res = isSuccessfulScan(code);
      deviceType = res.$2;
      if (res.$1) {
        LoadingDialog.show("连接蓝牙中...");
        var resp = await ApiService.getDeviceInfo(code!);
        if (resp != null) {
          deviceInfoRx.value = DeviceInfo.fromJson(resp);
        }
      } else {
        showToast("扫码失败，不符合格式的设备码!");
      }
    }
  }

  // 开始蓝牙扫描
  _startScanBle() {
    ble.findInput = 'AITH-V2';
    ble.start((List bleList) {
      if (bleList.isNotEmpty) {
        mBleList.value = bleList;
      }
    });
  }

  bool isShowLoading = false;
  bool isConnected = false;
  // 连接蓝牙设备
  _connectBle(device) {
    if (isShowLoading) {
      return;
    }

    isShowLoading = true;
    ble.connectToDevice(
      {
        "device": device,
        'success': (ble.ConnectedDeviceProp deviceProp) {
          hideLoading();
          // 当前连接的设备
          currentConnectedDeviceProp = deviceProp;
          deviceProp.write3OfString("blog enable");
          deviceProp.write3OfString("blog rlmax=128");
          Timer(const Duration(microseconds: 300), () {
            String log = "";
            logAdd(l) {
              log += l;
            }

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
            mWebsocket.sendWebSocketMessageCodeN(6, deviceProp.id);
          });

          isConnected = true;
          Get.to(() => SeatWifiStep2(
                deviceId: deviceInfoRx.value?.data?.deviceNo,
              ));
          ble.stopScan();
        },
        'fail': (e) {
          hideLoading();
        },
        "stateChange": (state, device) {
          // print('stateChange Device ${device.name} $state');
          // if (state == BluetoothDeviceState.disconnected) {
          onDisconnectBle();
          // }
        }
      },
    );
  }

  // 断开设备连接
  onDisconnectBle() {
    if (currentConnectedDeviceProp != null) {
      ble.disconnect(currentConnectedDeviceProp!);
    }

    isConnected = false;
    mWebsocket.sendWebSocketMessageCodeN(6, "");
    currentConnectedDeviceProp = null;
  }

  // socket消息处理
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
  void _handleMessage(String message) {
    Map<String, dynamic> d = jsonDecode(message);
    switch (d['code']) {
      case 3:
        _onMessageCode3(d['data']);
        break;
      case 4:
        currentConnectedDeviceProp?.write3OfString(d['data'], success: () {
          mWebsocket.sendWebSocketMessageCodeN(4, d['data']);
        });
        break;
      case 6:
        if (d['data'] != null) {
          for (var device in mBleList.value) {
            if (device['id'] == d['data']['deviceId']) {
              _connectBle(device['device']);
            }
          }
        } else {
          onDisconnectBle();
        }
        break;
      case 7:
      // print(d['data']);
      // if (d['data'] != null) {
      //   String findInput = d['data']['findInput'];
      //   double rssichange = double.parse("${d['data']['rssichange']}");
      //   // setState(() {
      //   //   findInputC.text = findInput;
      //   //   _rssichange = rssichange;
      //   // });
      //   ble.findInput = findInput;
      //   ble.rssichange = rssichange;
      //   ble.find();
      // } else {
      //   mWebsocket.sendWebSocketMessageCodeN(
      //     7,
      //     {
      //       "findInput": findInputC.text,
      //       "rssichange": _rssichange,
      //     },
      //   );
      // }
      // break;
      case 8:
        // 写入WiFi密码信息
        List arr = [];
        for (var element in mBleList.value) {
          String adData =
              element['adData'] != null ? jsonEncode(element['adData']) : '';
          arr.add({
            "name": element["name"],
            "RSSI": element["rssi"],
            "deviceId": element["id"],
            "adData": adData,
            "connectable": element["connectable"]
          });
        }
        mWebsocket.sendWebSocketMessageCodeN(8, arr);
        break;
      case 100:
        // Assuming you have Flutter navigation logic here
        // For example:
        // Navigator.of(context).pushReplacementNamed('/Login');
        break;
      default:
        break;
    }
  }

  // 获取WiFi列表
  Future<List> getWifiList() {
    LoadingDialog.show("扫描WIFI列表中");
    Completer<List> completer = Completer<List>();
    String log = "";
    logAdd(l) {
      log += l;
    }

    currentConnectedDeviceProp?.receiveLogArr.add(logAdd);
    currentConnectedDeviceProp?.write3OfString("wscan scan", success: () {
      Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (timer.tick > 6) {
          timer.cancel();
          currentConnectedDeviceProp?.receiveLogArr.remove(logAdd);
        }
        Iterable<RegExpMatch> a =
            RegExp(r'ITEM:SSID=([^\t]*)\s*RSSI=(\S*)\s*(,\s*auth\s*=\s*(\S*))?')
                .allMatches(log);
        if (a.isEmpty == false) {
          List arr = [];
          for (RegExpMatch one in a) {
            arr.add({"name": one[1], "num": one[2], "auth": one[4]});
          }

          currentConnectedDeviceProp?.receiveLogArr.remove(logAdd);
          timer.cancel();
          LoadingDialog.hide();
          completer.complete(arr);
        }
      });
    }, fail: () {
      LoadingDialog.hide();
      currentConnectedDeviceProp?.receiveLogArr.remove(logAdd);
      completer.complete([]);
    });
    return completer.future;
  }

  // 点击WiFi连接
  int maxRepeat = 10;
  onConnectWifi(Function(bool) callback, Function(double) callbackProgress) {
    Map item = mWifiParams.wifi;
    String v = mWifiParams.password;
    String log = "";
    logFun(l) {
      log += l;
    }

    callbackProgress.call(10);

    String d =
        "${'${'vtouch save update .wifi.sta.ssid="' + item['name']}" .wifi.sta.pwd="' + v}\"";
    if (item['auth'] != null) {
      d += " -a -i .wifi.sta.auth=" + item['auth'];
    }
    currentConnectedDeviceProp?.receiveLogArr.add(logFun);
    currentConnectedDeviceProp?.write3OfString(d, success: () {
      // 等待一段时间
      callbackProgress.call(20);
      Timer.periodic(const Duration(seconds: 2), (timer) {
        currentConnectedDeviceProp?.write3OfString("wl show name=vstrace");
        RegExpMatch? m = RegExp(r"status=(\S*)\s*name=vstrace").firstMatch(log);
        if (timer.tick > maxRepeat) {
          timer.cancel();
          currentConnectedDeviceProp?.receiveLogArr.remove(logFun);
          callback.call(false);
        }
        if (m != null && m[1] != null && m[1] == 'connect') {
          timer.cancel();
          currentConnectedDeviceProp?.receiveLogArr.remove(logFun);
          callback.call(true);
          // 断开socket链接
          onDisconnectBle();
          return;
        }
        callbackProgress.call(20 + (timer.tick / maxRepeat) * 80);
        log = "";
      });
    });
  }

  // 其他方法
  Future<String?> getId() async {
    String? id_ = StoreManger.getInstance().get('id');
    if (id_ == null) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        id_ = androidInfo.model +
            DateTime.now().millisecondsSinceEpoch.toString();
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        id_ = iosInfo.model +
            DateTime.now().millisecondsSinceEpoch.toString();
      }
      print(" id_ $id_");
      StoreManger.getInstance().setString('id', id_ ?? 'modelX');
    }
    return id_;
  }

  void hideLoading() {
    isShowLoading = false;
    LoadingDialog.hide();
  }

  Timer? updateDeviceTimer;

  _closeUpdateTimer() {
    if (updateDeviceTimer != null) {
      updateDeviceTimer?.cancel();
      updateDeviceTimer = null;
    }
  }

  // 解码信号为3的数据
  void _onMessageCode3(var data, {bool local = false}) {
    Map updateDevice = {};
    List<String> updateDeviceSendArr = [];
    RegExp regex = RegExp(r'startDeviceUpdate:[0-9]*');
    if (data is String && regex.hasMatch(data)) {
      updateDevice['sum'] = int.parse(data.split(':')[1]);
      List<String> other = data.split(',');
      updateDevice['updateFileSize'] = int.parse(other[0]);
      updateDevice['fileCrc16'] = other[1];
      int timeInter = 500;
      int speed = (double.parse(other[2]) / (1000 / timeInter) * 1.2).ceil();
      int maxSendSum = 400;
      updateDevice['sendSuccess'] = 0;
      updateDevice['sendLoading'] = 0;
      updateDeviceSendArr = [];
      _closeUpdateTimer();
      updateDevice['isUpdate'] = true;
      updateDeviceTimer =
          Timer.periodic(Duration(milliseconds: timeInter), (timer) {
        int othersum = updateDeviceSendArr.length;
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
                onDisconnectBle();
              });
            } else {
              currentConnectedDeviceProp?.write3OfString(v, success: () {
                if (!local) {
                  mWebsocket.sendWebSocketMessageCodeN(
                      5, updateDevice['sendSuccess']);
                }
              }, fail: () {
                onDisconnectBle();
              });
            }
          }
        }
        bool b = updateDevice['sum'] != 0 &&
            updateDevice['sum'] == updateDevice['sendSuccess'];
        b = b || !isConnected;
        if (b) {
          if (!local) {
            mWebsocket.sendWebSocketMessageCodeN(
                5, updateDevice['sendSuccess']);
          }
          _closeUpdateTimer();
          updateDevice['isUpdate'] = false;
        }
        if (!local) {
          mWebsocket.sendWebSocketMessageCodeN(5, updateDevice['sendSuccess']);
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
