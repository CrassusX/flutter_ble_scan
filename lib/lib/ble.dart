import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

FlutterBlue flutterBlue = FlutterBlue.instance;

String findInput = "";
double rssichange = -70;
Function? findCall;

int mcuMax = 500;

String myuuid = "00000001-0000-1000-8000-00805F9B34FB";
// String notifyuuid = "00000002-0000-1000-8000-00805F9B34FB";

int closeTime = 20000;

Map devices = {};

Map<String, ConnectedDeviceProp> connectList = {};

start(Function fun) {
  findCall = fun;
  requestBluetoothPermission();
}

void requestBluetoothPermission() async {
  // 请求蓝牙权限
  PermissionStatus status1 = await Permission.bluetooth.status;
  PermissionStatus status2 = await Permission.bluetoothScan.status;
  PermissionStatus status3 = await Permission.bluetoothConnect.status;

  if (status1.isGranted && status2.isGranted && status3.isGranted) {
    startBluetoothScanning();
  } else {
    PermissionStatus? result1;
    if (status1.isGranted == false) {
      result1 = await Permission.bluetooth.request();
    }
    PermissionStatus? result2;
    if (status2.isGranted == false) {
      result2 = await Permission.bluetoothScan.request();
    }
    PermissionStatus? result3;
    if (status3.isGranted == false) {
      result3 = await Permission.bluetoothConnect.request();
    }

    if ((result1 == null || result1.isGranted) &&
        (result2 == null || result2.isGranted) &&
        (result3 == null || result3.isGranted)) {
      // 在这里可以开始使用蓝牙功能
      startBluetoothScanning();
    } else {
      // 处理权限被拒绝的情况
    }
  }
}

void find() {
  int len = devices.length;
  String reg = findInput.toLowerCase().replaceAll(RegExp("[:：]"), "");
  List list = devices.values.toList();
  for (int i = 0; i < len; i++) {
    Map d = list[i];
    bool flag = d['rssi'] >= rssichange;
    if (flag) {
      bool a = d['name'].toString().toLowerCase().contains(reg);
      a = a ||
          d['id']
              .toString()
              .toLowerCase()
              .replaceAll(RegExp("[:：]"), "")
              .contains(reg);
      flag = flag && a;
    }
    if (flag) {
      flag = flag &&
          DateTime.now().millisecondsSinceEpoch - d['updateTime'] < closeTime;
    }
    if (!flag) {
      d['isClose'] = true;
    } else {
      d['isClose'] = false;
    }
  }
  var result = list.where((item) => item['isClose'] == false).toList();
  result.sort((a, b) {
    return b['rssi'] - a['rssi'];
  });
  findCall?.call(result);
}

String ab2str(List<int> buffer) {
  return buffer.map((x) => x.toRadixString(16).padLeft(2, '0')).join('');
}

void advertisDataFormatter(var a, item) {
  Map<String, dynamic> obj = {};
  try {
    if (a[2] == 1) {
      obj['sn'] = a[3];
      obj['deviceId'] = ab2str(a.sublist(4, 10).toList()).toUpperCase();
      obj['b'] = a[10];
      obj['h'] = a[11];
      obj['t'] = a[12];
      item['adData'] = obj;
    } else if (a[2] == 2) {
      obj['sn'] = a[3];
      obj['deviceId'] = ab2str(a.sublist(4, 10).toList()).toUpperCase();
      obj['b'] = a[10];
      obj['h'] = a[11];
      obj['t'] = a[12];
      obj['net'] = (a[13] & 1) == 1 ? '在线' : '离线';
      obj['flag'] = (a[13] & 2) == 2 ? '异常' : '正常';
      ByteData byteData = ByteData.sublistView(
          Uint8List.fromList(a.sublist(14, 18).reversed.toList()));
      obj['version'] = byteData.getUint32(0);
      item['adData'] = obj;
    } else if (a[2] == 3) {
      List<String> otherstr = [];
      obj['sn'] = a[3];
      obj['deviceId'] = ab2str(a.sublist(4, 10).toList()).toUpperCase();
      obj['b'] = a[10];
      obj['h'] = a[11];
      obj['t'] = a[12];
      obj['net'] = (a[13] & 1) == 1 ? '在线' : '离线';
      obj['flag'] = (a[13] & 2) == 2 ? '异常' : '正常';

      if ((a[13] & 4) == 4) {
        otherstr.add('呼吸暂停');
      }

      if ((a[13] & 8) == 8 && (a[13] & 1) == 1) {
        obj['isbed'] = '在床';
      } else {
        obj['isbed'] = '离床';
      }

      if ((a[13] & 16) == 16) {
        otherstr.add('授权过期');
      }

      if ((a[13] & 64) == 64) {
        otherstr.add('设备休眠');
      }

      obj['other'] = otherstr.join('、');

      ByteData byteData = ByteData.sublistView(
          Uint8List.fromList(a.sublist(14, 18).reversed.toList()));
      obj['version'] = byteData.getUint32(0);

      ByteData qsnData =
          ByteData.sublistView(Uint8List.fromList(a.sublist(17, 19)));
      obj['qsn'] = qsnData.getUint16(0) * 256 + obj['sn'];

      item['adData'] = obj;
    } else if (a.length > 17) {
      obj['sn'] = a[3];
      obj['deviceId'] = ab2str(a.sublist(4, 10).toList()).toUpperCase();
      obj['b'] = a[10];
      obj['h'] = a[11];
      obj['t'] = a[12];
      obj['net'] = (a[13] & 1) == 1 ? '在线' : '离线';
      obj['flag'] = (a[13] & 2) == 2 ? '异常' : '正常';

      ByteData byteData = ByteData.sublistView(
          Uint8List.fromList(a.sublist(14, 18).reversed.toList()));
      obj['version'] = byteData.getUint32(0);

      item['adData'] = obj;
    }
  } catch (e) {}
}

StreamSubscription? _subscription;

void startBluetoothScanning() {
  // 开始扫描附近的蓝牙设备
  flutterBlue.startScan(
    timeout: const Duration(days: 3),
    allowDuplicates: true,
    scanMode: ScanMode.lowLatency,
  );

  _subscription = flutterBlue.scanResults.listen((List<ScanResult> results) {
    // print(results.length);
    for (ScanResult result in results) {
      // if (result.device.id.toString().contains("A3:76")) {
      //   print("$result");
      // }
      Map d = {
        "updateTime": DateTime.now().millisecondsSinceEpoch,
        "name": result.device.name,
        "id": result.device.id.toString(),
        "rssi": result.rssi,
        "device": result.device,
        "connectable": result.advertisementData.connectable
      };
      Map<int, List<int>> m_d = result.advertisementData.manufacturerData;
      m_d.keys.toList().forEach((v) {
        if (v == 65517 && m_d[65517]?.length != 0) {
          List<int> a = [0, 0, ...?m_d[65517]];
          advertisDataFormatter(a, d);
        }
      });
      devices[result.device.id] = d;
      // print('Device found: ${result.device.name}, ${result.device.id}');

      Future.delayed(const Duration(microseconds: 300), () {
        find();
      });
    }
  });
}

getOneConnectedDeviceProp(id) {
  return connectList[id];
}

void setOther(device, connectedDeviceProp, fun) async {
  try {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == myuuid) {
        // print("serviece $service");
        for (BluetoothCharacteristic element in service.characteristics) {
          if (element.properties.notify) {
            await element.setNotifyValue(true);
            connectedDeviceProp.createLisetenReceive(element);
            continue;
          }
          if (element.properties.write) {
            connectedDeviceProp?.writeCharacteristic = element;
          }
        }
      }
    }
    connectList[connectedDeviceProp.id] = connectedDeviceProp;
    connectedDeviceProp.createListenState();
    connectedDeviceProp.heartbeat();
    fun['success']?.call(connectedDeviceProp);
  } catch (e) {
    if (connectedDeviceProp != null) {
      disconnect(connectedDeviceProp!);
    }
    fun['fail']?.call(e);
  }
}

// 连接设备
void connectToDevice(Map fun) async {
  BluetoothDevice device = fun['device'];
  ConnectedDeviceProp? connectedDeviceProp =
      getOneConnectedDeviceProp(device.id.toString());
  if (connectedDeviceProp != null) {
    disconnect(connectedDeviceProp);
    Future.delayed(const Duration(seconds: 1), () {
      connectToDevice(fun);
    });
    return;
  }
  try {
    Timer connectingTimeout = Timer(const Duration(seconds: 9), () {
      fun['fail']?.call("蓝牙连接超时");
    });
    await device.connect(timeout: const Duration(seconds: 8));
    connectingTimeout.cancel();
    connectedDeviceProp = ConnectedDeviceProp(connectDevice: device, fun: fun);
    await device.requestMtu(mcuMax);
    Timer(const Duration(milliseconds: 1000), () {
      setOther(device, connectedDeviceProp, fun);
    });
  } catch (e) {
    if (connectedDeviceProp != null) {
      disconnect(connectedDeviceProp);
    }
    fun['fail']?.call(e);
  }
}

void disconnect(ConnectedDeviceProp connectedDeviceProp) {
  connectedDeviceProp.closeHeartBeat();
  connectList.remove(connectedDeviceProp.id);
  connectedDeviceProp.closeConnectedDeviceProp();
}

void closeAll() {
  findCall = null;
  _subscription?.cancel();
  flutterBlue.stopScan();
  // 创建connectList的副本
  List<ConnectedDeviceProp> connectListCopy = List.from(connectList.values);
  if (connectListCopy.isNotEmpty) {
    for (ConnectedDeviceProp prop in connectListCopy) {
      disconnect(prop);
    }
    connectList = {};
  }
}

class ConnectedDeviceProp {
  Timer? heartbeatTimer;
  int _seq = 0;
  dynamic connectDevice;
  BluetoothCharacteristic? writeCharacteristic;
  StreamSubscription<BluetoothDeviceState>? listenState;
  StreamSubscription<List<int>>? lisetenReceive;
  Map fun;
  List receiveMethods = [];
  List logList = [];
  Function? logChange;
  ConnectedDeviceProp({required this.connectDevice, required this.fun});
  List receiveLogArr = [];
  int deviceType = 2;
  int encodeType = 2;
  List sendArr = [];
  double sendExecAverage = 100;
  bool isClose = false;

  String get id {
    return connectDevice.id.toString();
  }

  int sum_ab(dv) {
    ByteData sum = ByteData(1);
    for (int i = 0; i < dv.buffer.lengthInBytes; i++) {
      sum.setUint8(0, dv.getUint8(i) + sum.getUint8(0));
    }
    return sum.getUint8(0);
  }

  void heartbeat() {
    closeHeartBeat();
    heartbeatTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      ByteData dv = ByteData(4);
      dv.setUint8(0, 4);
      dv.setUint8(2, seq);
      dv.setUint8(3, 5);
      dv.setUint8(1, sum_ab(dv));
      writeBle(dv);
    });
  }

  closeHeartBeat() {
    if (heartbeatTimer != null) {
      heartbeatTimer?.cancel();
      heartbeatTimer = null;
    }
  }

  ByteData str2ab_oneByte(String str, {int startLength = 0}) {
    Uint8List utf8str = utf8.encode(str);
    int len = utf8str.length + startLength;
    ByteData buf2 = ByteData.sublistView(utf8str);
    ByteData buf = ByteData(len);
    for (int i = startLength; i < len; i++) {
      buf.setUint8(i, buf2.getUint8(i - startLength));
    }
    return buf;
  }

  void write3OfString(sendDate, {Function? success, Function? fail}) {
    ByteData dv = str2ab_oneByte(sendDate, startLength: 4);
    int len = dv.buffer.lengthInBytes;
    dv.setUint8(0, len);
    dv.setUint8(2, seq);
    dv.setUint8(3, 8 * 16 + 3);
    dv.setUint8(1, sum_ab(dv));
    writeBle(dv, success: success, fail: fail);
  }

  void writeBle(ByteData d, {Function? success, Function? fail}) {
    Uint8List d_ = Uint8List.view(d.buffer);
    if (sendArr.isEmpty) {
      write(d_, success, fail);
    }
    sendArr.insert(0, {"d": d_, "success": success, "fail": fail});
  }

  void write(Uint8List d, Function? success, Function? fail, {int exec = 100}) {
    if (writeCharacteristic != null) {
      // try {
      //   if (d[3] == 8 * 16 + 3) {
      //     print(
      //         "blewrite s = $sendExecAverage d = ${utf8.decode(d.sublist(4))}");
      //   } else {
      //     print("ble last write d = ${d[3]}");
      //   }
      // } catch (e) {
      //   print("write logprint error $e");
      // }
      writeCharacteristic?.write(d, withoutResponse: true).then((e) {
        // print("write success $e");
        if (exec > 95) {
          sendExecAverage = sendExecAverage + 0.5;
        }
        if (sendExecAverage > 99) {
          sendExecAverage = 99;
        }
        if (sendArr.isNotEmpty) {
          sendArr.removeLast();
          Map last = sendArr.last;
          write(last["d"], last["success"], last["fail"]);
        }
        success?.call();
      }).catchError((e) {
        // print("exec = $exec , $e");
        if (exec < 0) {
          fail?.call();
        }
        if (exec > -1 && isClose == false) {
          int time = ((100.0 - sendExecAverage) * 5.0).toInt();
          if (exec < 80) {
            time = (100 - exec) * 5;
            sendExecAverage = exec * 1.0;
          } else {
            sendExecAverage = sendExecAverage - (100 - exec) * 0.1;
          }
          Timer(Duration(milliseconds: time), () {
            write(d, success, fail, exec: exec - 1);
          });
        }
      });
    }
  }

  void read6() {
    ByteData dv = ByteData(4);
    dv.setUint8(0, 4);
    dv.setUint8(2, seq);
    dv.setUint8(3, 6);
    dv.setUint8(1, sum_ab(dv));
    writeBle(dv);
  }

  addLog(String log) {
    if (logList.length > 500) {
      logList.removeRange(0, 50);
    }
    DateTime date = DateTime.now();
    String h = date.hour > 10 ? "${date.hour}" : "0${date.hour}";
    String m = date.minute > 10 ? "${date.minute}" : "0${date.minute}";
    String s = date.second > 10 ? "${date.second}" : "0${date.second}";
    logList.add({"time": "$h:$m:$s", "value": log});
    if (logChange != null) {
      logChange?.call(logList, log);
    }
  }

  createListenState() {
    listenState = connectDevice.state.listen((state) {
      if (state == BluetoothDeviceState.disconnected) {
        fun['stateChange']?.call(state, connectDevice);
        isClose = true;
        disconnect(this);
      }
    });
  }

  createLisetenReceive(BluetoothCharacteristic element) {
    lisetenReceive = element.value.listen((List<int> value) {
      if (value.isEmpty) {
        return;
      }
      bool isOk = sumCheck(value);
      if (isOk) {
        // print("NotifyValue $value");
        for (var m in receiveMethods) {
          m?.call();
        }
        yewuSwitch(value[3], value.sublist(4));
      }
    });
  }

  closeConnectedDeviceProp() {
    isClose = true;
    if (listenState != null) {
      listenState?.cancel();
    }
    if (lisetenReceive != null) {
      lisetenReceive?.cancel();
    }
    connectDevice?.disconnect();
  }

  int get seq {
    int r = _seq % 256;
    _seq++;
    return r;
  }

  bool sumCheck(List<int> ab) {
    ByteData dv = ByteData.sublistView(Uint8List.fromList(ab));

    if (dv.getUint8(0) != ab.length) {
      return false;
    } //和校验失败

    if (sumList(ab) != dv.getUint8(1)) {
      return false;
    }

    return true;
  }

  int sumList(List<int> ab) {
    ByteData dv = ByteData.sublistView(Uint8List.fromList(ab));
    ByteData sum = ByteData.sublistView(Uint8List(1));

    sum.setUint8(0, dv.getUint8(0));

    for (int i = 2; i < ab.length; i++) {
      sum.setUint8(0, dv.getUint8(i) + sum.getUint8(0));
    }

    return sum.getUint8(0);
  }

  List<int> endLogValue = [];
  Timer? endLogTimer;

  void yewuSwitch(int yewu, List<int> abData) {
    switch (yewu) {
      case 7:
        String error = ab2StrByType(abData);
        break;

      case 131:
        List<int>? logData;
        if (abData.last != 10) {
          int index = abData.lastIndexOf(10);
          if (index == -1) {
            index = abData.length;
            endLogValue = [...endLogValue, ...abData.sublist(0, index)];
          } else {
            logData = [...endLogValue, ...abData.sublist(0, index)];
            endLogValue = abData.sublist(index);
          }
          // if (index == -1) {
          //   index = abData.length;
          // }
          // if(endLogValue.isNotEmpty) {
          //   logData = [...endLogValue, ...abData.sublist(0, index)];
          //   endLogValue = [];
          // } else {
          //   logData = [...abData.sublist(0, index)];
          // }
          // if(index != abData.length) {
          //   endLogValue = abData.sublist(index);
          // }
        } else {
          if (endLogValue.isNotEmpty) {
            logData = [...endLogValue, ...abData];
          } else {
            logData = abData;
          }

          endLogValue = [];
        }

        if (endLogTimer != null) {
          endLogTimer?.cancel();
          endLogTimer = null;
        }

        if (endLogValue.isNotEmpty) {
          endLogTimer = Timer(const Duration(milliseconds: 400), () {
            String log = ab2StrByType(endLogValue);
            endLogValue = [];
            addLog(log);
            try {
              for (var m in receiveLogArr) {
                m(log);
              }
            } catch (e) {}
          });
        }

        if (logData != null && logData.isNotEmpty) {
          if (logData.length != 1 || logData[0] != 13) {
            String log = ab2StrByType(logData);
            addLog(log);
            try {
              for (var m in receiveLogArr) {
                m(log);
              }
            } catch (e) {}
          }
        }
        // 处理逻辑
        break;

      case 132:
        ByteData dv = ByteData.sublistView(Uint8List.fromList(abData));

        for (int i = 0; i < abData.length;) {
          int len = dv.getUint8(i);
          yewuSwitch(dv.getUint8(i + 1), abData.sublist(i + 2, i + 1 + len));
          i = i + 1 + len;
        }

        break;

      default:
        break;
    }
  }

  String ab2StrByType(List<int> abData) {
    // Implement your logic for converting abData to String
    String str = "";
    if (abData.isNotEmpty) {
      try {
        str = utf8.decode(abData);
      } catch (e) {
        str = "解析错误";
      }
    }
    return str;
  }
}
