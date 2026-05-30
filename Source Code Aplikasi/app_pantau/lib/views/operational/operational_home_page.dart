  import 'package:flutter/material.dart';
  import 'package:get/get.dart';

  import '../../controllers/dashboard_controller.dart';
  import '../../core/theme.dart';
  import '../../models/models.dart';
  import '../shared/analytics_page.dart';
  import '../shared/widgets.dart';

  class OperationalHomePage extends StatelessWidget {
    const OperationalHomePage({super.key});

    @override
    Widget build(BuildContext context) {
      final dashboard = Get.find<DashboardController>();

      return Obx(() {
        final isLoading = dashboard.isLoading.value;
        final error = dashboard.errorMessage.value;

        final kpis = dashboard.operationalKpis.toList();
        final restockItems = dashboard.restockPriority.toList();
        final criticalItems = dashboard.criticalStockItems.toList();
        final overstockItems = dashboard.overstockItems.toList();
        final logisticsItems = dashboard.logisticsIssues.toList();
        final slowMovingItems = dashboard.slowMovingProducts.toList();
        final statusPoints = dashboard.operationalStockStatusChart.toList();

        final hasAnyOperationalData =
            dashboard.hasOperationalInventoryData.value ||
                dashboard.hasOperationalProductData.value ||
                dashboard.hasOperationalLogisticData.value;

        final actionCount = restockItems.length +
            criticalItems.length +
            overstockItems.length +
            logisticsItems.length +
            slowMovingItems.length;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return AppPage(
          children: [
            const GradientHeader(
              title: 'Dashboard Operasional',
              subtitle: 'Pantau stok, pergerakan produk, dan logistik.',
              trailing: SizedBox(
                width: 170,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SiteSelectorDropdown(darkMode: true),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              ErrorState(message: error, onRetry: dashboard.loadDashboard),
            ],
            const SizedBox(height: 16),
            if (!hasAnyOperationalData)
              const EmptyState(
                title: 'Data belum tersedia',
                message:
                    'Upload data Inventory, Sales, Product, atau Logistic untuk melihat ringkasan operasional.',
              )
            else if (actionCount > 0)
              CompactAlertBanner(
                title: 'Ada tindakan operasional yang perlu dicek',
                message:
                    'Daftar prioritas dibuat dari data operasional terbaru, seperti stok, restock, pergerakan produk, dan pengiriman.',
                chips: _priorityChips(
                  restock: restockItems.length,
                  critical: criticalItems.length,
                  overstock: overstockItems.length,
                  logistics: logisticsItems.length,
                  slowMoving: slowMovingItems.length,
                ),
                cta: 'Cek',
                status: AppStatus.warning,
                onTap: () => _openInventoryAnalytics(),
              )
            else
              const CompactAlertBanner(
                title: 'Kondisi operasional aman saat ini',
                message:
                    'Tidak ada prioritas restock, stok kritis, atau isu logistik dari data yang tersedia.',
                chips: ['Aman'],
                cta: 'Detail',
                status: AppStatus.success,
              ),
            const SectionHeader(title: 'KPI Operasional'),
            if (kpis.isEmpty)
              const EmptyState(
                title: 'Belum ada ringkasan',
                message:
                    'Upload data operasional agar KPI bisa dihitung tanpa data dummy.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kpis.length > 4 ? 4 : kpis.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 152,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) => KpiCard(metric: kpis[index]),
              ),
            const SectionHeader(title: 'Status Inventaris'),
            if (!dashboard.hasOperationalInventoryData.value)
              const EmptyState(
                title: 'Belum ada data stok',
                message:
                    'Upload data Inventory agar status stok keseluruhan bisa ditampilkan.',
              )
            else
              StatusDonutCard(
                title: 'Status Stok Keseluruhan',
                points: statusPoints,
                emptyTitle: 'Belum ada status stok',
                emptyMessage:
                    'Data Inventory tersedia, tetapi status stok belum bisa dihitung.',
              ),
            SectionHeader(
              title: 'Tindakan Prioritas',
              action: TextButton(
                onPressed: _openInventoryAnalytics,
                child: const Text('Lihat Analitik'),
              ),
            ),
            _AdminActionTabs(
              restockItems: restockItems,
              criticalItems: criticalItems,
              overstockItems: overstockItems,
              logisticsItems: logisticsItems,
              slowMovingItems: slowMovingItems,
              hasInventoryData: dashboard.hasOperationalInventoryData.value,
              hasProductData: dashboard.hasOperationalProductData.value,
              hasLogisticData: dashboard.hasOperationalLogisticData.value,
            ),
          ],
        );
      });
    }

    List<String> _priorityChips({
      required int restock,
      required int critical,
      required int overstock,
      required int logistics,
      required int slowMoving,
    }) {
      final chips = <String>[];

      if (critical > 0) chips.add('$critical Kritis');
      if (restock > 0) chips.add('$restock Restock');
      if (logistics > 0) chips.add('$logistics Delay Risk');
      if (overstock > 0) chips.add('$overstock Overstock');
      if (slowMoving > 0) chips.add('$slowMoving Slow Moving');

      return chips.take(4).toList();
    }

    void _openInventoryAnalytics() {
      Get.to(
        () => const AnalyticsDetailPage(
          category: AnalyticsCategory(
            title: 'Inventory',
            subtitle: 'Status stok dan restock',
            metric: 'Prioritas',
            badge: 'Stok',
            icon: Icons.warehouse_rounded,
          ),
          role: UserRole.operational,
        ),
      );
    }
  }

  class _AdminActionTabs extends StatefulWidget {
    const _AdminActionTabs({
      required this.restockItems,
      required this.criticalItems,
      required this.overstockItems,
      required this.logisticsItems,
      required this.slowMovingItems,
      required this.hasInventoryData,
      required this.hasProductData,
      required this.hasLogisticData,
    });

    final List<RankItem> restockItems;
    final List<RankItem> criticalItems;
    final List<RankItem> overstockItems;
    final List<RankItem> logisticsItems;
    final List<RankItem> slowMovingItems;
    final bool hasInventoryData;
    final bool hasProductData;
    final bool hasLogisticData;

    @override
    State<_AdminActionTabs> createState() => _AdminActionTabsState();
  }

  class _AdminActionTabsState extends State<_AdminActionTabs> {
    int selectedIndex = 0;

    @override
    Widget build(BuildContext context) {
      final groups = [
        _ActionGroup(
          label: 'Restock',
          icon: Icons.playlist_add_check_rounded,
          items: widget.restockItems,
          hasSourceData: widget.hasInventoryData,
          emptyTitle: widget.hasInventoryData
              ? 'Tidak ada prioritas restock'
              : 'Belum ada data stok',
          emptyMessage: widget.hasInventoryData
              ? 'Tidak ada produk yang perlu direstock dari data saat ini.'
              : 'Upload data Inventory agar prioritas restock bisa dihitung.',
        ),
        _ActionGroup(
          label: 'Kritis',
          icon: Icons.warning_amber_rounded,
          items: widget.criticalItems,
          hasSourceData: widget.hasInventoryData,
          emptyTitle: widget.hasInventoryData
              ? 'Tidak ada stok kritis'
              : 'Belum ada data stok',
          emptyMessage: widget.hasInventoryData
              ? 'Tidak ada produk dengan status stok kritis saat ini.'
              : 'Upload data Inventory agar stok kritis bisa dihitung.',
        ),
        _ActionGroup(
          label: 'Overstock',
          icon: Icons.inventory_2_rounded,
          items: widget.overstockItems,
          hasSourceData: widget.hasInventoryData,
          emptyTitle: widget.hasInventoryData
              ? 'Tidak ada overstock'
              : 'Belum ada data stok',
          emptyMessage: widget.hasInventoryData
              ? 'Tidak ada stok berlebih yang perlu dievaluasi saat ini.'
              : 'Upload data Inventory agar stok berlebih bisa dianalisis.',
        ),
        _ActionGroup(
          label: 'Logistik',
          icon: Icons.local_shipping_rounded,
          items: widget.logisticsItems,
          hasSourceData: widget.hasLogisticData,
          emptyTitle: widget.hasLogisticData
              ? 'Tidak ada isu logistik'
              : 'Belum ada data logistik',
          emptyMessage: widget.hasLogisticData
              ? 'Tidak ada pengiriman bermasalah saat ini.'
              : 'Upload data Logistic agar isu pengiriman bisa ditampilkan.',
        ),
        _ActionGroup(
          label: 'Slow',
          icon: Icons.speed_rounded,
          items: widget.slowMovingItems,
          hasSourceData: widget.hasProductData,
          emptyTitle: widget.hasProductData
              ? 'Belum ada slow moving'
              : 'Belum ada data penjualan',
          emptyMessage: widget.hasProductData
              ? 'Belum ada produk lambat bergerak yang perlu dievaluasi.'
              : 'Upload data Sales dan Product agar pergerakan produk bisa dihitung.',
        ),
      ];

      if (selectedIndex >= groups.length) selectedIndex = 0;
      final active = groups[selectedIndex];
      final activeStyle = statusStyleForText(active.label);

      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: groups.asMap().entries.map((entry) {
                  final index = entry.key;
                  final group = entry.value;
                  final isSelected = selectedIndex == index;
                  final style = statusStyleForText(group.label);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(
                        group.icon,
                        size: 16,
                        color: isSelected ? style.color : AppColors.textSecondary,
                      ),
                      label: Text(group.label),
                      labelStyle: AppText.caption.copyWith(
                        color: isSelected ? style.color : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor: style.background,
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: isSelected
                              ? style.color.withOpacity(.2)
                              : AppColors.borderSoft,
                        ),
                      ),
                      onSelected: (_) => setState(() => selectedIndex = index),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: activeStyle.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(active.icon, color: activeStyle.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(active.label, style: AppText.cardTitle)),
                InsightBadge(label: '${active.items.length} Item'),
              ],
            ),
            const SizedBox(height: 12),
            if (active.items.isEmpty)
              InlineEmptyState(
                title: active.emptyTitle,
                message: active.emptyMessage,
              )
            else
              ...active.items.take(4).toList().asMap().entries.map(
                    (entry) => RankCard(
                      item: entry.value,
                      index: entry.key + 1,
                      compact: true,
                    ),
                  ),
          ],
        ),
      );
    }
  }

  class _ActionGroup {
    const _ActionGroup({
      required this.label,
      required this.icon,
      required this.items,
      required this.hasSourceData,
      required this.emptyTitle,
      required this.emptyMessage,
    });

    final String label;
    final IconData icon;
    final List<RankItem> items;
    final bool hasSourceData;
    final String emptyTitle;
    final String emptyMessage;
  }
