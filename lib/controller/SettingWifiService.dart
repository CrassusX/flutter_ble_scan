import 'package:get/get.dart';

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

  // 去扫描页面
  void onGoScanWifi() async {
    var code = await Get.toNamed('/qrScan');
    print("code $code");
  }
}
