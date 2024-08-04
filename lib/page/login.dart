import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/GlobalController.dart';
import '../dio/dio.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final usernameC = TextEditingController();
  final pwdC = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      usernameC.text = "user";
      pwdC.text = "user";
    });
    usernameC.addListener(() {});
    pwdC.addListener(() {});
  }

   void login() {
    print("userpwd  ${usernameC.text} : ${pwdC.text}");
    ApiService.dio.post("/login", data: {
      "userId": usernameC.text,
			"pwd": pwdC.text
    }).then((value){
      Get.toNamed("/index");
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    usernameC.dispose();
    pwdC.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("登录")),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
        children: [
          TextField(
            controller: usernameC,
            decoration: InputDecoration(
              labelText: '输入账号',
              prefixIcon: const Icon(Icons.account_box),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            )
          ),
          const SizedBox(width: double.infinity, height: 30),
          TextField(
            controller: pwdC,
            obscureText: true,
            decoration: InputDecoration(
              labelText: '输入密码',
              prefixIcon: const Icon(Icons.password_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            )
          ),
          Container(
            height: 60,
            margin: const EdgeInsets.only(top: 40),
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Get.find<GlobalController>().token.value = DateTime.now().toString();
                  login();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, // 背景颜色
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 22
                  ),
                ),
                child: const Text('登录')),
          ),
          Obx(() => Text(Get.find<GlobalController>().token.value))
        ],
      ),
    );
  }
}
