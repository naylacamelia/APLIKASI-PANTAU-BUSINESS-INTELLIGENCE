import 'package:get/get.dart';

import '../data/supabase_repository.dart';
import '../models/models.dart';

class UserController extends GetxController {
  UserController(this._repository);

  final SupabaseRepository _repository;

  final users = <AppUser>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  Future<void> loadUsers() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      users.assignAll(await _repository.fetchUsers());
    } catch (error) {
      errorMessage.value = 'Gagal mengambil user: $error';
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addUser({required String name, required String email, required UserRole role, required String password}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repository.insertUser(name: name, email: email, role: role, password: password);
      await loadUsers();
    } catch (error) {
      errorMessage.value = 'Gagal menambah user: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUser({required String id, required String name, required String email, required UserRole role, String? password}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repository.updateUser(id: id, name: name, email: email, role: role, password: password);
      await loadUsers();
    } catch (error) {
      errorMessage.value = 'Gagal update user: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String id) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _repository.deleteUser(id);
      await loadUsers();
    } catch (error) {
      errorMessage.value = 'Gagal hapus user: $error';
    } finally {
      isLoading.value = false;
    }
  }
}
