import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pantau_app/controllers/dashboard_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

enum AppStatus { critical, warning, success, info, neutral }

class AppStatusStyle {
  const AppStatusStyle({
    required this.status,
    required this.color,
    required this.background,
    required this.icon,
  });

  final AppStatus status;
  final Color color;
  final Color background;
  final IconData icon;
}

AppStatusStyle statusStyle(AppStatus status) {
  switch (status) {
    case AppStatus.critical:
      return const AppStatusStyle(
        status: AppStatus.critical,
        color: AppColors.danger,
        background: AppColors.dangerSoft,
        icon: Icons.warning_amber_rounded,
      );
    case AppStatus.warning:
      return const AppStatusStyle(
        status: AppStatus.warning,
        color: AppColors.warning,
        background: AppColors.warningSoft,
        icon: Icons.priority_high_rounded,
      );
    case AppStatus.success:
      return const AppStatusStyle(
        status: AppStatus.success,
        color: AppColors.success,
        background: AppColors.successSoft,
        icon: Icons.check_circle_outline_rounded,
      );
    case AppStatus.info:
      return const AppStatusStyle(
        status: AppStatus.info,
        color: AppColors.info,
        background: AppColors.infoSoft,
        icon: Icons.info_outline_rounded,
      );
    case AppStatus.neutral:
      return const AppStatusStyle(
        status: AppStatus.neutral,
        color: AppColors.textSecondary,
        background: AppColors.borderSoft,
        icon: Icons.circle_outlined,
      );
  }
}

AppStatusStyle statusStyleForText(String text) {
  final value = text.toLowerCase().replaceAll('_', ' ');

  if (value.contains('kritis') ||
      value.contains('critical') ||
      value.contains('out of stock') ||
      value.contains('cancel') ||
      value.contains('gagal')) {
    return statusStyle(AppStatus.critical);
  }

  if (value.contains('restock') ||
      value.contains('urgent') ||
      value.contains('high') ||
      value.contains('medium') ||
      value.contains('delay') ||
      value.contains('slow') ||
      value.contains('evaluasi') ||
      value.contains('cek') ||
      value.contains('butuh')) {
    return statusStyle(AppStatus.warning);
  }

  if (value.contains('aman') ||
      value.contains('safe') ||
      value.contains('normal') ||
      value.contains('success') ||
      value.contains('fast') ||
      value.contains('overstock') ||
      value.contains('lancar')) {
    return statusStyle(AppStatus.success);
  }

  if (value.contains('info') ||
      value.contains('movement') ||
      value.contains('trend') ||
      value.contains('produk') ||
      value.contains('customer') ||
      value.contains('promo') ||
      value.contains('data')) {
    return statusStyle(AppStatus.info);
  }

  return statusStyle(AppStatus.neutral);
}

Color chartColorForLabel(String label, int index) {
  final value = label.toLowerCase().replaceAll('_', ' ').trim();

  if (value.contains('aman') ||
      value.contains('safe') ||
      value.contains('normal')) {
    return AppColors.success;
  }

  if (value.contains('menipis') || value.contains('low stock')) {
    return AppColors.info;
  }

  if (value.contains('kritis') ||
      value.contains('critical') ||
      value.contains('out of stock')) {
    return AppColors.danger;
  }

  if (value.contains('overstock') || value.contains('stok berlebih')) {
    return AppColors.tealMint;
  }

  if (value.contains('lancar') ||
      value.contains('delivered') ||
      value.contains('success')) {
    return AppColors.success;
  }

  if (value.contains('delay') ||
      value.contains('delayed') ||
      value.contains('pending') ||
      value.contains('in transit')) {
    return AppColors.warning;
  }

  if (value.contains('cancel') ||
      value.contains('gagal') ||
      value.contains('failed')) {
    return AppColors.danger;
  }

  if (value.contains('fast') || value.contains('cepat')) {
    return AppColors.success;
  }

  if (value.contains('slow') || value.contains('lambat')) {
    return AppColors.warning;
  }

  if (value.contains('promo') || value.contains('customer')) {
    return AppColors.info;
  }

  const fallback = [
    AppColors.primary,
    AppColors.tealMint,
    AppColors.warning,
    AppColors.info,
    AppColors.success,
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  return fallback[index % fallback.length];
}

Color chartBackgroundForLabel(String label, int index) {
  return chartColorForLabel(label, index).withOpacity(.13);
}

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: children,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.radius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.borderSoft.withOpacity(.55),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(.045),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: content,
    );
  }
}

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.badge,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? badge;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.tealMint],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: AppText.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(title, style: AppText.title.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppText.body.copyWith(
                    color: Colors.white.withOpacity(.86),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.sectionTitle)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.metric});
  final KpiMetric metric;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForText('${metric.title} ${metric.badge}');
    final isEmpty = metric.value.trim() == '-';

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: style.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(metric.icon, color: style.color, size: 20),
              ),
              const Spacer(),
              InsightBadge(label: metric.badge),
            ],
          ),
          const Spacer(),
          Text(
            metric.title,
            style: AppText.caption.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: AppText.kpiNumber.copyWith(
              color: isEmpty ? AppColors.textTertiary : style.color,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: isEmpty ? 0 : .72,
              minHeight: 4,
              backgroundColor: AppColors.borderSoft,
              valueColor: AlwaysStoppedAnimation<Color>(style.color),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightBadge extends StatelessWidget {
  const InsightBadge({super.key, required this.label, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final inferred = statusStyleForText(label);
    final foreground = color ?? inferred.color;
    final background =
        color == null ? inferred.background : foreground.withOpacity(.13);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactAlertBanner extends StatelessWidget {
  const CompactAlertBanner({
    super.key,
    required this.title,
    required this.chips,
    required this.cta,
    this.onTap,
    this.message,
    this.status,
  });

  final String title;
  final List<String> chips;
  final String cta;
  final VoidCallback? onTap;
  final String? message;
  final AppStatus? status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(
      status ?? statusStyleForText('$title ${chips.join(' ')}').status,
    );

    return AppCard(
      color: style.background,
      borderColor: style.color.withOpacity(.18),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(style.icon, color: style.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(message!, style: AppText.small),
                ],
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        chips.map((chip) => InsightBadge(label: chip)).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap ??
                () {
                  Get.snackbar(
                    'Insight',
                    'Detail insight ditampilkan berdasarkan data yang tersedia.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}

class LineChartCard extends StatelessWidget {
  const LineChartCard({super.key, required this.title, required this.points});

  final String title;
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final visiblePoints = points.where((point) => point.value > 0).toList();

    if (visiblePoints.isEmpty) {
      return EmptyState(
        title: title,
        message: 'Belum ada data grafik dari database.',
      );
    }

    final maxY = visiblePoints
        .map((e) => e.value)
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
                  Icons.show_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppText.cardTitle)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 10 : maxY * 1.20,
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
                      showTitles: visiblePoints.length <= 8,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= visiblePoints.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            visiblePoints[index].label,
                            style: AppText.caption.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY <= 0 ? 2 : maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderSoft.withOpacity(.85),
                    strokeWidth: 1.2,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < visiblePoints.length; i++)
                        FlSpot(i.toDouble(), visiblePoints[i].value),
                    ],
                    isCurved: true,
                    curveSmoothness: .22,
                    barWidth: 4.6,
                    color: AppColors.primary,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4.2,
                          color: AppColors.card,
                          strokeWidth: 3,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(.13),
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
}

class StatusDonutCard extends StatelessWidget {
  const StatusDonutCard({
    super.key,
    required this.title,
    required this.points,
    required this.emptyTitle,
    required this.emptyMessage,
    this.centerLabel = 'SEHAT',
  });

  final String title;
  final List<ChartPoint> points;
  final String emptyTitle;
  final String emptyMessage;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final visiblePoints = points.where((point) => point.value > 0).toList();
    final total = visiblePoints.fold<double>(
      0,
      (sum, point) => sum + point.value,
    );

    if (total <= 0 || visiblePoints.isEmpty) {
      return EmptyState(title: emptyTitle, message: emptyMessage);
    }

    final safeValue = visiblePoints.where((point) {
      final label = point.label.toLowerCase();

      return label.contains('aman') ||
          label.contains('safe') ||
          label.contains('normal') ||
          label.contains('lancar') ||
          label.contains('delivered');
    }).fold<double>(0, (sum, point) => sum + point.value);

    final health = total <= 0 ? 0 : (safeValue / total) * 100;
    final centerValue = safeValue <= 0 ? total : health;
    final centerSuffix = safeValue <= 0 ? '' : '%';
    final resolvedCenterLabel = safeValue <= 0 ? 'TOTAL' : centerLabel;

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
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  color: AppColors.tealMint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppText.sectionTitle.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 46,
                        sectionsSpace: 4,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(enabled: true),
                        sections: visiblePoints.asMap().entries.map((entry) {
                          final color = chartColorForLabel(
                            entry.value.label,
                            entry.key,
                          );

                          final percentage = total <= 0
                              ? 0
                              : (entry.value.value / total) * 100;

                          return PieChartSectionData(
                            value: entry.value.value,
                            title: percentage >= 12
                                ? '${percentage.toStringAsFixed(0)}%'
                                : '',
                            titleStyle: AppText.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                            titlePositionPercentageOffset: .64,
                            radius: 31,
                            color: color,
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${centerValue.toStringAsFixed(0)}$centerSuffix',
                            style: AppText.cardTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            resolvedCenterLabel,
                            style: AppText.caption.copyWith(letterSpacing: .2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: visiblePoints.asMap().entries.map((entry) {
                    final point = entry.value;
                    final percentage =
                        total <= 0 ? 0 : (point.value / total) * 100;

                    final color = chartColorForLabel(point.label, entry.key);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
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
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: AppText.caption.copyWith(
                              color: color,
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
        ],
      ),
    );
  }
}

class RankCard extends StatelessWidget {
  const RankCard({
    super.key,
    required this.item,
    this.index,
    this.compact = false,
  });
  final RankItem item;
  final int? index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForText(
      '${item.badge} ${item.title} ${item.subtitle}',
    );

    return AppCard(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: EdgeInsets.all(compact ? 12 : 14),
      borderColor: style.background,
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: index == null
                  ? Icon(style.icon, color: style.color, size: 20)
                  : Text(
                      '$index',
                      style: AppText.cardTitle.copyWith(color: style.color),
                    ),
            ),
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
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.value, style: AppText.cardTitle.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              InsightBadge(label: item.badge),
            ],
          ),
        ],
      ),
    );
  }
}

class AnalyticsCategoryCard extends StatelessWidget {
  const AnalyticsCategoryCard({super.key, required this.category});
  final AnalyticsCategory category;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleForText('${category.title} ${category.badge}');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
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
                Text(category.subtitle, style: AppText.caption),
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
              InsightBadge(label: category.badge),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.message, this.action});
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.card,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppText.cardTitle, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: AppText.small, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class InlineEmptyState extends StatelessWidget {
  const InlineEmptyState({super.key, required this.title, this.message});
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withOpacity(.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(title, style: AppText.cardTitle, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: AppText.caption, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.dangerSoft,
      borderColor: AppColors.danger.withOpacity(.18),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppText.small.copyWith(color: AppColors.danger),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Ulangi')),
        ],
      ),
    );
  }
}

String formatDate(DateTime date) =>
    DateFormat('dd MMM yyyy', 'id_ID').format(date);

String _siteDisplayLabel(SiteOption site) {
  final name = site.siteName.trim().isEmpty ? 'Cabang' : site.siteName.trim();
  final format = site.siteFormat?.trim();

  return [
    name,
    if (format != null && format.isNotEmpty) format,
  ].join(' • ');
}

String _siteDisplaySubtitle(SiteOption site) {
  final city = site.city?.trim();
  final state = site.state?.trim();

  final location = [
    if (city != null && city.isNotEmpty) city,
    if (state != null && state.isNotEmpty) state,
  ].join(', ');

  if (location.isNotEmpty) return location;

  return site.siteId;
}

class SiteSelector extends StatelessWidget {
  const SiteSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    return Obx(() {
      final sites = dashboard.availableSites.toList();
      final selectedId = dashboard.selectedSiteId.value;

      if (sites.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 52,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          children: [
            _SiteChip(
              label: 'Global',
              isSelected: selectedId == null,
              onTap: dashboard.selectGlobalScope,
              icon: Icons.public_rounded,
            ),
            ...sites.map(
              (site) => _SiteChip(
                label: _siteDisplayLabel(site),
                isSelected: selectedId == site.siteId,
                onTap: () => dashboard.selectSiteScope(site.siteId),
                icon: Icons.storefront_rounded,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SiteChip extends StatelessWidget {
  const _SiteChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderSoft,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(.24),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SiteSelectorDropdown extends StatelessWidget {
  const SiteSelectorDropdown({super.key, this.darkMode = false});

  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    return Obx(() {
      final sites = dashboard.availableSites.toList();
      final selectedId = dashboard.selectedSiteId.value;

      if (sites.isEmpty) return const SizedBox.shrink();

      final selectedSite = selectedId == null
          ? null
          : sites.firstWhereOrNull((site) => site.siteId == selectedId);

      final label = selectedSite == null
          ? 'Semua Cabang'
          : _siteDisplayLabel(selectedSite);

      final borderColor =
          darkMode ? Colors.white.withOpacity(.28) : AppColors.borderSoft;
      final bgColor = darkMode ? Colors.white.withOpacity(.16) : AppColors.card;
      final textColor = darkMode ? Colors.white : AppColors.textPrimary;
      final iconColor = darkMode ? Colors.white : AppColors.textSecondary;
      final subtitleColor =
          darkMode ? Colors.white.withOpacity(.72) : AppColors.textSecondary;

      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showBottomSheet(
          context,
          dashboard,
          sites,
          selectedId,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedId == null
                    ? Icons.public_rounded
                    : Icons.storefront_rounded,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cabang',
                      style: AppText.caption.copyWith(
                        color: subtitleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.expand_more_rounded, size: 18, color: iconColor),
            ],
          ),
        ),
      );
    });
  }

  void _showBottomSheet(
    BuildContext context,
    DashboardController dashboard,
    List<SiteOption> sites,
    String? selectedId,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .78,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text('Filter Cabang', style: AppText.sectionTitle),
                const SizedBox(height: 6),
                Text(
                  'Pilih cabang untuk memfilter semua data dan grafik.',
                  style: AppText.small.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _SheetOption(
                        label: 'Semua Cabang',
                        subtitle: 'Tampilkan data dari semua lokasi',
                        icon: Icons.public_rounded,
                        isSelected: selectedId == null,
                        onTap: () {
                          Get.back();
                          dashboard.selectGlobalScope();
                        },
                      ),
                      ...sites.map(
                        (site) => _SheetOption(
                          label: _siteDisplayLabel(site),
                          subtitle: _siteDisplaySubtitle(site),
                          icon: Icons.storefront_rounded,
                          isSelected: selectedId == site.siteId,
                          onTap: () {
                            Get.back();
                            dashboard.selectSiteScope(site.siteId);
                          },
                        ),
                      ),
                    ],
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
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSoft,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(.15)
                    : AppColors.borderSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
