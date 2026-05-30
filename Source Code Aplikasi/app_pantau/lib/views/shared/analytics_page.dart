import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import 'widgets.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final dashboard = Get.find<DashboardController>();

    return Obx(() {
      final role = auth.effectiveRole;
      final categories = role == UserRole.owner
          ? dashboard.ownerAnalytics.toList()
          : dashboard.operationalAnalytics.toList();

      return AppPage(
        children: [
          GradientHeader(
            title: role == UserRole.owner
                ? 'Analitik Owner'
                : 'Analitik Operasional',
            subtitle: role == UserRole.owner
                ? 'Pantau performa bisnis retail dari data terbaru.'
                : 'Pantau stok, pergerakan produk, dan logistik.',
            trailing: const SizedBox(
              width: 170,
              child: Align(
                alignment: Alignment.centerRight,
                child: SiteSelectorDropdown(darkMode: true),
              ),
            ),
          ),
          const SectionHeader(title: 'Kategori Analitik'),
          if (dashboard.isLoading.value)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (categories.isEmpty)
            const EmptyState(
              title: 'Belum ada analitik',
              message:
                  'Upload data yang dibutuhkan agar ringkasan dan grafik bisa ditampilkan.',
            )
          else
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () {
                    Get.to(
                      () => AnalyticsDetailPage(
                        category: category,
                        role: role,
                      ),
                    );
                  },
                  child: AnalyticsCategoryCard(category: category),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class AnalyticsDetailPage extends StatelessWidget {
  const AnalyticsDetailPage({
    super.key,
    required this.category,
    required this.role,
  });

  final AnalyticsCategory category;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    if (role == UserRole.operational) {
      return _OperationalAnalyticsDetail(
        category: category,
        dashboard: dashboard,
      );
    }

    final ownerTitle = category.title.toLowerCase();

    if (ownerTitle == 'sales') {
      return _OwnerSalesAnalyticsDetail(
        category: category,
        dashboard: dashboard,
      );
    }

    if (ownerTitle == 'product') {
      return _OwnerProductAnalyticsDetail(
        category: category,
        dashboard: dashboard,
      );
    }
    if (ownerTitle == 'promotion') {
      return _OwnerPromotionAnalyticsDetail(
        category: category,
        dashboard: dashboard,
      );
    }
    if (ownerTitle == 'planning') {
      return _OwnerPlanningAnalyticsDetail(
        category: category,
        dashboard: dashboard,
      );
    }
    if (ownerTitle.contains('inventory')) {
      return _OwnerInventoryAnalyticsDetail(
        category: category,
        dashboard: dashboard,
      );
    }

    return _OwnerAnalyticsDetail(category: category, dashboard: dashboard);
  }
}

class _OwnerPlanningAnalyticsDetail extends StatelessWidget {
  const _OwnerPlanningAnalyticsDetail({
    required this.category,
    required this.dashboard,
  });

  final AnalyticsCategory category;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Analytics'),
      ),
      body: Obx(() {
        final forecastPoints = dashboard.ownerPlanningForecastChart.toList();
        final actualPoints = dashboard.ownerPlanningActualChart.toList();
        final errorPoints = dashboard.ownerPlanningErrorChart.toList();
        final accuracyPoints = dashboard.ownerPlanningChart.toList();
        final ranks = dashboard.ownerPlanningRanks.toList();

        final hasPlanningData = forecastPoints.isNotEmpty ||
            actualPoints.isNotEmpty ||
            accuracyPoints.isNotEmpty ||
            ranks.isNotEmpty;

        final forecastTotal = forecastPoints.fold<double>(
          0,
          (sum, point) => sum + point.value,
        );

        final actualTotal = actualPoints.fold<double>(
          0,
          (sum, point) => sum + point.value,
        );

        final gap = (actualTotal - forecastTotal).abs();

        final gapPercent = forecastTotal <= 0
            ? 0.0
            : ((gap / forecastTotal) * 100).clamp(0, 999).toDouble();

        final accuracyAverage = accuracyPoints.isEmpty
            ? 0.0
            : accuracyPoints.fold<double>(
                  0,
                  (sum, point) => sum + point.value,
                ) /
                accuracyPoints.length;

        final hasGap = forecastTotal > 0 && actualTotal > 0 && gapPercent > 0;

        return AppPage(
          children: [
            const _OwnerPlanningHeader(),
            if (!hasPlanningData)
              const EmptyState(
                title: 'Belum ada data planning',
                message:
                    'Upload data planning atau hasil forecast agar analitik prediksi bisa ditampilkan.',
              )
            else ...[
              _PlanningHeroCard(
                gapPercent: gapPercent,
                isLowerThanForecast: actualTotal < forecastTotal,
                hasGap: hasGap,
              ),
              const SizedBox(height: 16),
              _PlanningMetricGrid(
                accuracyAverage: accuracyAverage,
                gapPercent: gapPercent,
                actualTotal: actualTotal,
                gap: gap,
                hasForecastActual: forecastTotal > 0 && actualTotal > 0,
              ),
              const SectionHeader(title: 'Forecast vs Actual'),
              _ForecastActualLineCard(
                forecastPoints: forecastPoints,
                actualPoints: actualPoints,
              ),
              const SectionHeader(title: 'Forecast Error'),
              _ForecastErrorCard(points: errorPoints),
              const SectionHeader(title: 'Analisis Planning'),
              _PlanningAnalysisCard(
                gapPercent: gapPercent,
                accuracyAverage: accuracyAverage,
                isLowerThanForecast: actualTotal < forecastTotal,
                hasGap: hasGap,
                ranks: ranks,
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _OwnerPlanningHeader extends StatelessWidget {
  const _OwnerPlanningHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.tealMint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -28,
            child: Icon(
              Icons.timeline_rounded,
              size: 118,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.24)),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Planning Analytics',
                  style: AppText.title.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanningHeroCard extends StatelessWidget {
  const _PlanningHeroCard({
    required this.gapPercent,
    required this.isLowerThanForecast,
    required this.hasGap,
  });

  final double gapPercent;
  final bool isLowerThanForecast;
  final bool hasGap;

  @override
  Widget build(BuildContext context) {
    final status = !hasGap
        ? AppStatus.info
        : gapPercent >= 20
            ? AppStatus.critical
            : gapPercent >= 10
                ? AppStatus.warning
                : AppStatus.success;

    final style = statusStyle(status);

    final title = !hasGap
        ? 'Forecast belum bisa dibandingkan'
        : gapPercent >= 10
            ? 'Forecast meleset ${gapPercent.toStringAsFixed(0)}%'
            : 'Forecast cukup akurat';

    final message = !hasGap
        ? 'Data forecast dan actual belum lengkap untuk dibandingkan.'
        : isLowerThanForecast
            ? 'Penjualan actual lebih rendah dari prediksi pada periode ini.'
            : 'Penjualan actual lebih tinggi dari prediksi pada periode ini.';

    return Container(
      margin: const EdgeInsets.only(top: 18),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            status == AppStatus.critical
                ? AppColors.danger
                : status == AppStatus.warning
                    ? AppColors.warning
                    : AppColors.tealMint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: style.color.withOpacity(.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -26,
            child: Icon(
              Icons.insights_rounded,
              size: 108,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanningHeroBadge(
                label: 'Forecast Insight',
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppText.title.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppText.body.copyWith(
                  color: Colors.white.withOpacity(.88),
                  height: 1.45,
                ),
              ),
              if (hasGap) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.compare_arrows_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lihat Gap',
                        style: AppText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanningHeroBadge extends StatelessWidget {
  const _PlanningHeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _PlanningMetricGrid extends StatelessWidget {
  const _PlanningMetricGrid({
    required this.accuracyAverage,
    required this.gapPercent,
    required this.actualTotal,
    required this.gap,
    required this.hasForecastActual,
  });

  final double accuracyAverage;
  final double gapPercent;
  final double actualTotal;
  final double gap;
  final bool hasForecastActual;

  @override
  Widget build(BuildContext context) {
    final accuracyStatus = accuracyAverage >= 80
        ? AppStatus.success
        : accuracyAverage >= 60
            ? AppStatus.warning
            : AppStatus.critical;

    final gapStatus = gapPercent >= 20
        ? AppStatus.critical
        : gapPercent >= 10
            ? AppStatus.warning
            : AppStatus.success;

    final items = [
      _PlanningMetricCard(
        title: 'Forecast Accuracy',
        value: accuracyAverage > 0
            ? '${accuracyAverage.toStringAsFixed(0)}%'
            : '-',
        subtitle: accuracyAverage >= 80
            ? 'Akurat'
            : accuracyAverage >= 60
                ? 'Perlu dipantau'
                : 'Perlu evaluasi',
        status: accuracyStatus,
        icon: Icons.trending_up_rounded,
      ),
      _PlanningMetricCard(
        title: 'Forecast Error',
        value: hasForecastActual ? '${gapPercent.toStringAsFixed(0)}%' : '-',
        subtitle: hasForecastActual ? 'Selisih prediksi' : 'Belum lengkap',
        status: gapStatus,
        icon: Icons.warning_amber_rounded,
      ),
      _PlanningMetricCard(
        title: 'Actual Sales',
        value: actualTotal > 0 ? _formatPlanningCurrency(actualTotal) : '-',
        subtitle: 'Penjualan actual',
        status: AppStatus.info,
        icon: Icons.payments_rounded,
      ),
      _PlanningMetricCard(
        title: 'Planning Gap',
        value: gap > 0 ? _formatPlanningCurrency(gap) : '-',
        subtitle: gapPercent >= 10 ? 'High deviation' : 'Terkendali',
        status: gapStatus,
        icon: Icons.compare_arrows_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardHeight = width < 340
            ? 170.0
            : width < 380
                ? 160.0
                : 148.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: cardHeight,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) => items[index],
        );
      },
    );
  }
}

class _PlanningMetricCard extends StatelessWidget {
  const _PlanningMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.status,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final AppStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return AppCard(
      padding: EdgeInsets.all(isCompact ? 13 : 15),
      borderColor: style.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isCompact ? 34 : 38,
                height: isCompact ? 34 : 38,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: style.color,
                  size: isCompact ? 18 : 20,
                ),
              ),
              const Spacer(),
              _PlanningStatusBadge(
                label: subtitle,
                status: status,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 10.5 : 11,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppText.kpiNumber.copyWith(
                    fontSize: isCompact ? 24 : 28,
                    color: style.color,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningStatusBadge extends StatelessWidget {
  const _PlanningStatusBadge({
    required this.label,
    required this.status,
  });

  final String label;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Container(
      constraints: const BoxConstraints(maxWidth: 82),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(
          color: style.color,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

class _ForecastActualLineCard extends StatelessWidget {
  const _ForecastActualLineCard({
    required this.forecastPoints,
    required this.actualPoints,
  });

  final List<ChartPoint> forecastPoints;
  final List<ChartPoint> actualPoints;

  @override
  Widget build(BuildContext context) {
    final forecast = forecastPoints.where((point) => point.value > 0).toList();
    final actual = actualPoints.where((point) => point.value > 0).toList();

    if (forecast.isEmpty || actual.isEmpty) {
      return const EmptyState(
        title: 'Forecast vs Actual belum tersedia',
        message:
            'Grafik perbandingan akan tampil jika data forecasted_sales dan actual_sales tersedia.',
      );
    }

    final length =
        forecast.length < actual.length ? forecast.length : actual.length;
    final visibleForecast = forecast.take(length).toList();
    final visibleActual = actual.take(length).toList();

    final maxY = [
      ...visibleForecast.map((point) => point.value),
      ...visibleActual.map((point) => point.value),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Forecast vs Actual', style: AppText.sectionTitle),
              ),
              _LineLegend(
                color: AppColors.primary,
                label: 'Forecast',
              ),
              const SizedBox(width: 10),
              _LineLegend(
                color: AppColors.success,
                label: 'Actual',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Data performa ${length} periode terakhir',
            style: AppText.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 245,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 10 : maxY * 1.22,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final index = spot.x.toInt();

                        if (index < 0 || index >= length) return null;

                        final label = visibleForecast[index].label;
                        final series =
                            spot.barIndex == 0 ? 'Forecast' : 'Actual';

                        return LineTooltipItem(
                          '$label\n$series: ${_formatPlanningCompact(spot.y)}',
                          AppText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _shortPlanningMonth(visibleForecast[index].label),
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 2 : maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderSoft.withOpacity(.65),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < length; i++)
                        FlSpot(i.toDouble(), visibleForecast[i].value),
                    ],
                    isCurved: true,
                    curveSmoothness: .30,
                    barWidth: 4.2,
                    color: AppColors.primary,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(.20),
                          AppColors.primary.withOpacity(.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < length; i++)
                        FlSpot(i.toDouble(), visibleActual[i].value),
                    ],
                    isCurved: true,
                    curveSmoothness: .30,
                    barWidth: 3.6,
                    color: AppColors.success,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: const [8, 6],
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastErrorCard extends StatelessWidget {
  const _ForecastErrorCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).toList();

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'Forecast error belum tersedia',
        message:
            'Forecast error akan tampil setelah data forecast dan actual tersedia.',
      );
    }

    final chartPoints =
        visible.length > 8 ? visible.sublist(visible.length - 8) : visible;

    final maxValue = chartPoints
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Forecast Error by Month', style: AppText.sectionTitle),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxValue <= 0 ? 10 : maxValue * 1.22,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= chartPoints.length) {
                        return null;
                      }

                      return BarTooltipItem(
                        '${chartPoints[groupIndex].label}\nGap: ${_formatPlanningCompact(rod.toY)}',
                        AppText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= chartPoints.length) {
                          return const SizedBox.shrink();
                        }

                        final point = chartPoints[index];
                        final isHighest = point.value == maxValue;

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _shortPlanningMonth(point.label),
                            style: AppText.caption.copyWith(
                              color: isHighest
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue <= 0 ? 2 : maxValue / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderSoft.withOpacity(.65),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartPoints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  final isHighest = point.value == maxValue;
                  final color =
                      isHighest ? AppColors.danger : AppColors.warning;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: point.value,
                        width: 20,
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(.66),
                            color,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningAnalysisCard extends StatelessWidget {
  const _PlanningAnalysisCard({
    required this.gapPercent,
    required this.accuracyAverage,
    required this.isLowerThanForecast,
    required this.hasGap,
    required this.ranks,
  });

  final double gapPercent;
  final double accuracyAverage;
  final bool isLowerThanForecast;
  final bool hasGap;
  final List<RankItem> ranks;

  @override
  Widget build(BuildContext context) {
    final status = !hasGap
        ? AppStatus.info
        : gapPercent >= 20
            ? AppStatus.critical
            : gapPercent >= 10
                ? AppStatus.warning
                : AppStatus.success;

    final style = statusStyle(status);

    final title = !hasGap
        ? 'Data planning belum lengkap'
        : gapPercent >= 10
            ? 'Analisis Penyimpangan'
            : 'Forecast cukup stabil';

    final badge = !hasGap
        ? 'Info'
        : accuracyAverage >= 80
            ? 'Forecast Akurat'
            : gapPercent >= 20
                ? 'Gap Tinggi'
                : 'Evaluasi';

    final mainMessage = !hasGap
        ? 'Tambahkan data forecasted_sales dan actual_sales agar gap planning dapat dianalisis.'
        : isLowerThanForecast
            ? 'Actual sales lebih rendah dari forecast sebesar ${gapPercent.toStringAsFixed(0)}%. Evaluasi stok, promo, dan permintaan pasar untuk periode berikutnya.'
            : 'Actual sales lebih tinggi dari forecast sebesar ${gapPercent.toStringAsFixed(0)}%. Pastikan stok tersedia agar peluang penjualan tidak terlewat.';

    final rankText = ranks.isNotEmpty
        ? ' Area/periode yang perlu dipantau: ${ranks.first.title}.'
        : '';

    return AppCard(
      padding: const EdgeInsets.all(18),
      borderColor: style.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              style.icon,
              color: style.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.cardTitle.copyWith(fontSize: 16),
                      ),
                    ),
                    _PlanningStatusBadge(
                      label: badge,
                      status: status,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$mainMessage$rankText',
                  style: AppText.body.copyWith(
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineLegend extends StatelessWidget {
  const _LineLegend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _shortPlanningMonth(String label) {
  final trimmed = label.trim();

  if (trimmed.isEmpty) return '-';
  if (trimmed.length <= 3) return trimmed.toUpperCase();

  return trimmed.substring(0, 3).toUpperCase();
}

String _formatPlanningCurrency(double value) {
  if (value >= 1000000000) {
    return 'Rp${(value / 1000000000).toStringAsFixed(1)}B';
  }

  if (value >= 1000000) {
    return 'Rp${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return 'Rp${(value / 1000).toStringAsFixed(1)}K';
  }

  return 'Rp${value.toStringAsFixed(0)}';
}

String _formatPlanningCompact(double value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }

  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  return value.toStringAsFixed(0);
}

class _OwnerPromotionAnalyticsDetail extends StatelessWidget {
  const _OwnerPromotionAnalyticsDetail({
    required this.category,
    required this.dashboard,
  });

  final AnalyticsCategory category;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Analytics'),
      ),
      
      body: Obx(() {
        final promoChart = dashboard.ownerPromoChart.toList();
        final promoRanks = dashboard.ownerPromoRanks.toList();

        final hasPromoData = promoChart.isNotEmpty || promoRanks.isNotEmpty;

        final totalPromo =
            promoRanks.isNotEmpty ? promoRanks.length : promoChart.length;

        final totalRevenue = promoChart.fold<double>(
          0,
          (sum, point) => sum + point.value,
        );

        final bestPromo = promoRanks.isNotEmpty ? promoRanks.first : null;

        final promoRevenueText = totalRevenue > 0
            ? _formatPromoCurrency(totalRevenue)
            : bestPromo?.value ?? '-';

        return AppPage(
          children: [
            const _OwnerPromotionHeader(),
            const SizedBox(height: 16),
            if (!hasPromoData)
              const EmptyState(
                title: 'Belum ada analitik promo',
                message:
                    'Upload data promosi dan penjualan agar performa promo bisa ditampilkan.',
              )
            else ...[
              _PromotionMetricGrid(
                totalPromo: totalPromo,
                promoRevenue: promoRevenueText,
                bestPromo: bestPromo,
              ),
              const SectionHeader(title: 'Revenue by Promo'),
              if (promoChart.isNotEmpty)
                _PromotionRevenueChartCard(points: promoChart)
              else
                const EmptyState(
                  title: 'Revenue promo belum tersedia',
                  message:
                      'Grafik revenue promo akan tampil setelah data promo berhasil diproses.',
                ),
              if (bestPromo != null) ...[
                const SizedBox(height: 16),
                _PromotionInsightCard(bestPromo: bestPromo),
              ],
              if (promoChart.length >= 2) ...[
                const SectionHeader(title: 'Promotion Matrix'),
                _PromotionMatrixCard(points: promoChart),
              ],
              if (promoRanks.isNotEmpty) ...[
                const SectionHeader(title: 'Promo Insights'),
                _PromotionInsightList(items: promoRanks.take(4).toList()),
              ],
            ],
          ],
        );
      }),
    );
  }
}

class _OwnerPromotionHeader extends StatelessWidget {
  const _OwnerPromotionHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.tealMint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -28,
            child: Icon(
              Icons.local_offer_rounded,
              size: 118,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.24)),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Promotion Analytics',
                  style: AppText.title.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionMetricGrid extends StatelessWidget {
  const _PromotionMetricGrid({
    required this.totalPromo,
    required this.promoRevenue,
    required this.bestPromo,
  });

  final int totalPromo;
  final String promoRevenue;
  final RankItem? bestPromo;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _PromotionMetricCard(
        title: 'Total Promo',
        value: '$totalPromo',
        subtitle: 'Promo tercatat',
        status: AppStatus.info,
        icon: Icons.campaign_rounded,
      ),
      _PromotionMetricCard(
        title: 'Promo Revenue',
        value: promoRevenue,
        subtitle: 'Kontribusi promo',
        status: AppStatus.success,
        icon: Icons.payments_rounded,
        highlight: true,
      ),
      if (bestPromo != null)
        _PromotionMetricCard(
          title: 'Best Promo',
          value: bestPromo!.title,
          subtitle: bestPromo!.badge,
          status: AppStatus.warning,
          icon: Icons.emoji_events_rounded,
        ),
      if (bestPromo != null)
        _PromotionMetricCard(
          title: 'Top Revenue',
          value: bestPromo!.value,
          subtitle: bestPromo!.subtitle,
          status: AppStatus.info,
          icon: Icons.trending_up_rounded,
        ),
    ];

    final visibleItems = items.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardHeight = width < 340
            ? 178.0
            : width < 380
                ? 168.0
                : width < 430
                    ? 158.0
                    : 150.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: cardHeight,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) => visibleItems[index],
        );
      },
    );
  }
}

class _PromotionMetricCard extends StatelessWidget {
  const _PromotionMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.highlight = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final AppStatus status;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    if (highlight) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.20),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -18,
              child: Icon(
                icon,
                size: 82,
                color: Colors.white.withOpacity(.08),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white.withOpacity(.82), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: Colors.white.withOpacity(.82),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppText.kpiNumber.copyWith(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    color: Colors.white.withOpacity(.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: style.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: style.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: style.color, size: 19),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          _PromotionBadge(label: subtitle, status: status),
        ],
      ),
    );
  }
}

class _PromotionRevenueChartCard extends StatelessWidget {
  const _PromotionRevenueChartCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).take(8).toList();

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'Revenue promo belum tersedia',
        message: 'Belum ada nilai revenue promo yang bisa divisualisasikan.',
      );
    }

    final maxValue = visible
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenue by Promo', style: AppText.sectionTitle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Text(
                      'Top Promo',
                      style: AppText.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: maxValue <= 0 ? 10 : maxValue * 1.22,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= visible.length) {
                        return null;
                      }

                      return BarTooltipItem(
                        '${visible[groupIndex].label}\n${_formatPromoCompact(rod.toY)}',
                        AppText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= visible.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _shortPromoLabel(visible[index].label),
                            style: AppText.caption.copyWith(
                              color: index == 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: index == 0
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue <= 0 ? 2 : maxValue / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderSoft.withOpacity(.65),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: visible.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  final color = _promoColor(index);

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: point.value,
                        width: 20,
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(.70),
                            color,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _promoColor(int index) {
    if (index == 0) return AppColors.primary;
    if (index == 1) return AppColors.info;
    if (index == 2) return AppColors.tealMint;
    if (index == 3) return AppColors.warning;

    return AppColors.primary.withOpacity(.45);
  }
}

class _PromotionInsightCard extends StatelessWidget {
  const _PromotionInsightCard({required this.bestPromo});

  final RankItem bestPromo;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(AppStatus.success);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: style.color.withOpacity(.16)),
        boxShadow: [
          BoxShadow(
            color: style.color.withOpacity(.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: style.color.withOpacity(.28),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PromotionBadge(
                      label: 'Promo Efektif',
                      status: AppStatus.success,
                    ),
                    const Spacer(),
                    Text(
                      'Evaluasi',
                      style: AppText.caption.copyWith(
                        color: style.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${bestPromo.title} paling efektif',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(
                    color: style.color,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Promo ini memiliki kontribusi revenue tertinggi berdasarkan data yang tersedia.',
                  style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionMatrixCard extends StatelessWidget {
  const _PromotionMatrixCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).take(8).toList();

    if (visible.length < 2) {
      return const SizedBox.shrink();
    }

    final maxRevenue = visible
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Promotion Matrix', style: AppText.sectionTitle),
          const SizedBox(height: 4),
          Text(
            'Perbandingan ranking promo dengan kontribusi revenue.',
            style: AppText.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: ScatterChart(
              ScatterChartData(
                minX: 0,
                maxX: visible.length + 1,
                minY: 0,
                maxY: maxRevenue <= 0 ? 10 : maxRevenue * 1.22,
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchTooltipData: ScatterTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    getTooltipItems: (spot) {
                      final index = spot.x.toInt() - 1;

                      if (index < 0 || index >= visible.length) {
                        return null;
                      }

                      return ScatterTooltipItem(
                        '${visible[index].label}\n${_formatPromoCompact(spot.y)}',
                        textStyle: AppText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxRevenue <= 0 ? 2 : maxRevenue / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderSoft.withOpacity(.65),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: AppColors.borderSoft.withOpacity(.45),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index <= 0 || index > visible.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '#$index',
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                scatterSpots: visible.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;

                  return ScatterSpot(
                    (index + 1).toDouble(),
                    point.value,
                    dotPainter: FlDotCirclePainter(
                      radius: index == 0 ? 8 : 6,
                      color: index == 0
                          ? AppColors.primary
                          : AppColors.info.withOpacity(0.45),
                      strokeWidth: index == 0 ? 4 : 0,
                      strokeColor: index == 0
                          ? AppColors.primarySoft
                          : Colors.transparent,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MatrixLegend(
                color: AppColors.primary,
                label: 'Top Promo',
              ),
              const SizedBox(width: 16),
              _MatrixLegend(
                color: AppColors.info.withOpacity(.45),
                label: 'Promo Lain',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatrixLegend extends StatelessWidget {
  const _MatrixLegend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PromotionInsightList extends StatelessWidget {
  const _PromotionInsightList({required this.items});

  final List<RankItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        final index = entry.key;

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          borderColor:
              index == 0 ? AppColors.successSoft : AppColors.primarySoft,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: index == 0
                      ? AppColors.successSoft
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  index == 0
                      ? Icons.emoji_events_rounded
                      : Icons.local_offer_rounded,
                  color: index == 0 ? AppColors.success : AppColors.primary,
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
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PromotionBadge(
                label: index == 0 ? 'Best' : item.badge,
                status: index == 0
                    ? AppStatus.success
                    : _promotionStatusFromText(item.badge),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PromotionBadge extends StatelessWidget {
  const _PromotionBadge({
    required this.label,
    required this.status,
  });

  final String label;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(
          color: style.color,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

AppStatus _promotionStatusFromText(String value) {
  final text = value.toLowerCase();

  if (text.contains('efektif') ||
      text.contains('best') ||
      text.contains('top') ||
      text.contains('success')) {
    return AppStatus.success;
  }

  if (text.contains('cek') ||
      text.contains('evaluasi') ||
      text.contains('warning')) {
    return AppStatus.warning;
  }

  if (text.contains('rendah') ||
      text.contains('gagal') ||
      text.contains('critical')) {
    return AppStatus.critical;
  }

  return AppStatus.info;
}

String _shortPromoLabel(String label) {
  final trimmed = label.trim();

  if (trimmed.isEmpty) return '-';

  final words = trimmed.split(RegExp(r'\s+'));

  if (words.length == 1) {
    return trimmed.length <= 5 ? trimmed : trimmed.substring(0, 5);
  }

  return words
      .take(2)
      .map((word) => word.length <= 4 ? word : word.substring(0, 4))
      .join(' ');
}

String _formatPromoCurrency(double value) {
  if (value >= 1000000000) {
    return 'Rp ${(value / 1000000000).toStringAsFixed(1)}B';
  }

  if (value >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return 'Rp ${(value / 1000).toStringAsFixed(1)}K';
  }

  return 'Rp ${value.toStringAsFixed(0)}';
}

String _formatPromoCompact(double value) {
  if (value >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(1)}B';
  }

  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  return value.toStringAsFixed(0);
}

class _OwnerProductAnalyticsDetail extends StatelessWidget {
  const _OwnerProductAnalyticsDetail({
    required this.category,
    required this.dashboard,
  });

  final AnalyticsCategory category;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Analytics'),
      ),
      body: Obx(() {
        final topProducts = dashboard.ownerTopProducts.toList();
        final productChart = dashboard.ownerProductChart.toList();

        final hasProductData =
            topProducts.isNotEmpty || productChart.isNotEmpty;

        final totalRevenue = productChart.fold<double>(
          0,
          (sum, point) => sum + point.value,
        );

        final topProduct = topProducts.isNotEmpty ? topProducts.first : null;
        final highestRevenue = topProduct?.value;
        final topCategory = _topCategoryFrom(topProducts);

        return AppPage(
          children: [
            const _OwnerProductHeader(),
            if (!hasProductData)
              const EmptyState(
                title: 'Belum ada analitik produk',
                message:
                    'Upload data produk dan penjualan agar performa produk bisa ditampilkan.',
              )
            else ...[
              _ProductHeroCard(
                title: 'Total Revenue',
                value: totalRevenue > 0
                    ? _formatRupiah(totalRevenue)
                    : highestRevenue ?? '-',
                badge: productChart.isNotEmpty ? 'Data tersedia' : null,
              ),
              const SizedBox(height: 16),
              _ProductMetricGrid(
                topProduct: topProduct,
                productCount: topProducts.length,
                topCategory: topCategory,
              ),
              const SectionHeader(title: 'Top Performance'),
              _ProductPerformanceCard(
                title: 'Top 10 Performance',
                points: productChart,
              ),
              if (_categoryPointsFrom(topProducts).isNotEmpty) ...[
                const SectionHeader(title: 'Category Contribution'),
                _ProductCategoryContributionCard(
                  points: _categoryPointsFrom(topProducts),
                ),
              ],
              if (topProducts.isNotEmpty) ...[
                Row(
                  children: [
                    const Expanded(
                      child: SectionHeader(title: 'Product Insights'),
                    ),
                    Text(
                      'Top 3',
                      style: AppText.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                _ProductInsightList(
                  items: topProducts.take(3).toList(),
                ),
              ],
            ],
          ],
        );
      }),
    );
  }

  String? _topCategoryFrom(List<RankItem> items) {
    final counts = <String, int>{};

    for (final item in items) {
      final category = item.subtitle.trim();

      if (category.isEmpty || category == '-') continue;

      counts[category] = (counts[category] ?? 0) + 1;
    }

    if (counts.isEmpty) return null;

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.first.key;
  }

  List<ChartPoint> _categoryPointsFrom(List<RankItem> items) {
    final counts = <String, double>{};

    for (final item in items) {
      final category = item.subtitle.trim();

      if (category.isEmpty || category == '-') continue;

      counts[category] = (counts[category] ?? 0) + 1;
    }

    final points = counts.entries
        .map((entry) => ChartPoint(entry.key, entry.value))
        .toList();

    points.sort((a, b) => b.value.compareTo(a.value));

    return points.take(5).toList();
  }

  static String _formatRupiah(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }
}

class _OwnerProductHeader extends StatelessWidget {
  const _OwnerProductHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.tealMint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -28,
            child: Icon(
              Icons.category_rounded,
              size: 118,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.24)),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Product Analytics',
                  style: AppText.title.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductHeroCard extends StatelessWidget {
  const _ProductHeroCard({
    required this.title,
    required this.value,
    this.badge,
  });

  final String title;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.tealMint,
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
            right: -16,
            bottom: -24,
            child: Icon(
              Icons.paid_rounded,
              size: 108,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppText.caption.copyWith(
                  color: Colors.white.withOpacity(.78),
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 9),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppText.kpiNumber.copyWith(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        badge!,
                        style: AppText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductMetricGrid extends StatelessWidget {
  const _ProductMetricGrid({
    required this.topProduct,
    required this.productCount,
    required this.topCategory,
  });

  final RankItem? topProduct;
  final int productCount;
  final String? topCategory;

  @override
  Widget build(BuildContext context) {
    final items = <_ProductMetricItem>[
      if (topProduct != null)
        _ProductMetricItem(
          title: 'Top Product',
          value: topProduct!.title,
          badge: 'Top Seller',
          status: AppStatus.success,
          icon: Icons.star_rounded,
        ),
      if (topProduct != null)
        _ProductMetricItem(
          title: 'Highest Rev',
          value: topProduct!.value,
          badge: 'Revenue',
          status: AppStatus.info,
          icon: Icons.payments_rounded,
        ),
      if (productCount > 0)
        _ProductMetricItem(
          title: 'Produk Teratas',
          value: '$productCount Item',
          badge: 'Produk',
          status: AppStatus.warning,
          icon: Icons.category_rounded,
        ),
      if (topCategory != null)
        _ProductMetricItem(
          title: 'Top Category',
          value: topCategory!,
          badge: 'Kategori',
          status: AppStatus.success,
          icon: Icons.sell_rounded,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardHeight = width < 340
            ? 172.0
            : width < 380
                ? 164.0
                : width < 430
                    ? 156.0
                    : 148.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.take(4).length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: cardHeight,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) => items[index],
        );
      },
    );
  }
}

class _ProductMetricItem extends StatelessWidget {
  const _ProductMetricItem({
    required this.title,
    required this.value,
    required this.badge,
    required this.status,
    required this.icon,
  });

  final String title;
  final String value;
  final String badge;
  final AppStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: style.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: style.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: style.color,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _ColoredBadge(
            label: badge,
            status: status,
          ),
        ],
      ),
    );
  }
}

class _ProductPerformanceCard extends StatelessWidget {
  const _ProductPerformanceCard({
    required this.title,
    required this.points,
  });

  final String title;
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).take(10).toList();

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'Performance belum tersedia',
        message: 'Data performa produk akan tampil setelah sales tersedia.',
      );
    }

    final maxValue = visible
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppText.sectionTitle),
              const Spacer(),
              const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...visible.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            final progress = maxValue <= 0 ? 0.0 : point.value / maxValue;
            final color = index < 3 ? AppColors.primary : AppColors.info;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visible.length - 1 ? 0 : 15,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCompact(point.value),
                        style: AppText.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 9,
                          color: AppColors.borderSoft.withOpacity(.85),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                          child: Container(
                            height: 9,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(.70),
                                  color,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }
}

class _ProductCategoryContributionCard extends StatelessWidget {
  const _ProductCategoryContributionCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).toList();
    final total = visible.fold<double>(0, (sum, point) => sum + point.value);

    if (visible.isEmpty || total <= 0) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Contribution', style: AppText.sectionTitle),
          const SizedBox(height: 18),
          SizedBox(
            height: 172,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 48,
                          sectionsSpace: 4,
                          startDegreeOffset: -90,
                          sections: visible.asMap().entries.map((entry) {
                            final index = entry.key;
                            final point = entry.value;
                            final color = chartColorForLabel(
                              point.label,
                              index,
                            );

                            return PieChartSectionData(
                              value: point.value,
                              color: color,
                              radius: 30,
                              title: '',
                            );
                          }).toList(),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '100%',
                            style: AppText.kpiNumber.copyWith(
                              fontSize: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Kategori',
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Wrap(
                    runSpacing: 10,
                    children: visible.asMap().entries.map((entry) {
                      final index = entry.key;
                      final point = entry.value;
                      final color = chartColorForLabel(point.label, index);
                      final percent = total <= 0
                          ? 0
                          : ((point.value / total) * 100).round();

                      return SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                point.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: AppText.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInsightList extends StatelessWidget {
  const _ProductInsightList({required this.items});

  final List<RankItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return _ProductInsightTile(
          item: item,
          index: index + 1,
        );
      }).toList(),
    );
  }
}

class _ProductInsightTile extends StatelessWidget {
  const _ProductInsightTile({
    required this.item,
    required this.index,
  });

  final RankItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForText('${item.title} ${item.badge}');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: style.background,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  style.background,
                  AppColors.primarySoft.withOpacity(.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              index == 1
                  ? Icons.emoji_events_rounded
                  : Icons.shopping_bag_rounded,
              color: style.color,
              size: 23,
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
                  'Rev: ${item.value}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ColoredBadge(
            label: item.badge,
            status: _statusForBadge(item.badge),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  AppStatus _statusForBadge(String badge) {
    final value = badge.toLowerCase();

    if (value.contains('top') ||
        value.contains('seller') ||
        value.contains('laris')) {
      return AppStatus.success;
    }

    if (value.contains('slow') ||
        value.contains('return') ||
        value.contains('cek')) {
      return AppStatus.warning;
    }

    if (value.contains('critical') || value.contains('kritis')) {
      return AppStatus.critical;
    }

    return AppStatus.info;
  }
}

class _ColoredBadge extends StatelessWidget {
  const _ColoredBadge({
    required this.label,
    required this.status,
  });

  final String label;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(
          color: style.color,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _OwnerSalesAnalyticsDetail extends StatelessWidget {
  const _OwnerSalesAnalyticsDetail({
    required this.category,
    required this.dashboard,
  });

  final AnalyticsCategory category;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
      ),
      body: Obx(() {
        final revenueTrend = dashboard.ownerRevenueTrend.toList();
        final kpis = dashboard.ownerKpis.toList();
        final productRevenue = dashboard.ownerProductChart.toList();

        final monthlyRevenue = _findKpiValue(
          kpis,
          candidates: const [
            'Net Revenue',
            'Total Revenue',
            'Revenue',
            'Total Pendapatan',
          ],
        );

        final totalRevenue = _findKpi(kpis, const [
          'Total Revenue',
          'Revenue',
          'Total Pendapatan',
        ]);

        final netRevenue = _findKpi(kpis, const [
          'Net Revenue',
          'Pendapatan Bersih',
        ]);

        final profit = _findKpi(kpis, const [
          'Estimasi Profit',
          'Profit',
          'Estimated Profit',
        ]);

        final unitsSold = _findKpi(kpis, const [
          'Produk Terjual',
          'Units Sold',
          'Unit Terjual',
        ]);

        final hasSalesData = kpis.isNotEmpty || revenueTrend.isNotEmpty;

        return AppPage(
          children: [
            const _OwnerSalesHeader(),
            if (!hasSalesData)
              const EmptyState(
                title: 'Belum ada data sales',
                message:
                    'Upload data penjualan agar analitik revenue dan produk terjual bisa ditampilkan.',
              )
            else ...[
              _SalesHeroCard(
                title: 'Monthly Revenue',
                value: monthlyRevenue ?? '-',
                badge: revenueTrend.isNotEmpty ? 'Trend tersedia' : null,
              ),
              const SizedBox(height: 16),
              _SalesKpiGrid(
                totalRevenue: totalRevenue,
                netRevenue: netRevenue,
                profit: profit,
                unitsSold: unitsSold,
              ),
              const SectionHeader(title: 'Revenue Analysis'),
              _SalesRevenueAnalysisCard(
                points: revenueTrend,
              ),
              if (productRevenue.isNotEmpty) ...[
                const SectionHeader(title: 'Revenue by Product'),
                _SalesRevenueBarCard(
                  title: 'Revenue by Product',
                  points: productRevenue,
                ),
              ],
            ],
          ],
        );
      }),
    );
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

  String? _findKpiValue(
    List<KpiMetric> kpis, {
    required List<String> candidates,
  }) {
    return _findKpi(kpis, candidates)?.value;
  }
}

class _OwnerSalesHeader extends StatelessWidget {
  const _OwnerSalesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.tealMint,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -26,
            child: Icon(
              Icons.trending_up_rounded,
              size: 116,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.24)),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sales Analytics',
                  style: AppText.title.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesHeroCard extends StatelessWidget {
  const _SalesHeroCard({
    required this.title,
    required this.value,
    this.badge,
  });

  final String title;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
            bottom: -24,
            child: Icon(
              Icons.payments_rounded,
              size: 105,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppText.caption.copyWith(
                  color: Colors.white.withOpacity(.78),
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppText.kpiNumber.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        badge!,
                        style: AppText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesKpiGrid extends StatelessWidget {
  const _SalesKpiGrid({
    required this.totalRevenue,
    required this.netRevenue,
    required this.profit,
    required this.unitsSold,
  });

  final KpiMetric? totalRevenue;
  final KpiMetric? netRevenue;
  final KpiMetric? profit;
  final KpiMetric? unitsSold;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (totalRevenue != null)
        _SalesKpiItem(
          title: 'Total Revenue',
          value: totalRevenue!.value,
          badge: totalRevenue!.badge,
          status: AppStatus.info,
          icon: Icons.payments_rounded,
        ),
      if (netRevenue != null)
        _SalesKpiItem(
          title: 'Net Revenue',
          value: netRevenue!.value,
          badge: netRevenue!.badge,
          status: AppStatus.success,
          icon: Icons.account_balance_wallet_rounded,
        ),
      if (profit != null)
        _SalesKpiItem(
          title: 'Estimasi Profit',
          value: profit!.value,
          badge: profit!.badge,
          status: AppStatus.success,
          icon: Icons.trending_up_rounded,
        ),
      if (unitsSold != null)
        _SalesKpiItem(
          title: 'Units Sold',
          value: unitsSold!.value,
          badge: unitsSold!.badge,
          status: AppStatus.info,
          icon: Icons.shopping_bag_rounded,
        ),
    ];

    if (items.isEmpty) {
      return const EmptyState(
        title: 'KPI sales belum tersedia',
        message: 'KPI sales akan tampil setelah data penjualan tersedia.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 360;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.take(4).length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: isSmall ? 140 : 128,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) => items[index],
        );
      },
    );
  }
}

class _SalesKpiItem extends StatelessWidget {
  const _SalesKpiItem({
    required this.title,
    required this.value,
    required this.badge,
    required this.status,
    required this.icon,
  });

  final String title;
  final String value;
  final String badge;
  final AppStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: style.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(icon, size: 18, color: style.color),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.cardTitle.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          InsightBadge(label: badge, color: style.color),
        ],
      ),
    );
  }
}

class _SalesRevenueAnalysisCard extends StatelessWidget {
  const _SalesRevenueAnalysisCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).toList();

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'Revenue belum tersedia',
        message: 'Grafik revenue akan tampil setelah data penjualan tersedia.',
      );
    }

    final chartPoints =
        visible.length > 8 ? visible.sublist(visible.length - 8) : visible;

    final maxY = chartPoints
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenue Analysis', style: AppText.sectionTitle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _PeriodChip(label: '6 Mo', active: false),
                    _PeriodChip(label: 'Yearly', active: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 235,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 10 : maxY * 1.22,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final index = spot.x.toInt();

                        if (index < 0 || index >= chartPoints.length) {
                          return null;
                        }

                        return LineTooltipItem(
                          '${chartPoints[index].label}\n${spot.y.toStringAsFixed(0)}',
                          AppText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= chartPoints.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _shortMonth(chartPoints[index].label),
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 2 : maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderSoft.withOpacity(.75),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < chartPoints.length; i++)
                        FlSpot(i.toDouble(), chartPoints[i].value),
                    ],
                    isCurved: true,
                    curveSmoothness: .28,
                    barWidth: 4.2,
                    color: AppColors.primary,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(.26),
                          AppColors.primary.withOpacity(.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortMonth(String label) {
    final trimmed = label.trim();

    if (trimmed.length <= 3) return trimmed.toUpperCase();

    return trimmed.substring(0, 3).toUpperCase();
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: active ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SalesRevenueBarCard extends StatelessWidget {
  const _SalesRevenueBarCard({
    required this.title,
    required this.points,
  });

  final String title;
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).take(5).toList();

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = visible
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.sectionTitle),
          const SizedBox(height: 18),
          ...visible.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            final progress = maxValue <= 0 ? 0.0 : point.value / maxValue;
            final color = _colorForIndex(index);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visible.length - 1 ? 0 : 18,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.cardTitle.copyWith(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        point.value.toStringAsFixed(0),
                        style: AppText.cardTitle.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 10,
                          color: AppColors.borderSoft.withOpacity(.85),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(.72),
                                  color,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _colorForIndex(int index) {
    const colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.tealMint,
      AppColors.warning,
      AppColors.success,
    ];

    return colors[index % colors.length];
  }
}

class _OwnerInventoryAnalyticsDetail extends StatelessWidget {
  const _OwnerInventoryAnalyticsDetail({
    required this.category,
    required this.dashboard,
  });

  final AnalyticsCategory category;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Obx(() {
        final criticalItems = dashboard.ownerCriticalStockItems.toList();
        final restockItems = dashboard.ownerRestockPriority.toList();
        final overstockItems = dashboard.ownerOverstockItems.toList();

        final hasIssue = criticalItems.isNotEmpty ||
            restockItems.isNotEmpty ||
            overstockItems.isNotEmpty;

        return AppPage(
          children: [
            const _OwnerInventoryHeader(
              title: 'Inventory',
              subtitle: 'Pantau kondisi stok dan prioritas restock.',
            ),
            const SizedBox(height: 14),
            _OwnerInventoryAlertCard(
              title: hasIssue
                  ? 'Ada stok yang perlu diperiksa'
                  : 'Stok dalam kondisi aman',
              message: hasIssue
                  ? 'Beberapa produk memiliki stok kritis, perlu restock, atau stok berlebih.'
                  : 'Tidak ada stok kritis, prioritas restock, atau stok berlebih saat ini.',
              status: hasIssue ? AppStatus.warning : AppStatus.success,
            ),
            const SizedBox(height: 14),
            _OwnerInventoryMetricCard(
              title: 'Stok Kritis',
              value: '${criticalItems.length}',
              suffix: 'produk',
              caption: 'Perlu segera dicek',
              status: AppStatus.critical,
              icon: Icons.warning_amber_rounded,
            ),
            _OwnerInventoryMetricCard(
              title: 'Prioritas Restock',
              value: '${restockItems.length}',
              suffix: 'produk',
              caption: 'Perlu ditambah',
              status: AppStatus.warning,
              icon: Icons.shopping_cart_checkout_rounded,
            ),
            _OwnerInventoryMetricCard(
              title: 'Stok Berlebih',
              value: '${overstockItems.length}',
              suffix: 'produk',
              caption: 'Stok terlalu tinggi',
              status: AppStatus.success,
              icon: Icons.inventory_2_rounded,
            ),
            const SizedBox(height: 8),
            _OwnerStockStatusCard(
              points: dashboard.ownerStockStatusChart.toList(),
            ),
            const SizedBox(height: 12),
            _OwnerStockProductCard(
              points: dashboard.ownerInventoryChart.toList(),
            ),
            const SectionHeader(title: 'Daftar Tindakan'),
            if (!hasIssue)
              const EmptyState(
                title: 'Tidak ada tindakan stok',
                message:
                    'Inventory dalam kondisi aman berdasarkan data yang tersedia.',
              )
            else ...[
              if (criticalItems.isNotEmpty)
                _OwnerInventoryActionSection(
                  title: 'Stok Kritis',
                  icon: Icons.priority_high_rounded,
                  status: AppStatus.critical,
                  items: criticalItems,
                  badgeLabel: 'Kritis',
                ),
              if (restockItems.isNotEmpty)
                _OwnerInventoryActionSection(
                  title: 'Prioritas Restock',
                  icon: Icons.shopping_cart_checkout_rounded,
                  status: AppStatus.warning,
                  items: restockItems,
                  badgeLabel: 'Restock',
                ),
              if (overstockItems.isNotEmpty)
                _OwnerInventoryActionSection(
                  title: 'Stok Berlebih',
                  icon: Icons.inventory_2_outlined,
                  status: AppStatus.success,
                  items: overstockItems,
                  badgeLabel: 'Berlebih',
                ),
            ],
          ],
        );
      }),
    );
  }
}

class _OwnerInventoryHeader extends StatelessWidget {
  const _OwnerInventoryHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFF1F7C66),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -28,
            child: Icon(
              Icons.inventory_2_rounded,
              size: 118,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  title,
                  style: AppText.title.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                subtitle,
                style: AppText.body.copyWith(
                  color: Colors.white.withOpacity(.84),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerInventoryAlertCard extends StatelessWidget {
  const _OwnerInventoryAlertCard({
    required this.title,
    required this.message,
    required this.status,
  });

  final String title;
  final String message;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: style.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: style.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              style.icon,
              color: style.color,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.cardTitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppText.body.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerInventoryMetricCard extends StatelessWidget {
  const _OwnerInventoryMetricCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.caption,
    required this.status,
    required this.icon,
  });

  final String title;
  final String value;
  final String suffix;
  final String caption;
  final AppStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: style.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 82),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: style.color,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      value,
                                      style: AppText.kpiNumber.copyWith(
                                        fontSize: 30,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(
                                    suffix,
                                    style: AppText.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerStockStatusCard extends StatelessWidget {
  const _OwnerStockStatusCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).toList();

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'Status stok belum tersedia',
        message: 'Status stok akan tampil setelah data inventory tersedia.',
      );
    }

    return StatusDonutCard(
      title: 'Status Stok',
      points: visible,
      emptyTitle: 'Status stok belum tersedia',
      emptyMessage: 'Status stok akan tampil setelah data inventory tersedia.',
      centerLabel: 'TOTAL SKU',
    );
  }
}

class _OwnerStockProductCard extends StatelessWidget {
  const _OwnerStockProductCard({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.where((point) => point.value > 0).take(6).toList();

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'Stok produk belum tersedia',
        message: 'Data stok produk akan tampil setelah inventory tersedia.',
      );
    }

    final maxValue = visible
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stok Produk', style: AppText.sectionTitle),
          const SizedBox(height: 16),
          ...visible.map((point) {
            final progress = maxValue <= 0 ? 0.0 : point.value / maxValue;
            final color = _barColor(progress);

            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${point.value.toStringAsFixed(0)} stok',
                        style: AppText.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          color: AppColors.borderSoft.withOpacity(.9),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                          child: Container(
                            height: 8,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _barColor(double progress) {
    if (progress >= .65) return AppColors.primary;
    if (progress >= .35) return AppColors.warning;
    return AppColors.danger;
  }
}

class _OwnerInventoryActionSection extends StatelessWidget {
  const _OwnerInventoryActionSection({
    required this.title,
    required this.icon,
    required this.status,
    required this.items,
    required this.badgeLabel,
  });

  final String title;
  final IconData icon;
  final AppStatus status;
  final List<RankItem> items;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: style.color, size: 18),
              const SizedBox(width: 7),
              Text(
                title,
                style: AppText.cardTitle.copyWith(color: style.color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.take(4).map(
                (item) => _OwnerInventoryActionTile(
                  item: item,
                  status: status,
                  badgeLabel: badgeLabel,
                ),
              ),
        ],
      ),
    );
  }
}

class _OwnerInventoryActionTile extends StatelessWidget {
  const _OwnerInventoryActionTile({
    required this.item,
    required this.status,
    required this.badgeLabel,
  });

  final RankItem item;
  final AppStatus status;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: style.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 46),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.cardTitle,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${item.value} • ${item.subtitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InsightBadge(
                      label: badgeLabel,
                      color: style.color,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            OPERATIONAL ANALYTICS                           */
/* -------------------------------------------------------------------------- */

class _OperationalAnalyticsDetail extends StatelessWidget {
  const _OperationalAnalyticsDetail({
    required this.category,
    required this.dashboard,
  });

  final AnalyticsCategory category;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    final title = category.title.toLowerCase();

    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: AppPage(
        children: [
          GradientHeader(
            title: category.title,
            subtitle: category.subtitle,
            badge: category.badge,
            icon: category.icon,
          ),
          Obx(() {
            return _InsightHeroCard(
              title: _mainInsightTitle(title),
              message: _mainInsightMessage(title),
              badge: category.badge,
              icon: category.icon,
            );
          }),
          const SizedBox(height: 14),
          _OperationalMetricGrid(title: title, dashboard: dashboard),
          const SectionHeader(title: 'Ringkasan Visual'),
          Obx(() {
            return _buildMainVisual(title);
          }),
          const SectionHeader(title: 'Daftar Tindakan'),
          Obx(() {
            return _buildActionList(title);
          }),
        ],
      ),
    );
  }

  String _mainInsightTitle(String title) {
    if (title == 'inventory') {
      final critical = _kpiValue('Stok Kritis');
      final restock = _kpiValue('Restock Priority');
      final overstock = _kpiValue('Overstock');

      if (critical == '0' && restock == '0' && overstock == '0') {
        return 'Stok dalam kondisi aman';
      }

      if (critical != '0' && critical != '-') {
        return 'Ada stok kritis yang perlu dicek';
      }

      if (restock != '0' && restock != '-') {
        return 'Ada produk yang perlu diprioritaskan';
      }

      if (overstock != '0' && overstock != '-') {
        return 'Ada stok berlebih yang perlu dievaluasi';
      }

      return 'Pantau kondisi stok';
    }

    if (title == 'product movement') {
      final fast = dashboard.fastMovingProducts.length;
      final slow = dashboard.slowMovingProducts.length;

      if (fast == 0 && slow == 0) return 'Pergerakan produk belum terlihat';
      if (slow > 0) return 'Ada produk yang pergerakannya lambat';

      return 'Produk cepat bergerak sudah terdeteksi';
    }

    if (title == 'logistics') {
      final delay = _kpiValue('Delay Risk');

      if (delay == '0') return 'Pengiriman berjalan aman';
      if (delay == '-') return 'Data pengiriman belum tersedia';

      return 'Ada pengiriman yang perlu dicek';
    }

    return 'Ringkasan analitik';
  }

  String _mainInsightMessage(String title) {
    if (title == 'inventory') {
      final critical = _kpiValue('Stok Kritis');
      final restock = _kpiValue('Restock Priority');
      final overstock = _kpiValue('Overstock');

      if (critical == '0' && restock == '0' && overstock == '0') {
        return 'Tidak ada stok kritis, prioritas restock, atau stok berlebih yang perlu ditindaklanjuti saat ini.';
      }

      return 'Terdapat $critical stok kritis, $restock prioritas restock, dan $overstock stok berlebih. Cek daftar tindakan untuk menentukan langkah berikutnya.';
    }

    if (title == 'product movement') {
      final fast = dashboard.fastMovingProducts.length;
      final slow = dashboard.slowMovingProducts.length;

      if (fast == 0 && slow == 0) {
        return 'Belum ada pergerakan produk yang bisa dibandingkan. Pastikan data Sales dan Product sudah tersedia.';
      }

      return 'Terdapat $fast produk cepat bergerak dan $slow produk lambat bergerak. Produk lambat perlu dicek untuk evaluasi stok atau promosi.';
    }

    if (title == 'logistics') {
      final delay = _kpiValue('Delay Risk');
      final issues = dashboard.logisticsIssues.length;

      if (delay == '0' && issues == 0) {
        return 'Tidak ada pengiriman bermasalah saat ini. Pengiriman masih dalam kondisi aman.';
      }

      if (delay == '-') {
        return 'Upload data Logistic agar kondisi pengiriman bisa ditampilkan.';
      }

      return 'Terdapat $delay risiko keterlambatan dan $issues catatan pengiriman yang perlu dicek.';
    }

    return 'Ringkasan ini membantu melihat kondisi utama dari data yang tersedia.';
  }

  String _kpiValue(String title) {
    for (final kpi in dashboard.operationalKpis) {
      if (kpi.title.toLowerCase() == title.toLowerCase()) {
        return kpi.value;
      }
    }

    return '-';
  }

  String _movementSuggestionText(int fastCount, int slowCount) {
    if (fastCount == 0 && slowCount == 0) {
      return 'Data pergerakan produk belum tersedia.';
    }

    if (slowCount == 0) {
      return 'Pastikan stok produk fast moving tetap tersedia agar penjualan tidak terganggu.';
    }

    if (fastCount == 0) {
      return 'Fokus evaluasi pada produk slow moving dari sisi promosi, harga, dan kebutuhan stok.';
    }

    return 'Pastikan stok produk fast moving tetap tersedia. Untuk produk slow moving, cek kembali kebutuhan promosi, harga, atau jumlah stok.';
  }

  String _inventorySuggestionText(
    int criticalCount,
    int restockCount,
    int overstockCount,
  ) {
    if (criticalCount == 0 && restockCount == 0 && overstockCount == 0) {
      return 'Kondisi stok aman. Tetap pantau produk dengan penjualan tinggi agar stok tidak cepat menipis.';
    }

    if (criticalCount > 0) {
      return 'Prioritaskan pengecekan stok kritis terlebih dahulu. Setelah itu lanjutkan restock untuk produk prioritas dan evaluasi stok berlebih.';
    }

    if (restockCount > 0) {
      return 'Fokus pada produk dengan prioritas restock agar ketersediaan barang tetap terjaga.';
    }

    return 'Evaluasi stok berlebih dari sisi permintaan, promosi, dan jumlah pembelian berikutnya.';
  }

  String _logisticsSuggestionText(int issueCount) {
    if (issueCount == 0) {
      return 'Pengiriman berjalan aman. Tetap pantau status pengiriman secara berkala.';
    }

    return 'Cek pengiriman yang terlambat atau dibatalkan. Prioritaskan rute, jenis transportasi, atau status dengan jumlah isu paling tinggi.';
  }

  Widget _buildMainVisual(String title) {
    if (title == 'inventory') {
      final statusPoints = dashboard.operationalStockStatusChart.toList();
      final stockPoints = dashboard.operationalInventoryChart.toList();

      return Column(
        children: [
          _DonutSummaryCard(
            title: 'Status Stok Keseluruhan',
            points: statusPoints,
            emptyMessage: 'Belum ada status stok yang bisa ditampilkan.',
          ),
          const SizedBox(height: 12),
          _HorizontalBarCard(
            title: 'Stok Produk',
            points: stockPoints,
            valueSuffix: ' stok',
            emptyMessage: 'Belum ada data stok produk.',
            semanticStyle: _BarSemanticStyle.inventory,
          ),
        ],
      );
    }

    if (title == 'product movement') {
      final points = dashboard.operationalProductChart.toList();

      return Column(
        children: [
          _HorizontalBarCard(
            title: 'Produk dengan Penjualan Tertinggi',
            points: points,
            valueSuffix: ' unit',
            emptyMessage:
                'Belum ada data pergerakan produk. Upload Sales dan Product terlebih dahulu.',
            semanticStyle: _BarSemanticStyle.productMovement,
          ),
        ],
      );
    }

    if (title == 'logistics') {
      final statusPoints = dashboard.operationalLogisticStatusChart.toList();
      final delayPoints = dashboard.operationalLogisticsChart.toList();

      return Column(
        children: [
          _DonutSummaryCard(
            title: 'Status Pengiriman',
            points: statusPoints,
            emptyMessage: 'Belum ada status pengiriman yang bisa ditampilkan.',
          ),
          const SizedBox(height: 12),
          _HorizontalBarCard(
            title: 'Delay Berdasarkan Transportasi',
            points: delayPoints,
            valueSuffix: ' delay',
            emptyMessage: 'Tidak ada keterlambatan yang tercatat.',
            semanticStyle: _BarSemanticStyle.logistics,
          ),
        ],
      );
    }

    return const EmptyState(
      title: 'Grafik belum tersedia',
      message: 'Belum ada data yang cukup untuk kategori ini.',
    );
  }

  Widget _buildActionList(String title) {
    if (title == 'inventory') {
      final criticalItems = dashboard.criticalStockItems.toList();
      final restockItems = dashboard.restockPriority.toList();
      final overstockItems = dashboard.overstockItems.toList();

      if (criticalItems.isEmpty &&
          restockItems.isEmpty &&
          overstockItems.isEmpty) {
        return const EmptyState(
          title: 'Stok dalam kondisi aman',
          message:
              'Tidak ada stok kritis, restock prioritas, atau stok berlebih yang perlu ditindaklanjuti saat ini.',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (criticalItems.isNotEmpty)
            _AnalysisSectionBlock(
              title: 'Stok Kritis',
              subtitle:
                  'Produk dengan stok sangat rendah atau habis dan perlu dicek segera.',
              badgeLabel: 'Kritis',
              items: criticalItems,
              status: AppStatus.critical,
              icon: Icons.warning_amber_rounded,
            ),
          if (restockItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AnalysisSectionBlock(
              title: 'Prioritas Restock',
              subtitle:
                  'Produk yang perlu diprioritaskan untuk pengadaan atau pengisian ulang stok.',
              badgeLabel: 'Restock',
              items: restockItems,
              status: AppStatus.warning,
              icon: Icons.playlist_add_check_rounded,
            ),
          ],
          if (overstockItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AnalysisSectionBlock(
              title: 'Stok Berlebih',
              subtitle:
                  'Produk dengan stok tinggi yang perlu dievaluasi agar tidak menumpuk terlalu lama.',
              badgeLabel: 'Overstock',
              items: overstockItems,
              status: AppStatus.success,
              icon: Icons.inventory_2_rounded,
            ),
          ],
          const SizedBox(height: 18),
          _ActionSuggestionCard(
            title: 'Saran Tindakan',
            message: _inventorySuggestionText(
              criticalItems.length,
              restockItems.length,
              overstockItems.length,
            ),
          ),
        ],
      );
    }

    if (title == 'product movement') {
      final fast = dashboard.fastMovingProducts.toList();
      final slow = dashboard.slowMovingProducts.toList();

      if (fast.isEmpty && slow.isEmpty) {
        return const EmptyState(
          title: 'Belum ada pergerakan produk',
          message:
              'Upload data Sales dan Product agar produk cepat dan lambat bergerak bisa dianalisis.',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fast.isNotEmpty)
            _AnalysisSectionBlock(
              title: 'Produk Cepat Bergerak',
              subtitle:
                  'Produk dengan penjualan tinggi dan perlu dijaga ketersediaannya.',
              badgeLabel: 'Fast Moving',
              items: fast,
              status: AppStatus.success,
              icon: Icons.flash_on_rounded,
            ),
          if (slow.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AnalysisSectionBlock(
              title: 'Produk Lambat Bergerak',
              subtitle:
                  'Produk yang perlu dievaluasi dari sisi promosi atau stok.',
              badgeLabel: 'Slow Moving',
              items: slow,
              status: AppStatus.warning,
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: 18),
          _ActionSuggestionCard(
            title: 'Saran Tindakan',
            message: _movementSuggestionText(fast.length, slow.length),
          ),
        ],
      );
    }

    if (title == 'logistics') {
      final items = dashboard.logisticsIssues.toList();
      final delayItems = items
          .where((item) => item.badge.toLowerCase().contains('delay'))
          .toList();
      final cancelledItems = items
          .where((item) => item.badge.toLowerCase().contains('cancel'))
          .toList();

      if (items.isEmpty) {
        return const EmptyState(
          title: 'Pengiriman berjalan aman',
          message:
              'Tidak ada pengiriman delay atau cancelled yang perlu ditindaklanjuti saat ini.',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (delayItems.isNotEmpty)
            _AnalysisSectionBlock(
              title: 'Pengiriman Terlambat',
              subtitle:
                  'Pengiriman dengan risiko keterlambatan yang perlu dipantau.',
              badgeLabel: 'Delay Risk',
              items: delayItems,
              status: AppStatus.warning,
              icon: Icons.local_shipping_rounded,
            ),
          if (cancelledItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AnalysisSectionBlock(
              title: 'Pengiriman Dibatalkan',
              subtitle:
                  'Pengiriman cancelled yang perlu dicek penyebab dan dampaknya.',
              badgeLabel: 'Cancelled',
              items: cancelledItems,
              status: AppStatus.critical,
              icon: Icons.cancel_outlined,
            ),
          ],
          const SizedBox(height: 18),
          _ActionSuggestionCard(
            title: 'Saran Tindakan',
            message: _logisticsSuggestionText(items.length),
          ),
        ],
      );
    }

    return const EmptyState(
      title: 'Data ringkas belum tersedia',
      message: 'Belum ada item yang bisa ditampilkan.',
    );
  }
}

class _OwnerAnalyticsDetail extends StatelessWidget {
  const _OwnerAnalyticsDetail({
    required this.category,
    required this.dashboard,
  });

  final AnalyticsCategory category;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    final title = category.title.toLowerCase();

    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: AppPage(
        children: [
          GradientHeader(
            title: category.title,
            subtitle: category.subtitle,
            badge: category.badge,
            icon: category.icon,
          ),
          _MetricSummaryCard(category: category),
          const SectionHeader(title: 'Grafik Utama'),
          Obx(() {
            return _buildOwnerVisual(title);
          }),
          const SectionHeader(title: 'Data Ringkas'),
          _buildOwnerListSection(title),
        ],
      ),
    );
  }

  Widget _buildOwnerVisual(String title) {
    if (title == 'sales') {
      return LineChartCard(
        title: 'Revenue Bulanan',
        points: dashboard.ownerRevenueTrend.toList(),
      );
    }

    if (title == 'product') {
      return _HorizontalBarCard(
        title: 'Kontribusi Produk',
        points: dashboard.ownerProductChart.toList(),
        valueSuffix: '',
        emptyMessage: 'Belum ada data produk yang bisa ditampilkan.',
        semanticStyle: _BarSemanticStyle.productMovement,
      );
    }

    if (title.contains('inventory')) {
      return _HorizontalBarCard(
        title: 'Stok Produk',
        points: dashboard.ownerInventoryChart.toList(),
        valueSuffix: ' stok',
        emptyMessage: 'Belum ada data stok yang bisa ditampilkan.',
        semanticStyle: _BarSemanticStyle.inventory,
      );
    }

    if (title == 'customer') {
      return _HorizontalBarCard(
        title: 'Customer Berdasarkan Nilai Pembelian',
        points: dashboard.ownerCustomerChart.toList(),
        valueSuffix: '',
        emptyMessage: 'Belum ada data customer.',
      );
    }

    if (title == 'promotion') {
      return _HorizontalBarCard(
        title: 'Revenue dari Promo',
        points: dashboard.ownerPromoChart.toList(),
        valueSuffix: '',
        emptyMessage: 'Belum ada data promo.',
      );
    }

    if (title == 'planning') {
      return LineChartCard(
        title: 'Akurasi Perencanaan',
        points: dashboard.ownerPlanningChart.toList(),
      );
    }

    return const EmptyState(
      title: 'Grafik belum tersedia',
      message: 'Belum ada data yang cukup.',
    );
  }

  Widget _buildOwnerListSection(String title) {
    if (title == 'product') {
      return Obx(() {
        return _PriorityList(
          items: dashboard.ownerTopProducts.toList(),
          ctaText: 'Lihat Detail',
        );
      });
    }

    if (title == 'customer') {
      return Obx(() {
        return _PriorityList(
          items: dashboard.ownerCustomerRanks.toList(),
          ctaText: 'Lihat Detail',
        );
      });
    }

    if (title == 'promotion') {
      return Obx(() {
        return _PriorityList(
          items: dashboard.ownerPromoRanks.toList(),
          ctaText: 'Lihat Detail',
        );
      });
    }

    if (title == 'planning') {
      return Obx(() {
        return _PriorityList(
          items: dashboard.ownerPlanningRanks.toList(),
          ctaText: 'Lihat Detail',
        );
      });
    }

    return const EmptyState(
      title: 'Data ringkas belum tersedia',
      message: 'Kategori ini menampilkan grafik utama.',
    );
  }
}

class _InsightHeroCard extends StatelessWidget {
  const _InsightHeroCard({
    required this.title,
    required this.message,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String message;
  final String badge;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForText('$title $badge');

    return AppCard(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      borderColor: style.background,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Icon(
              icon,
              size: 86,
              color: style.color.withOpacity(.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InsightBadge(label: badge, color: style.color),
              const SizedBox(height: 12),
              Text(title, style: AppText.title.copyWith(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppText.subtitle.copyWith(
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationalMetricGrid extends StatelessWidget {
  const _OperationalMetricGrid({required this.title, required this.dashboard});

  final String title;
  final DashboardController dashboard;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final kpis = dashboard.operationalKpis.toList();
      final width = MediaQuery.sizeOf(context).width;

      final cardHeight = width < 360
          ? 172.0
          : width < 410
              ? 162.0
              : 150.0;

      if (title == 'product movement') {
        final fastCount = dashboard.fastMovingProducts.length;
        final slowCount = dashboard.slowMovingProducts.length;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: width < 360 ? .82 : .92,
          children: [
            _AnalysisMetricCard(
              title: 'Fast Moving',
              value: '$fastCount',
              subtitle: 'Produk cepat terjual',
              status: AppStatus.success,
              icon: Icons.trending_up_rounded,
              badgeLabel: fastCount > 0 ? '+$fastCount' : '0',
            ),
            _AnalysisMetricCard(
              title: 'Slow Moving',
              value: '$slowCount',
              subtitle: 'Produk lambat bergerak',
              status: AppStatus.warning,
              icon: Icons.trending_down_rounded,
              badgeLabel: slowCount > 0 ? '$slowCount' : '0',
            ),
          ],
        );
      }

      List<KpiMetric> visible = [];

      if (title == 'inventory') {
        visible = kpis
            .where(
              (kpi) => [
                'Stok Kritis',
                'Restock Priority',
                'Overstock',
              ].contains(kpi.title),
            )
            .toList();
      } else if (title == 'logistics') {
        visible =
            kpis.where((kpi) => ['Delay Risk'].contains(kpi.title)).toList();
      }

      if (visible.isEmpty) return const SizedBox.shrink();

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: cardHeight,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, index) {
          final item = visible[index];
          final status = _statusForOperationalMetric(item.title, item.badge);

          return _AnalysisMetricCard(
            title: item.title,
            value: item.value,
            subtitle: _subtitleForOperationalMetric(item.title),
            status: status,
            icon: item.icon,
            badgeLabel: item.badge,
          );
        },
      );
    });
  }

  AppStatus _statusForOperationalMetric(String title, String badge) {
    final value = '$title $badge'.toLowerCase();

    if (value.contains('butuh')) return AppStatus.info;
    if (value.contains('aman')) return AppStatus.success;
    if (value.contains('kritis') || value.contains('cek')) {
      return AppStatus.critical;
    }
    if (value.contains('restock') ||
        value.contains('delay') ||
        value.contains('prioritaskan')) {
      return AppStatus.warning;
    }
    if (value.contains('overstock')) return AppStatus.success;

    return statusStyleForText(value).status;
  }

  String _subtitleForOperationalMetric(String title) {
    switch (title) {
      case 'Stok Kritis':
        return 'Produk perlu dicek';
      case 'Restock Priority':
        return 'Prioritas pengadaan';
      case 'Overstock':
        return 'Stok berlebih';
      case 'Delay Risk':
        return 'Pengiriman berisiko';
      default:
        return 'Ringkasan data';
    }
  }
}

class _MetricSummaryCard extends StatelessWidget {
  const _MetricSummaryCard({required this.category});

  final AnalyticsCategory category;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForText('${category.title} ${category.badge}');

    return AppCard(
      margin: const EdgeInsets.only(top: 16),
      borderColor: style.background,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(category.icon, color: style.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.title, style: AppText.cardTitle),
                const SizedBox(height: 4),
                Text(category.subtitle, style: AppText.small),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                category.metric,
                style: AppText.cardTitle.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 6),
              InsightBadge(label: category.badge, color: style.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutSummaryCard extends StatelessWidget {
  const _DonutSummaryCard({
    required this.title,
    required this.points,
    required this.emptyMessage,
  });

  final String title;
  final List<ChartPoint> points;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return StatusDonutCard(
      title: title,
      points: points,
      emptyTitle: 'Belum ada ringkasan',
      emptyMessage: emptyMessage,
      centerLabel: 'SEHAT',
    );
  }
}

enum _BarSemanticStyle {
  neutral,
  productMovement,
  inventory,
  logistics,
}

class _HorizontalBarCard extends StatelessWidget {
  const _HorizontalBarCard({
    required this.title,
    required this.points,
    required this.valueSuffix,
    required this.emptyMessage,
    this.semanticStyle = _BarSemanticStyle.neutral,
  });

  final String title;
  final List<ChartPoint> points;
  final String valueSuffix;
  final String emptyMessage;
  final _BarSemanticStyle semanticStyle;

  @override
  Widget build(BuildContext context) {
    final visiblePoints =
        points.where((point) => point.value > 0).take(8).toList();

    if (visiblePoints.isEmpty) {
      return EmptyState(title: title, message: emptyMessage);
    }

    final maxValue = visiblePoints
        .map((point) => point.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppText.cardTitle)),
            ],
          ),
          const SizedBox(height: 16),
          ...visiblePoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            final progress = maxValue <= 0 ? 0.0 : point.value / maxValue;

            final color = _resolveBarColor(point.label, index);
            final formattedValue = point.value >= 1000000
                ? '${(point.value / 1000000).toStringAsFixed(1)} jt'
                : point.value >= 1000
                    ? '${(point.value / 1000).toStringAsFixed(1)} rb'
                    : point.value.toStringAsFixed(0);

            return Container(
              margin: EdgeInsets.only(
                bottom: index == visiblePoints.length - 1 ? 0 : 12,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(.10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.label,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$formattedValue$valueSuffix',
                        style: AppText.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: Colors.white.withOpacity(.78),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(.72),
                                  color,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _resolveBarColor(String label, int index) {
    if (semanticStyle == _BarSemanticStyle.productMovement) {
      return AppColors.primary;
    }

    if (semanticStyle == _BarSemanticStyle.inventory) {
      return AppColors.tealMint;
    }

    if (semanticStyle == _BarSemanticStyle.logistics) {
      return AppColors.warning;
    }

    return chartColorForLabel(label, index);
  }
}

class _AnalysisMetricCard extends StatelessWidget {
  const _AnalysisMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.badgeLabel,
  });

  final String title;
  final String value;
  final String subtitle;
  final AppStatus status;
  final IconData icon;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;

    return AppCard(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      borderColor: style.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isCompact ? 34 : 38,
                    height: isCompact ? 34 : 38,
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: style.color,
                      size: isCompact ? 18 : 20,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InsightBadge(
                        label: badgeLabel,
                        color: style.color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 10 : 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sectionTitle.copyWith(
                  fontSize: isCompact ? 14 : 15,
                  height: 1.15,
                ),
              ),
              SizedBox(height: isCompact ? 6 : 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppText.kpiNumber.copyWith(
                    fontSize: isCompact ? 25 : 28,
                    height: 1,
                    color: style.color,
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 6 : 8),
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    fontSize: isCompact ? 10.5 : 11,
                    height: 1.25,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalysisSectionBlock extends StatelessWidget {
  const _AnalysisSectionBlock({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.items,
    required this.status,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final List<RankItem> items;
  final AppStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: style.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppText.sectionTitle.copyWith(
                  fontSize: 16,
                  color: style.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: AppText.body.copyWith(height: 1.4)),
        const SizedBox(height: 12),
        ...items.take(4).map(
              (item) => _AnalysisListCard(
                item: item,
                status: status,
                badgeLabel: badgeLabel,
              ),
            ),
      ],
    );
  }
}

class _AnalysisListCard extends StatelessWidget {
  const _AnalysisListCard({
    required this.item,
    required this.status,
    required this.badgeLabel,
  });

  final RankItem item;
  final AppStatus status;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: style.background),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 82,
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomLeft: Radius.circular(22),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, color: style.color, size: 20),
                  ),
                  const SizedBox(width: 12),
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
                        Text(item.value, style: AppText.body),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InsightBadge(label: badgeLabel, color: style.color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSuggestionCard extends StatelessWidget {
  const _ActionSuggestionCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.sectionTitle.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppText.body.copyWith(
                    color: Colors.white.withOpacity(.88),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityList extends StatelessWidget {
  const _PriorityList({required this.items, required this.ctaText});

  final List<RankItem> items;

  final String ctaText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        title: 'Belum ada item',
        message: 'Data akan tampil setelah tersedia.',
      );
    }

    return Column(
      children: [
        ...items.asMap().entries.map(
              (entry) => RankCard(item: entry.value, index: entry.key + 1),
            ),
      ],
    );
  }
}
