import 'package:get/get.dart';

class NavigationController extends GetxController {
  final selectedIndex = 0.obs;

  void setIndex(int index) {
    selectedIndex.value = index;
  }

  void reset() {
    selectedIndex.value = 0;
  }
}
