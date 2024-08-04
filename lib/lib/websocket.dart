import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketProp {
  late WebSocketChannel channel;
  late bool isConnecting;
  late String url;
  late Map fun;
  String nickName = "";
  String avatarUrl = "none";

  void initState(String a, Map funn) async {
    print(a);
    fun = funn;
    url = a;
    isConnecting = false;
    _connect();
  }

  void _connect() {
    channel = IOWebSocketChannel.connect(url);
    channel.stream.listen((message) {
      // print('Received message: $message');
      // Handle incoming messages here
      heartCheck();
      if (message == "open") {
        fun['open']?.call();
        print('Received message: $message');
        return;
      }
      if (message == "ht") {
        print('Received message: $message');
        return;
      }
      fun["message"]?.call(message);
    }, onError: (error) {
      // Handle connection error and initiate reconnection
      print('Error: $error');
      _reconnect();
    }, onDone: () {
      // Handle connection closed
      print('Connection closed');
      _reconnect();
    });
  }

  Timer? timeoutObj;
  Timer? serverTimeoutObj;
  int timeout = 10;

  void heartCheck() {
    timeoutObj?.cancel();
    serverTimeoutObj?.cancel();
    timeoutObj = Timer(Duration(seconds: timeout), () {
      sendMessage("ht");
      serverTimeoutObj = Timer(Duration(seconds: timeout), () {
        dispose();
      });
    });
  }

  void _reconnect() {
    if (!isConnecting) {
      isConnecting = true;
      Timer(Duration(seconds: 5), () {
        // Retry connection after 5 seconds
        _connect();
        isConnecting = false;
      });
    }
  }

  void sendMessage(data) {
    if (data is String) {
      channel.sink.add(data);
    } else {
      String s = jsonEncode(data);
      // print("发送 $s");
      channel.sink.add(s);
    }
  }

  sendWebSocketMessageCodeN(code, data) {
    sendMessage({"code": code, "data": data});
  }

  void dispose() {
    channel.sink.close();
  }
}
