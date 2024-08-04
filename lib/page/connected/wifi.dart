import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../common/util.dart';
import '../../controller/GlobalController.dart';
import '../../event/DisConnectedEvent.dart';
import '../../lib/ble.dart';

class Wifi extends StatefulWidget {
  const Wifi({super.key});

  @override
  State<Wifi> createState() => _WifiState();
}

class _WifiState extends State<Wifi> {
  List wifiList = [];
  late ConnectedDeviceProp connectedDeviceProp;
  late StreamSubscription disSubscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // for (var i = 0; i < 50; i++) {
    //   wifiList.add({
    //     "name": "2222",
    //     "num": "-52",
    //     "auth": "2",
    //   });
    // }
    ConnectedDeviceProp? connectedDeviceProp2 = Get.find<GlobalController>().connectedDeviceProp;
    if(connectedDeviceProp2 == null) {
      showToast("蓝牙连接断开");
      Get.back();
    } else {
      connectedDeviceProp = connectedDeviceProp2;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        getWifiList();
      });
    }
    disSubscription = Get.find<GlobalController>().eventBus.on<DisConnectedEvent>().listen((event) {
      print(event.message);
      Get.back();
    });
  }

  @override
  dispose() {
    super.dispose();
    disSubscription.cancel();
  }

  getWifiList() {
    LoadingDialog.show("扫描WIFI列表中");
    String log = "";
    Function logAdd = (l) {
      log += l;
    };
    connectedDeviceProp.receiveLogArr.add(logAdd);
    connectedDeviceProp.write3OfString("wscan scan", success: () {
      Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (timer.tick > 6) {
          timer.cancel();
          connectedDeviceProp.receiveLogArr.remove(logAdd);
          LoadingDialog.hide();
          // getWifiList();
        }
        Iterable<RegExpMatch> a = RegExp(
                r'ITEM:SSID=([^\t]*)\s*RSSI=(\S*)\s*(,\s*auth\s*=\s*(\S*))?')
            .allMatches(log);
        if (a.isEmpty == false) {
          List arr = [];
          for (RegExpMatch one in a) {
            arr.add({"name": one[1], "num": one[2], "auth": one[4]});
          }
          LoadingDialog.hide();
          setState(() {
            wifiList = arr;
          });
          connectedDeviceProp.receiveLogArr.remove(logAdd);
          timer.cancel();
        }
      });
    }, fail: () {
      connectedDeviceProp.receiveLogArr.remove(logAdd);
      LoadingDialog.hide();
    });
  }

  confirm(v, Map item) {
    LoadingDialog.show("WIFI连接中");
    String log = "";
    Function fun = (l) {
      log += l;
    };
    String d = 'vtouch save update .wifi.sta.ssid=\"' +
        item['name'] +
        '\" .wifi.sta.pwd=\"' +
        v +
        "\"";
    if (item['auth'] != null) {
      d += " -a -i .wifi.sta.auth=" + item['auth'];
    }
    connectedDeviceProp.receiveLogArr.add(fun);
    print(d);
    connectedDeviceProp.write3OfString(d, success: () {
      Timer.periodic(Duration(milliseconds: 1500), (timer) {
        connectedDeviceProp.write3OfString("wl show name=vstrace");
        if (timer.tick > 7) {
          LoadingDialog.hide();
          timer.cancel();
          connectedDeviceProp.receiveLogArr.remove(fun);
          showToast("连接失败");
        }
        RegExpMatch? m = RegExp(r"status=(\S*)\s*name=vstrace").firstMatch(log);
        if (m != null && m[1] != null && m[1] == 'connect') {
          LoadingDialog.hide();
          timer.cancel();
          connectedDeviceProp.receiveLogArr.remove(fun);
          showToast("连接成功");
          Get.back();
        }
        log = "";
      });
    });
  }

  inputPwd(Map d) {
    showInputCustomDialog(context, name: d['name']).then((value) {
      if(value == 'cancel') {
        return;
      }
      confirm(value, d);
    }).catchError((e) {
      print("$e");
    });
  }

  wifiListWidget() {
    return ListView.builder(
      itemCount: wifiList.length,
      itemBuilder: (BuildContext context, int index) {
        var d = wifiList[index];
        return InkWell(
          onTap: () {
            inputPwd(d);
          },
          child: Container(
            margin: EdgeInsets.only(left: 20, right: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      "images/wifi3.svg",
                      width: 30,
                      height: 30,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text("${d['num']}"),
                    SizedBox(
                      width: 20,
                    ),
                    Text("${d['name']}"),
                  ],
                ),
                Image.asset("images/right.png")
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text("WIFI配网"),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(left: 30, right: 30, bottom: 10, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "WLAN",
                    style: TextStyle(fontSize: 20),
                  ),
                  InkWell(
                    onTap: () {
                      getWifiList();
                    },
                    child: Icon(Icons.refresh, size: 30,)
                  )
                ],
              ),
            ),
            Expanded(child: wifiListWidget()),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }
}
