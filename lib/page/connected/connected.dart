import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/FitTool.dart';
import '../../controller/GlobalController.dart';
import 'package:flutter_ble_scan/lib/ble.dart' as ble;
import 'package:flutter_ble_scan/lib/Websocket.dart';
import '../../page/connected/update.dart';

class Connected extends StatefulWidget {
 final  Function onDisConnected;
 final  WebsocketProp websocketProp;
  const Connected({
    super.key,
    required this.onDisConnected,
    required this.websocketProp,
  });

  @override
  State<Connected> createState() => ConnectedState();
}

Widget getButton(context, {String name = "", onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(
        Theme.of(context).primaryColor,
      ),
      foregroundColor: MaterialStateProperty.all(
        Colors.white,
      ),
    ),
    child: Text(name),
  );
}

class ConnectedState extends State<Connected> {
  late ble.ConnectedDeviceProp connectedDeviceProp;
  String id = "";
  String name = "";
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List logList = [];
  int currentType = 1;
  Map widgetmap = {};

  void init() {
    connectedDeviceProp = Get.find<GlobalController>().connectedDeviceProp!;
    setState(() {
      name = connectedDeviceProp.connectDevice.name;
      id = connectedDeviceProp.id;
    });
    _textController.text = "free";
    connectedDeviceProp.logChange = (List list, String log) {
      widget.websocketProp.sendWebSocketMessageCodeN(2, getDate() + log);
      setState(() {
        logList = list;
      });
      if (_scrollController.position.maxScrollExtent -
              _scrollController.position.pixels <
          200) {
        //  _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 40);
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 40,
            duration: const Duration(milliseconds: 5),
            curve: Curves.linear);
      }
    };
  }

  getOrderField() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _textController,
              minLines: 2,
              maxLines: 2, // 设置为null表示文本框可以自动调整大小
              decoration: const InputDecoration(
                labelText: '请输入指令',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            width: 100,
            height: 80,
            padding: const EdgeInsets.only(top: 7, bottom: 7),
            child: Column(
              children: [
                Expanded(
                  child: getButton(
                    context,
                    name: "执行",
                    onPressed: () {
                      _focusNode.unfocus();
                      String text = _textController.text;
                      print(text);
                      connectedDeviceProp.write3OfString(text);
                    },
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Expanded(
                  child: getButton(
                    context,
                    name: "清空",
                    onPressed: () {
                      _focusNode.unfocus();
                      _textController.text = "";
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  getLogList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: logList.length,
      itemBuilder: (context, index) {
        return Container(
          child: Text(logList[index]['time'] + logList[index]['value']),
        );
      },
    );
  }

  String getDate() {
    DateTime now = DateTime.now();
    String formattedDate =
        '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)} ${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}';
    return '$formattedDate ';
  }

  String _twoDigits(int n) {
    if (n >= 10) {
      return '$n';
    } else {
      return '0$n';
    }
  }

  getOneBtnlist(
      {required int type, required Function onTap, required String name}) {
    var border;
    if (type < 3) {
      border = const Border(
          top: BorderSide(), left: BorderSide(), bottom: BorderSide());
    } else {
      border = const Border(
          top: BorderSide(),
          left: BorderSide(),
          right: BorderSide(),
          bottom: BorderSide());
    }
    return Expanded(
      child: InkWell(
        onTap: () {
          onTap();
        },
        child: Container(
          height: 30,
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: currentType == type
              ? BoxDecoration(
                  color: Colors.blue,
                  border: border,
                )
              : BoxDecoration(border: border),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                color: currentType == type ? Colors.white : Colors.black,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  getlistbtn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getOneBtnlist(
          type: 1,
          onTap: () {
            setState(() {
              currentType = 1;
            });
          },
          name: "日志",
        ),
        getOneBtnlist(
          type: 2,
          onTap: () {
            setState(() {
              currentType = 2;
            });
          },
          name: "升级",
        ),
        getOneBtnlist(
          type: 3,
          onTap: () {
            setState(() {
              currentType = 3;
            });
          },
          name: "配置",
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var updateDevice = Get.find<GlobalController>().updateDevice;
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        print("${ble.findInput}  ${ble.rssichange}");
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("配置操作"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text("设备名称 ${name}", style: TextStyle(fontSize: 22.rpx),),
                    SizedBox(height: 6.rpx,),
                    Text("蓝牙地址${id}", style: TextStyle(fontSize: 22.rpx),),
                  ],),
                  ElevatedButton(
                    onPressed: () {
                      _focusNode.unfocus();
                      widget.onDisConnected();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("断开连接"),
                  )
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Obx(() => updateDevice['isUpdate'] == true ? Text("升级中：${updateDevice['sendSuccess']}/${updateDevice['sum']}", style: TextStyle(fontSize: 22.rpx)):const Text("")),
              ),
              getlistbtn(),
              Flexible(
                flex: currentType == 1 ? 1000 : 1,
                child: Offstage(
                  offstage: currentType != 1,
                  child: Column(
                    children: [
                      getOrderField(),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 30,
                        child: Row(
                          children: [
                            getButton(
                              context,
                              name: "清空日志",
                              onPressed: () {
                                connectedDeviceProp.logList.clear();
                                setState(() {
                                  logList = [];
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: getLogList()),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: currentType == 2 ? 1000 : 1,
                child: Offstage(
                  offstage: currentType != 2,
                  child: const UpgradeWidget(),
                ),
              ),
              Flexible(
                flex: currentType == 3 ? 1000 : 1,
                child: Offstage(
                  offstage: currentType != 3,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.toNamed("/wifi");
                          },
                          child: SizedBox(
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("WIFI配网"),
                                Image.asset("images/right.png")
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
