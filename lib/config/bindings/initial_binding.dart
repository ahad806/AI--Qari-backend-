import 'package:al_qari/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:al_qari/features/auth/presentation/controllers/auth_controller.dart';
import 'package:al_qari/features/progress/progress_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(
      AuthController(AuthRepositoryImpl()),
      permanent: true,
    );
    // Permanent so GetX's SmartManagement never deletes it during route
    // changes. ProgressScreen lives in an IndexedStack and must always have
    // a live controller with isLoading==false after the first load.
    Get.put<ProgressController>(ProgressController(), permanent: true);
  }
}
