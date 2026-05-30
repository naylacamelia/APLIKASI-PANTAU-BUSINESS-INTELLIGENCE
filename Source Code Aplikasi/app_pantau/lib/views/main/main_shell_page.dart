  import 'package:flutter/material.dart';
  import 'package:get/get.dart';

  import '../../controllers/auth_controller.dart';
  import '../../controllers/dashboard_controller.dart';
  import '../../controllers/dataset_controller.dart';
  import '../../controllers/navigation_controller.dart';
  import '../../controllers/user_controller.dart';
  import '../../core/theme.dart';
  import '../../models/models.dart';
  import '../data/data_management_page.dart';
  import '../operational/operational_home_page.dart';
  import '../owner/owner_home_page.dart';
  import '../shared/analytics_page.dart';
  import '../shared/profile_page.dart';
  import '../superadmin/superadmin_home_page.dart';
  import '../superadmin/user_management_page.dart';

  class MainShellPage extends StatelessWidget {
    const MainShellPage({super.key});

    @override
    Widget build(BuildContext context) {
      final auth = Get.find<AuthController>();
      final nav = Get.find<NavigationController>();
      final dashboard = Get.find<DashboardController>();
      final dataset = Get.find<DatasetController>();
      final users = Get.find<UserController>();

      return Obx(() {
        final role = auth.effectiveRole;
        final items = _itemsFor(role);
        final selectedIndex = nav.selectedIndex.value.clamp(0, items.length - 1);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/logo_pantau.png',
                  width: 34,
                  height: 34,
                ),
                const SizedBox(width: 10),
                const Text('Pantau'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Notifikasi',
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: Column(
            children: [
              if (auth.isPreviewMode)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mode Preview ${role.label}',
                          style: AppText.cardTitle.copyWith(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: auth.exitPreview,
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                ),
              Expanded(child: _bodyFor(role, selectedIndex)),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(.06),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) async {
                nav.setIndex(index);
                if (index == 0 || (role != UserRole.superadmin && index == 1))
                  await dashboard.loadDashboard();
                if (index == 1 && role == UserRole.superadmin)
                  await users.loadUsers();
                if (index == 2) await dataset.loadDatasets();
              },
              destinations: items
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      });
    }

    Widget _bodyFor(UserRole role, int index) {
      if (index == 0) {
        switch (role) {
          case UserRole.owner:
            return const OwnerHomePage();
          case UserRole.operational:
            return const OperationalHomePage();
          case UserRole.superadmin:
            return const SuperadminHomePage();
        }
      }
      if (index == 1) {
        return role == UserRole.superadmin
            ? const UserManagementPage()
            : const AnalyticsPage();
      }
      if (index == 2) return const DataManagementPage();
      return const ProfilePage();
    }

    List<_NavItem> _itemsFor(UserRole role) {
      if (role == UserRole.superadmin) {
        return const [
          _NavItem('Beranda', Icons.home_rounded),
          _NavItem('User', Icons.groups_2_outlined),
          _NavItem('Data', Icons.storage_rounded),
          _NavItem('Profil', Icons.person_outline_rounded),
        ];
      }
      return const [
        _NavItem('Beranda', Icons.home_rounded),
        _NavItem('Analitik', Icons.insert_chart_outlined_rounded),
        _NavItem('Data', Icons.storage_rounded),
        _NavItem('Profil', Icons.person_outline_rounded),
      ];
    }
  }

  class _NavItem {
    const _NavItem(this.label, this.icon);
    final String label;
    final IconData icon;
  }
