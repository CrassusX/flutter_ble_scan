import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class WifiListDialog extends StatefulWidget {
  const WifiListDialog({super.key});

  @override
  State<WifiListDialog> createState() => WifiListDialogState();
}

class WifiListDialogState extends State<WifiListDialog> {
  List wifiList = [];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Get.height * 0.5,
      width: Get.width * 0.8,
      child: wifiList.isNotEmpty ? ListView.builder(
        itemCount: wifiList.length,
        itemBuilder: (BuildContext context, int index) {
          var d = wifiList[index];
          return InkWell(
            onTap: () {
              // inputPwd(d);
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
      ): const Center(child: Text("暂无数据！"),),
    );
  }
}
