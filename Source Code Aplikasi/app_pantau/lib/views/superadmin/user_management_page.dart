import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/user_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../shared/widgets.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final controller = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    Future.microtask(controller.loadUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppPage(
        children: [
          const GradientHeader(
            title: 'User Management',
            subtitle:
                'Kelola akun utama aplikasi. Setiap role hanya memiliki satu akun.',
            icon: Icons.manage_accounts_rounded,
          ),
          const SectionHeader(title: 'Akun Role'),
          if (controller.isLoading.value)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (controller.errorMessage.value != null)
            ErrorState(
              message: controller.errorMessage.value!,
              onRetry: controller.loadUsers,
            )
          else ...[
            _RoleAccountCard(
              role: UserRole.superadmin,
              title: 'Superadmin',
              subtitle:
                  'Akun sistem untuk mengelola user, dataset, dan konfigurasi aplikasi.',
              user: _findUserByRole(UserRole.superadmin),
              canCreate: false,
              canEdit: false,
            ),
            _RoleAccountCard(
              role: UserRole.owner,
              title: 'Owner',
              subtitle:
                  'Pemilik UMKM yang melihat dashboard bisnis, performa global, dan detail cabang.',
              user: _findUserByRole(UserRole.owner),
              canCreate: true,
              canEdit: true,
            ),
            _RoleAccountCard(
              role: UserRole.operational,
              title: 'Admin Operasional',
              subtitle:
                  'Manager operasional global yang memantau stok, produk, logistik, dan cabang.',
              user: _findUserByRole(UserRole.operational),
              canCreate: true,
              canEdit: true,
            ),
          ],
        ],
      ),
    );
  }

  AppUser? _findUserByRole(UserRole role) {
    final matched =
        controller.users.where((user) => user.role == role).toList();
    if (matched.isEmpty) return null;
    return matched.first;
  }
}

class _RoleAccountCard extends StatelessWidget {
  const _RoleAccountCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.user,
    required this.canCreate,
    required this.canEdit,
  });

  final UserRole role;
  final String title;
  final String subtitle;
  final AppUser? user;
  final bool canCreate;
  final bool canEdit;

  bool get hasUser => user != null;

  @override
  Widget build(BuildContext context) {
    final statusLabel = hasUser ? 'Sudah dibuat' : 'Belum dibuat';
    final statusColor = hasUser ? AppColors.success : AppColors.warning;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(.12),
            foregroundColor: AppColors.primary,
            child: Icon(role.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.small),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InsightBadge(label: role.label),
                    InsightBadge(label: statusLabel, color: statusColor),
                    if (role == UserRole.superadmin)
                      const InsightBadge(label: 'Akun Sistem'),
                  ],
                ),
                if (hasUser) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user!.name,
                          style: AppText.cardTitle.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(user!.email, style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RoleActionButton(
            role: role,
            user: user,
            canCreate: canCreate,
            canEdit: canEdit,
          ),
        ],
      ),
    );
  }
}

class _RoleActionButton extends StatelessWidget {
  const _RoleActionButton({
    required this.role,
    required this.user,
    required this.canCreate,
    required this.canEdit,
  });

  final UserRole role;
  final AppUser? user;
  final bool canCreate;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    if (user == null && !canCreate) {
      return const SizedBox.shrink();
    }

    if (user != null && !canEdit) {
      return const SizedBox.shrink();
    }

    if (user == null) {
      return ElevatedButton.icon(
        onPressed: () {
          Get.to(
            () => AddEditUserPage(
              role: role,
            ),
          );
        },
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: const Text('Buat'),
      );
    }

    return OutlinedButton.icon(
      onPressed: () {
        Get.to(
          () => AddEditUserPage(
            role: role,
            user: user,
          ),
        );
      },
      icon: const Icon(Icons.edit_rounded, size: 18),
      label: const Text('Edit'),
    );
  }
}

class AddEditUserPage extends StatefulWidget {
  const AddEditUserPage({
    super.key,
    required this.role,
    this.user,
  });

  final UserRole role;
  final AppUser? user;

  @override
  State<AddEditUserPage> createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends State<AddEditUserPage> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  bool obscurePassword = true;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    nameController = TextEditingController(text: user?.name ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    passwordController = TextEditingController(
      text: isEdit ? '********' : 'sementara123',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = Get.find<UserController>();

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Gagal', 'Nama wajib diisi.');
      return;
    }

    if (email.isEmpty) {
      Get.snackbar('Gagal', 'Email wajib diisi.');
      return;
    }

    if (!isEdit && password.isEmpty) {
      Get.snackbar('Gagal', 'Password wajib diisi.');
      return;
    }

    if (widget.role == UserRole.superadmin) {
      Get.snackbar(
        'Gagal',
        'Akun superadmin tidak dibuat dari halaman ini.',
      );
      return;
    }

    if (!isEdit && _roleAlreadyExists(controller, widget.role)) {
      Get.snackbar(
        'Role sudah ada',
        'Akun ${widget.role.label} sudah dibuat. Silakan edit akun yang tersedia.',
      );
      return;
    }

    if (isEdit) {
      await controller.updateUser(
        id: widget.user!.id,
        name: name,
        email: email,
        role: widget.role,
        password: password == '********' ? null : password,
      );
    } else {
      await controller.addUser(
        name: name,
        email: email,
        role: widget.role,
        password: password,
      );
    }

    if (controller.errorMessage.value == null) {
      await controller.loadUsers();

      Get.back();

      Get.snackbar(
        'Berhasil',
        isEdit ? 'Akun berhasil diperbarui.' : 'Akun berhasil dibuat.',
      );
    } else {
      Get.snackbar('Gagal', controller.errorMessage.value!);
    }
  }

  bool _roleAlreadyExists(UserController controller, UserRole role) {
    return controller.users.any((user) => user.role == role);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEdit ? 'Edit ${widget.role.label}' : 'Buat ${widget.role.label}'),
      ),
      body: Obx(
        () => AppPage(
          children: [
            GradientHeader(
              title: isEdit ? 'Edit Akun' : 'Buat Akun',
              subtitle:
                  'Role akun ini adalah ${widget.role.label}. Role tidak dapat diganti dari form ini.',
              icon: widget.role.icon,
            ),
            const SectionHeader(title: 'Informasi Akun'),
            AppCard(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: widget.role.label),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? 'Password baru, biarkan ******** jika tidak diganti'
                          : 'Password sementara',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : _save,
                icon: Icon(
                    isEdit ? Icons.save_rounded : Icons.person_add_rounded),
                label: Text(isEdit ? 'Simpan Perubahan' : 'Buat Akun'),
              ),
            ),
            if (controller.isLoading.value)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
