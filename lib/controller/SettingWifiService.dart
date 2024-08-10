import 'package:flutter_ble_scan/common/util.dart';
import 'package:get/get.dart';
import 'package:flutter_ble_scan/lib/ble.dart' as ble;

class GetSettingWifiService extends GetxService {
  // 单利初始化
  static GetSettingWifiService get to => Get.find();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // 第一步，去扫描页面
  void onGoScanWifi() async {
    _startScanBle();
    // var code = await Get.toNamed('/qrScan');
    // print("code $code");
    // if (isSuccessfulScan(code)) {
    //   // var resp = await ApiService.getDeviceInfo(code!);
    //   // if (resp != null) {
    //   //   var deviceInfo = DeviceInfo.fromJson(resp);
    //   //   if (deviceInfo.data?.macAddress != null) {
    //   //     // 查找的mac 地址连接
    //   //     var macAddrss = deviceInfo.data?.getMacAddrss;
    //   //     var device = devices
    //   //         .firstWhereOrNull((element) => element?['id'] == macAddrss);
    //   //     if (device != null) {
    //   //       toConnectToDevice(device['device']);
    //   //     }
    //   //   }
    //   // }
    // } else {
    //   showToast("扫码失败，不符合格式的设备码!");
    // }
  }

  // 开始蓝牙扫描
  _startScanBle() {
    ble.findInput = 'AITH';
    ble.start((List bleList){
      print("bleList $bleList");
    });
  }
  // 连接蓝牙设备
  _connectBle() {}
  // 断开设备连接
  _disconnectBle() {}
}
