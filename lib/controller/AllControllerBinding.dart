import 'package:get/get.dart';
import '../controller/GlobalController.dart';

class AllControllerBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GlobalController>(() => GlobalController());
  }
}