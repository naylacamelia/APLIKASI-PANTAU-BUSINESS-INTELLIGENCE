import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/dataset_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../auth/login_page.dart';
import 'widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final auth = Get.find<AuthController>();
  final dataset = Get.find<DatasetController>();
  final nav = Get.find<NavigationController>();

  String staffArea = 'Operasional Toko';
  String staffShift = 'Shift Pagi';
  String staffNumber = 'Belum diisi';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = auth.currentUser.value;
      final role = auth.effectiveRole;
      final activeDatasets = dataset.summaries
          .where((summary) => summary.rows > 0)
          .length;
      final totalDatasets = dataset.summaries.length;

      return AppPage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _ProfileHeroCard(
            name: user?.name ?? '-',
            email: user?.email ?? '-',
            role: role,
            isActive: user?.isActive ?? false,
            staffArea: staffArea,
            staffShift: staffShift,
            onEdit: () {
              _showEditProfileSheet(
                context,
                name: user?.name ?? '-',
                email: user?.email ?? '-',
                role: role,
                isActive: user?.isActive ?? false,
              );
            },
          ),
          const SectionHeader(title: 'Akun Staff'),
          _ProfileInfoCard(
            role: role,
            email: user?.email ?? '-',
            isActive: user?.isActive ?? false,
            staffArea: staffArea,
            staffShift: staffShift,
            staffNumber: staffNumber,
          ),
          const SectionHeader(title: 'Menu'),
          _ProfileActionCard(
            activeDatasets: activeDatasets,
            totalDatasets: totalDatasets,
            onOpenData: () async {
              nav.setIndex(2);
              await dataset.loadDatasets();
            },
            onEditProfile: () {
              _showEditProfileSheet(
                context,
                name: user?.name ?? '-',
                email: user?.email ?? '-',
                role: role,
                isActive: user?.isActive ?? false,
              );
            },
            onLogout: () {
              _confirmLogout();
            },
          ),
        ],
      );
    });
  }

  void _showEditProfileSheet(
    BuildContext context, {
    required String name,
    required String email,
    required UserRole role,
    required bool isActive,
  }) {
    final areaController = TextEditingController(text: staffArea);
    final shiftController = TextEditingController(text: staffShift);
    final staffNumberController = TextEditingController(text: staffNumber);

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Profil Staff',
                        style: AppText.sectionTitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ReadonlyProfileField(
                  label: 'Nama',
                  value: name,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _ReadonlyProfileField(
                  label: 'Email',
                  value: email,
                  icon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 12),
                _ReadonlyProfileField(
                  label: 'Role',
                  value: role.label,
                  icon: Icons.admin_panel_settings_outlined,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: staffNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Staff',
                    hintText: 'Contoh: OP-001',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area / Cabang',
                    hintText: 'Contoh: Gudang, Kasir, Toko Utama',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shiftController,
                  decoration: const InputDecoration(
                    labelText: 'Shift',
                    hintText: 'Contoh: Shift Pagi / Shift Sore',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                _ReadonlyProfileField(
                  label: 'Status Akun',
                  value: isActive ? 'Aktif' : 'Nonaktif',
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  color: AppColors.infoSoft,
                  borderColor: AppColors.info.withOpacity(.18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nama, email, role, dan status akun mengikuti data akun aplikasi. Area, shift, dan nomor staff dapat dipakai sebagai informasi operasional staff.',
                          style: AppText.caption.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.45,
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
                    onPressed: () {
                      setState(() {
                        staffArea = areaController.text.trim().isEmpty
                            ? 'Belum diisi'
                            : areaController.text.trim();

                        staffShift = shiftController.text.trim().isEmpty
                            ? 'Belum diisi'
                            : shiftController.text.trim();

                        staffNumber = staffNumberController.text.trim().isEmpty
                            ? 'Belum diisi'
                            : staffNumberController.text.trim();
                      });

                      Get.back();

                      Get.snackbar(
                        'Profil diperbarui',
                        'Informasi staff operasional berhasil diperbarui.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan Profil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Anda akan keluar dari aplikasi Pantau Retail.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              auth.logout();
              nav.reset();
              Get.offAll(() => const LoginPage());
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.staffArea,
    required this.staffShift,
    required this.onEdit,
  });

  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String staffArea;
  final String staffShift;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              Icons.storefront_rounded,
              size: 110,
              color: Colors.white.withOpacity(.07),
            ),
          ),
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(.26),
                  ),
                ),
                child: Icon(
                  role.icon,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroBadge(label: role.label),
                        _HeroBadge(label: isActive ? 'Aktif' : 'Nonaktif'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(
                        color: Colors.white,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        color: Colors.white.withOpacity(.84),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$staffArea • $staffShift',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: Colors.white.withOpacity(.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.role,
    required this.email,
    required this.isActive,
    required this.staffArea,
    required this.staffShift,
    required this.staffNumber,
  });

  final UserRole role;
  final String email;
  final bool isActive;
  final String staffArea;
  final String staffShift;
  final String staffNumber;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Role',
            value: role.label,
            status: AppStatus.info,
          ),
          const _ProfileDivider(),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: email,
            status: AppStatus.info,
          ),
          const _ProfileDivider(),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Nomor Staff',
            value: staffNumber,
            status: staffNumber == 'Belum diisi'
                ? AppStatus.warning
                : AppStatus.success,
          ),
          const _ProfileDivider(),
          _InfoRow(
            icon: Icons.storefront_outlined,
            label: 'Area / Cabang',
            value: staffArea,
            status: AppStatus.success,
          ),
          const _ProfileDivider(),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Shift',
            value: staffShift,
            status: AppStatus.success,
          ),
          const _ProfileDivider(),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Status Akun',
            value: isActive ? 'Aktif' : 'Nonaktif',
            status: isActive ? AppStatus.success : AppStatus.critical,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: style.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppText.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.activeDatasets,
    required this.totalDatasets,
    required this.onOpenData,
    required this.onEditProfile,
    required this.onLogout,
  });

  final int activeDatasets;
  final int totalDatasets;
  final VoidCallback onOpenData;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final dataSubtitle = totalDatasets == 0
        ? 'Belum ada dataset'
        : '$activeDatasets dari $totalDatasets dataset aktif';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ProfileMenuItem(
            icon: Icons.edit_note_rounded,
            title: 'Edit Profil',
            subtitle: 'Ubah area, shift, dan nomor staff',
            status: AppStatus.info,
            onTap: onEditProfile,
          ),
          const _ProfileDivider(),
          _ProfileMenuItem(
            icon: Icons.storage_rounded,
            title: 'Data Operasional',
            subtitle: dataSubtitle,
            badge: activeDatasets > 0 ? 'Aktif' : 'Kosong',
            status: activeDatasets > 0 ? AppStatus.success : AppStatus.warning,
            onTap: onOpenData,
          ),
          const _ProfileDivider(),
          _ProfileMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Keluar dari akun aplikasi',
            status: AppStatus.critical,
            hideChevron: true,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    this.badge,
    this.hideChevron = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppStatus status;
  final VoidCallback onTap;
  final String? badge;
  final bool hideChevron;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: style.color,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.cardTitle.copyWith(
                      color: status == AppStatus.critical
                          ? AppColors.danger
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              InsightBadge(
                label: badge!,
                color: style.color,
              ),
            ],
            if (!hideChevron) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadonlyProfileField extends StatelessWidget {
  const _ReadonlyProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: AppColors.borderSoft.withOpacity(.75),
    );
  }
}