import 'package:flutter/material.dart';
import 'package:flutter_ble_scan/common/util.dart';
import 'package:flutter_svg/svg.dart';

class SeatWifiStep3Setting extends StatefulWidget {
  final Function()? onNext;
  const SeatWifiStep3Setting({super.key, this.onNext});

  @override
  SeatWifiStep3SettingState createState() => SeatWifiStep3SettingState();
}

class SeatWifiStep3SettingState extends State<SeatWifiStep3Setting> {
  bool _hasChecked = false;
  final TextEditingController _mWifiController = TextEditingController();
  final TextEditingController _mPwdController = TextEditingController();

  _onChecked(bool? value) {
    setState(() {
      _hasChecked = value!;
    });
  }

  _onWifiTap() {
    var wifiList = [
      {"num": 1, "name": "wifi1"},
    ];
    Widget child = ListView.builder(
      itemCount: wifiList.length,
      itemBuilder: (BuildContext context, int index) {
        var d = wifiList[index];
        return InkWell(
          onTap: () {
            // widget.onSelectWifiName?.call(d);
            print("xxx $d");
          },
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            decoration: const BoxDecoration(
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
                    const SizedBox(
                      width: 20,
                    ),
                    Text("${d['num']}"),
                    const SizedBox(
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
    showCustomBottomSheet(context, child);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Row(
            children: [Text("网络设置")],
          ),
          const SizedBox(height: 16),
          TextField(
            onTap: _onWifiTap,
            controller: _mWifiController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.wifi, color: Colors.black),
              suffixIcon: Icon(Icons.arrow_forward_ios),
              hintText: '请选择WIFI',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mPwdController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock, color: Colors.black),
              hintText: '请输入密码',
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Checkbox(
              value: _hasChecked,
              onChanged: _onChecked,
              fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return normalColor;
                }
                return greyColor;
              }),
            ), // 复选
            InkWell(
                onTap: () => _onChecked(!_hasChecked),
                child: const Text('允许记住密码')),
          ]),
          const SizedBox(height: 40), // 文字描述
          Center(
            child: FilledButton.tonal(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll(Colors.grey.shade300)),
                onPressed: widget.onNext,
                child: const Text('下一步',
                    style: TextStyle(
                        color: Color.fromARGB(255, 80, 179, 146),
                        fontSize: 16))),
          )
        ],
      ),
    );
  }
}
