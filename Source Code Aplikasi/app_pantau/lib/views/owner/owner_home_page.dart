import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dashboard_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../shared/widgets.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    return Obx(() {
      if (dashboard.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final revenueKpi = _findKpi(
        dashboard.ownerKpis,
        const ['Total Revenue', 'Revenue', 'Total Pendapatan', 'Net Revenue'],
      );

      final netRevenueKpi = _findKpi(
        dashboard.ownerKpis,
        const ['Net Revenue', 'Pendapatan Bersih'],
      );

      final profitKpi = _findKpi(
        dashboard.ownerKpis,
        const ['Estimasi Profit', 'Profit', 'Estimated Profit'],
      );

      final unitsKpi = _findKpi(
        dashboard.ownerKpis,
        const ['Produk Terjual', 'Units Sold', 'Unit Terjual'],
      );

      final hasData = dashboard.ownerKpis.isNotEmpty ||
          dashboard.ownerRevenueTrend.isNotEmpty ||
          dashboard.ownerTopProducts.isNotEmpty ||
          dashboard.ownerInsights.isNotEmpty;

      final warningInsights = dashboard.ownerInsights
          .where((item) => _isWarning(item.severity))
          .toList();

      final trend = _trendFrom(dashboard.ownerRevenueTrend.toList());

      return AppPage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _OwnerHeroCard(
            totalRevenue: revenueKpi?.value ?? '-',
            trend: trend,
            hasData: hasData,
          ),
          const SizedBox(height: 18),
          _OwnerAlertCard(
            hasData: hasData,
            warningInsights: warningInsights,
          ),
          const SectionHeader(title: 'KPI Bisnis'),
          _OwnerKpiMosaic(
            netRevenue: netRevenueKpi,
            unitsSold: unitsKpi,
            profit: profitKpi,
            totalRevenue: revenueKpi,
          ),
          const SectionHeader(title: 'Revenue Trend'),
          _OwnerRevenueCard(
            points: dashboard.ownerRevenueTrend.toList(),
          ),
          Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Top Product')),
              if (dashboard.ownerTopProducts.isNotEmpty)
                const _MiniBadge(
                  label: 'Top 3',
                  color: AppColors.primary,
                  icon: Icons.emoji_events_rounded,
                ),
            ],
          ),
          if (dashboard.ownerTopProducts.isEmpty)
            const EmptyState(
              title: 'Belum ada produk teratas',
              message:
                  'Produk terlaris akan tampil setelah data penjualan berhasil diproses.',
            )
          else
            _TopProductList(
              items: dashboard.ownerTopProducts.take(3).toList(),
            ),
          if (dashboard.ownerInsights.isNotEmpty) ...[
            const SectionHeader(title: 'Insight Bisnis'),
            _OwnerInsightList(items: dashboard.ownerInsights.take(4).toList()),
          ],
        ],
      );
    });
  }

  KpiMetric? _findKpi(List<KpiMetric> kpis, List<String> candidates) {
    for (final candidate in candidates) {
      for (final kpi in kpis) {
        if (kpi.title.toLowerCase() == candidate.toLowerCase()) {
          return kpi;
        }
      }
    }

    return null;
  }

  bool _isWarning(String value) {
    final text = value.toLowerCase();
    return text.contains('warning') ||
        text.contains('critical') ||
        text.contains('kritis') ||
        text.contains('cek');
  }

  _TrendData? _trendFrom(List<ChartPoint> points) {
    final visible = points.where((point) => point.value > 0).toList();

    if (visible.length < 2) return null;

    final previous = visible[visible.length - 2].value;
    final current = visible.last.value;

    if (previous <= 0) return null;

    final percent = ((current - previous) / previous) * 100;

    return _TrendData(
      label:
          '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}% vs periode lalu',
      isPositive: percent >= 0,
    );
  }
}

class _TrendData {
  const _TrendData({
    required this.label,
    required this.isPositive,
  });

  final String label;
  final bool isPositive;
}

/* -------------------------------------------------------------------------- */
/*                                    HERO                                    */
/* -------------------------------------------------------------------------- */

class _OwnerHeroCard extends StatelessWidget {
  const _OwnerHeroCard({
    required this.totalRevenue,
    required this.trend,
    required this.hasData,
  });

  final String totalRevenue;
  final _TrendData? trend;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2F6BFF),
            Color(0xFF23B7A4),
            Color(0xFF38D68B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.26),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -26,
            child: Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.10),
              ),
            ),
          ),
          Positioned(
            right: -12,
            bottom: -30,
            child: Icon(
              Icons.storefront_rounded,
              size: 132,
              color: Colors.white.withOpacity(.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _GlassChip(
                    label: hasData ? 'Data Aktif' : 'Menunggu Data',
                    icon: hasData
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                  ),
                  const Spacer(),
                  const SiteSelectorDropdown(darkMode: true),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Halo, Owner',
                style: AppText.title.copyWith(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Ringkasan performa bisnis retail terbaru.',
                style: AppText.body.copyWith(
                  color: Colors.white.withOpacity(.88),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withOpacity(.18)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL PENDAPATAN',
                            style: AppText.caption.copyWith(
                              color: Colors.white.withOpacity(.78),
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              totalRevenue,
                              maxLines: 1,
                              style: AppText.kpiNumber.copyWith(
                                color: Colors.white,
                                fontSize: 34,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (trend != null)
                            _GlassChip(
                              label: trend!.label,
                              icon: trend!.isPositive
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                            )
                          else
                            const _GlassChip(
                              label: 'Data tersedia',
                              icon: Icons.insights_rounded,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  ALERT                                     */
/* -------------------------------------------------------------------------- */

class _OwnerAlertCard extends StatelessWidget {
  const _OwnerAlertCard({
    required this.hasData,
    required this.warningInsights,
  });

  final bool hasData;
  final List<InsightItem> warningInsights;

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return _ColorAlertCard(
        title: 'Belum ada data bisnis',
        message: 'Upload data retail untuk mulai melihat performa usaha.',
        label: 'Mulai',
        color: AppColors.info,
        softColor: AppColors.infoSoft,
        icon: Icons.upload_file_rounded,
      );
    }

    if (warningInsights.isEmpty) {
      return _ColorAlertCard(
        title: 'Bisnis dalam kondisi aman',
        message: 'Belum ada insight kritis yang perlu dicek saat ini.',
        label: 'Aman',
        color: AppColors.success,
        softColor: AppColors.successSoft,
        icon: Icons.verified_rounded,
      );
    }

    return _ColorAlertCard(
      title: '${warningInsights.length} Insight perlu dicek',
      message: warningInsights.first.value,
      label: 'Cek',
      color: AppColors.danger,
      softColor: AppColors.dangerSoft,
      icon: Icons.priority_high_rounded,
    );
  }
}

class _ColorAlertCard extends StatelessWidget {
  const _ColorAlertCard({
    required this.title,
    required this.message,
    required this.label,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final String title;
  final String message;
  final String label;
  final Color color;
  final Color softColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withOpacity(.16)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _MiniBadge(
              label: label, color: color, icon: Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  KPI                                       */
/* -------------------------------------------------------------------------- */

class _OwnerKpiMosaic extends StatelessWidget {
  const _OwnerKpiMosaic({
    required this.netRevenue,
    required this.unitsSold,
    required this.profit,
    required this.totalRevenue,
  });

  final KpiMetric? netRevenue;
  final KpiMetric? unitsSold;
  final KpiMetric? profit;
  final KpiMetric? totalRevenue;

  @override
  Widget build(BuildContext context) {
    final items = <_KpiVisualData>[
      if (netRevenue != null)
        _KpiVisualData(
          title: 'Net Revenue',
          value: netRevenue!.value,
          badge: netRevenue!.badge,
          color: AppColors.primary,
          softColor: AppColors.primarySoft,
          icon: Icons.account_balance_wallet_rounded,
        ),
      if (unitsSold != null)
        _KpiVisualData(
          title: 'Produk Terjual',
          value: unitsSold!.value,
          badge: unitsSold!.badge,
          color: AppColors.success,
          softColor: AppColors.successSoft,
          icon: Icons.shopping_bag_rounded,
        ),
      if (profit != null)
        _KpiVisualData(
          title: 'Estimasi Profit',
          value: profit!.value,
          badge: profit!.badge,
          color: AppColors.warning,
          softColor: AppColors.warningSoft,
          icon: Icons.trending_up_rounded,
        ),
      if (totalRevenue != null)
        _KpiVisualData(
          title: 'Total Revenue',
          value: totalRevenue!.value,
          badge: totalRevenue!.badge,
          color: AppColors.tealMint,
          softColor: AppColors.successSoft,
          icon: Icons.payments_rounded,
        ),
    ];

    if (items.isEmpty) {
      return const EmptyState(
        title: 'Belum ada KPI bisnis',
        message:
            'Upload data penjualan, produk, dan inventory agar ringkasan performa bisa ditampilkan.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width < 360 ? 158.0 : 148.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.take(4).length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: height,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            return _ColorKpiCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _KpiVisualData {
  const _KpiVisualData({
    required this.title,
    required this.value,
    required this.badge,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String badge;
  final Color color;
  final Color softColor;
  final IconData icon;
}

class _ColorKpiCard extends StatelessWidget {
  const _ColorKpiCard({required this.item});

  final _KpiVisualData item;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return Container(
      padding: EdgeInsets.all(isCompact ? 13 : 15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: item.softColor),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -20,
            child: Icon(
              item.icon,
              size: 80,
              color: item.color.withOpacity(.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBubble(
                    color: item.color,
                    softColor: item.softColor,
                    icon: item.icon,
                  ),
                  const Spacer(),
                  _MiniBadge(
                    label: item.badge,
                    color: item.color,
                    icon: Icons.circle_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value,
                  maxLines: 1,
                  style: AppText.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 18 : 20,
                    height: 1,
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

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final Color color;
  final Color softColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}


class _OwnerRevenueCard extends StatelessWidget {
  const _OwnerRevenueCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).toList();

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'Revenue trend belum tersedia',
        message:
            'Grafik revenue akan tampil setelah data penjualan berhasil diproses.',
      );
    }

    final chartPoints =
        visible.length > 6 ? visible.sublist(visible.length - 6) : visible;

    final maxValue = chartPoints
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBubble(
                color: AppColors.primary,
                softColor: AppColors.primarySoft,
                icon: Icons.bar_chart_rounded,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text('Revenue Trend', style: AppText.sectionTitle),
              ),
              _MiniBadge(
                label: '${chartPoints.length} Periode',
                color: AppColors.primary,
                icon: Icons.calendar_month_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 190,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primarySoft.withOpacity(.85),
                  AppColors.successSoft.withOpacity(.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight - 30;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chartPoints.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final isLast = index == chartPoints.length - 1;
                    final ratio = maxValue <= 0 ? 0.0 : point.value / maxValue;
                    final barHeight = availableHeight * (0.3 + ratio * 0.7);

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            height: barHeight,
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLast
                                    ? [
                                        AppColors.primary,
                                        AppColors.tealMint,
                                      ]
                                    : [
                                        AppColors.primary.withOpacity(.35),
                                        AppColors.info.withOpacity(.28),
                                      ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isLast
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(.22),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                          const SizedBox(height: 11),
                          Text(
                            _shortLabel(point.label),
                            style: AppText.caption.copyWith(
                              color: isLast
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight:
                                  isLast ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _shortLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return '-';
    if (trimmed.length <= 3) return trimmed.toUpperCase();
    return trimmed.substring(0, 3).toUpperCase();
  }
}

/* -------------------------------------------------------------------------- */
/*                              TOP PRODUCT                                   */
/* -------------------------------------------------------------------------- */

class _TopProductList extends StatelessWidget {
  const _TopProductList({required this.items});

  final List<RankItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        return _TopProductTile(
          item: entry.value,
          index: entry.key + 1,
        );
      }).toList(),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  const _TopProductTile({
    required this.item,
    required this.index,
  });

  final RankItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.success,
      AppColors.primary,
      AppColors.warning,
    ];

    final color = colors[(index - 1).clamp(0, colors.length - 1)];
    final soft = color.withOpacity(.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: soft),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [soft, AppColors.primarySoft.withOpacity(.70)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              index == 1
                  ? Icons.emoji_events_rounded
                  : Icons.shopping_bag_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniBadge(
            label: item.badge,
            color: color,
            icon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  INSIGHT                                   */
/* -------------------------------------------------------------------------- */

class _OwnerInsightList extends StatelessWidget {
  const _OwnerInsightList({required this.items});

  final List<InsightItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final style = _styleFromInsight(item);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: style.softColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: style.color.withOpacity(.14)),
          ),
          child: Row(
            children: [
              _IconBubble(
                color: style.color,
                softColor: Colors.white.withOpacity(.62),
                icon: style.icon,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle.copyWith(
                        color: style.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                label: style.label,
                color: style.color,
                icon: style.icon,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _InsightVisualStyle _styleFromInsight(InsightItem item) {
    final text = '${item.label} ${item.value} ${item.severity}'.toLowerCase();

    if (text.contains('warning') ||
        text.contains('critical') ||
        text.contains('kritis') ||
        text.contains('cek')) {
      return const _InsightVisualStyle(
        label: 'Cek',
        color: AppColors.danger,
        softColor: AppColors.dangerSoft,
        icon: Icons.warning_amber_rounded,
      );
    }

    if (text.contains('positive') ||
        text.contains('top') ||
        text.contains('seller')) {
      return const _InsightVisualStyle(
        label: 'Baik',
        color: AppColors.success,
        softColor: AppColors.successSoft,
        icon: Icons.check_circle_rounded,
      );
    }

    return const _InsightVisualStyle(
      label: 'Info',
      color: AppColors.info,
      softColor: AppColors.infoSoft,
      icon: Icons.info_outline_rounded,
    );
  }
}

class _InsightVisualStyle {
  const _InsightVisualStyle({
    required this.label,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color softColor;
  final IconData icon;
}

/* -------------------------------------------------------------------------- */
/*                                  COMMON                                    */
/* -------------------------------------------------------------------------- */

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
