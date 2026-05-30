import 'package:get/get.dart';

import '../data/supabase_repository.dart';
import '../models/models.dart';

class AuthController extends GetxController {
  AuthController(this._repository);

  final SupabaseRepository _repository;

  final Rxn<AppUser> currentUser = Rxn<AppUser>();
  final Rxn<UserRole> previewRole = Rxn<UserRole>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  UserRole? get currentRole => currentUser.value?.role;
  UserRole get effectiveRole => previewRole.value ?? currentRole ?? UserRole.owner;
  bool get isLoggedIn => currentUser.value != null;
  bool get isPreviewMode => previewRole.value != null && currentRole == UserRole.superadmin;
  bool get canDownloadReport => currentRole == UserRole.owner && previewRole.value == null;
  bool get canResetDatasets => currentRole == UserRole.superadmin && previewRole.value == null;


  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final user = await _repository.login(email: email, password: password);
      if (user == null) {
        errorMessage.value = 'Email atau password salah.';
        return false;
      }
      currentUser.value = user;
      previewRole.value = null;
      return true;
    } catch (error) {
      errorMessage.value = 'Gagal login ke database: $error';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    currentUser.value = null;
    previewRole.value = null;
  }

  void startPreview(UserRole role) {
    if (currentRole != UserRole.superadmin) return;
    if (role == UserRole.superadmin) return;
    previewRole.value = role;
  }

  void exitPreview() {
    previewRole.value = null;
  }
}
