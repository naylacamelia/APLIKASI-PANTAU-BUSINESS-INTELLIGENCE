import 'package:get/get.dart';

import '../data/supabase_repository.dart';
import 'auth_controller.dart';
import 'dashboard_controller.dart';
import 'dataset_controller.dart';
import 'navigation_controller.dart';
import 'user_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SupabaseRepository>(SupabaseRepository(), permanent: true);
    Get.put<AuthController>(AuthController(Get.find<SupabaseRepository>()), permanent: true);
    Get.put<NavigationController>(NavigationController(), permanent: true);
    Get.put<DatasetController>(DatasetController(Get.find<SupabaseRepository>(), Get.find<AuthController>()), permanent: true);
    Get.put<DashboardController>(DashboardController(Get.find<SupabaseRepository>(), Get.find<AuthController>()), permanent: true);
    Get.put<UserController>(UserController(Get.find<SupabaseRepository>()), permanent: true);
  }
}
