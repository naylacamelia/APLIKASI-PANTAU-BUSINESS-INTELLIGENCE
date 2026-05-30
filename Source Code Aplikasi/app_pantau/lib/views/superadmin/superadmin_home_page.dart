import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/dataset_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/models.dart';
import '../shared/widgets.dart';

class SuperadminHomePage extends StatelessWidget {
  const SuperadminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final nav = Get.find<NavigationController>();
    final dataset = Get.find<DatasetController>();
    final dashboard = Get.find<DashboardController>();
    final users = Get.find<UserController>();

    return Obx(() {
      final activeUsers = users.users.where((user) => user.isActive).length;
      final inactiveUsers = users.users.where((user) => !user.isActive).length;
      final activeDatasets = dataset.summaries
          .where((summary) => summary.rows > 0)
          .length;
      final roleCount = users.users.map((user) => user.role).toSet().length;

      return AppPage(
        children: [
          const GradientHeader(
            title: 'Halo, Superadmin',
            subtitle:
                'Kelola user, role, dan dataset aplikasi tanpa data dummy.',
            badge: 'Superadmin',
            icon: Icons.admin_panel_settings_rounded,
          ),
          const SectionHeader(title: 'Ringkasan Sistem'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .96,
            children: [
              KpiCard(
                metric: KpiMetric(
                  title: 'User Aktif',
                  value: '$activeUsers',
                  badge: 'Aktif',
                  icon: Icons.groups_2_outlined,
                ),
              ),
              KpiCard(
                metric: KpiMetric(
                  title: 'Dataset Aktif',
                  value: '$activeDatasets',
                  badge: 'Data',
                  icon: Icons.storage_rounded,
                ),
              ),
              KpiCard(
                metric: KpiMetric(
                  title: 'Role Terpakai',
                  value: '$roleCount',
                  badge: 'Role',
                  icon: Icons.admin_panel_settings_rounded,
                ),
              ),
              KpiCard(
                metric: KpiMetric(
                  title: 'User Nonaktif',
                  value: '$inactiveUsers',
                  badge: inactiveUsers > 0 ? 'Cek' : 'Aman',
                  icon: Icons.person_off_outlined,
                ),
              ),
            ],
          ),
          const SectionHeader(title: 'Quick Actions'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.groups_2_outlined),
                  title: const Text('Kelola User'),
                  subtitle: const Text(
                    'Tambah, ubah, atau nonaktifkan akses pengguna.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    nav.setIndex(1);
                    await users.loadUsers();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded),
                  title: const Text('Import Dataset'),
                  subtitle: const Text(
                    'Kelola file sumber untuk dashboard BI.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    nav.setIndex(2);
                    await dataset.loadDatasets();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Lihat sebagai Owner'),
                  subtitle: const Text(
                    'Preview dashboard owner dengan data aktif.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    auth.startPreview(UserRole.owner);
                    nav.reset();
                    await dataset.loadDatasets();
                    await dashboard.loadDashboard();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Lihat sebagai Operasional'),
                  subtitle: const Text(
                    'Preview dashboard admin operasional dengan data aktif.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    auth.startPreview(UserRole.operational);
                    nav.reset();
                    await dataset.loadDatasets();
                    await dashboard.loadDashboard();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
