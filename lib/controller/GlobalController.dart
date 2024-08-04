import 'package:event_bus/event_bus.dart';
import 'package:get/get.dart';
import '../lib/ble.dart';

class GlobalController extends GetxController {
  RxMap updateDevice = {}.obs;
  RxString token = '167b3fc3f61e7a41e20345dda17af1ca'.obs;
  EventBus eventBus = EventBus();
  ConnectedDeviceProp? connectedDeviceProp;
}