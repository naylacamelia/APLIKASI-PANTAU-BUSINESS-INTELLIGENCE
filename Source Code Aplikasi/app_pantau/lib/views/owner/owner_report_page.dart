import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../controllers/dashboard_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../shared/widgets.dart';

class OwnerReportPage extends StatefulWidget {
  const OwnerReportPage({super.key});

  @override
  State<OwnerReportPage> createState() => _OwnerReportPageState();
}

class _OwnerReportPageState extends State<OwnerReportPage> {
  String filter = 'Bulanan';

  final _currency = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );

  List<ChartPoint> _filteredTrend(DashboardController dashboard) {
    final points = dashboard.ownerRevenueTrend.toList();

    if (filter == 'Tahunan') {
      final total = points.fold<double>(0, (sum, item) => sum + item.value);

      return total <= 0 ? [] : [ChartPoint('Total', total)];
    }

    return points;
  }

  bool _hasReportData(DashboardController dashboard) {
    return dashboard.ownerKpis.isNotEmpty ||
        dashboard.ownerRevenueTrend.isNotEmpty ||
        dashboard.ownerTopProducts.isNotEmpty ||
        dashboard.ownerInsights.isNotEmpty;
  }

  PdfColor _pdfColor(String hex) {
    return PdfColor.fromHex(hex);
  }

  Future<Uint8List> _buildPdf(DashboardController dashboard) async {
    final pdf = pw.Document();

    final points = _filteredTrend(dashboard);
    final topProducts = dashboard.ownerTopProducts.take(8).toList();
    final insights = dashboard.ownerInsights.take(6).toList();

    final maxRevenue = points.isEmpty
        ? 1.0
        : points
              .map((point) => point.value)
              .fold<double>(0, (a, b) => a > b ? a : b);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) {
          return [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _pdfColor('#2F6BFF'),
                borderRadius: pw.BorderRadius.circular(18),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Laporan Pantau Retail',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Ringkasan performa bisnis Owner - Periode $filter',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 11),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Dibuat otomatis berdasarkan data bisnis retail yang tersedia di aplikasi.',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            pw.Text(
              'KPI Bisnis',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            if (dashboard.ownerKpis.isEmpty)
              _pdfEmptyCard('Belum ada KPI bisnis yang tersedia.')
            else
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: dashboard.ownerKpis.map((kpi) {
                  return pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: _pdfColor('#EAF1FF'),
                      borderRadius: pw.BorderRadius.circular(14),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          kpi.title,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _pdfColor('#6C7893'),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          kpi.value,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: _pdfColor('#1653E8'),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          kpi.badge,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: _pdfColor('#1F2A44'),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            pw.SizedBox(height: 22),

            pw.Text(
              filter == 'Tahunan' ? 'Total Revenue Tahunan' : 'Revenue Bulanan',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.Container(
              width: double.infinity,
              height: 210,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _pdfColor('#F6F8FC'),
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: _pdfColor('#E8ECF4')),
              ),
              child: points.isEmpty
                  ? pw.Center(
                      child: pw.Text(
                        'Data revenue belum tersedia.',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    )
                  : pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: points.map((point) {
                        final height = maxRevenue <= 0
                            ? 0.0
                            : (point.value / maxRevenue) * 135;

                        return pw.Expanded(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                _currency.format(point.value),
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Container(
                                height: height < 5 ? 5 : height,
                                width: 22,
                                decoration: pw.BoxDecoration(
                                  color: _pdfColor('#2F6BFF'),
                                  borderRadius: pw.BorderRadius.circular(7),
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                point.label.length > 8
                                    ? point.label.substring(0, 8)
                                    : point.label,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            pw.SizedBox(height: 22),

            pw.Text(
              'Top Product',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            if (topProducts.isEmpty)
              _pdfEmptyCard('Belum ada produk terlaris yang tersedia.')
            else
              ...topProducts.asMap().entries.map((entry) {
                final item = entry.value;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: _pdfColor('#E8ECF4')),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 24,
                        height: 24,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: _pdfColor('#EAF1FF'),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          '${entry.key + 1}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _pdfColor('#2F6BFF'),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.title,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              item.subtitle,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: _pdfColor('#6C7893'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        item.value,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _pdfColor('#1F2A44'),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 22),

            pw.Text(
              'Insight Bisnis',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            if (insights.isEmpty)
              _pdfEmptyCard('Tidak ada insight prioritas saat ini.')
            else
              ...insights.map((item) {
                final color = _pdfInsightColor(item.severity);

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _pdfColor('#F8FAFC'),
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: _pdfColor('#E8ECF4')),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 10,
                        height: 10,
                        margin: const pw.EdgeInsets.only(top: 2),
                        decoration: pw.BoxDecoration(
                          color: color,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.label,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              item.value,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: _pdfColor('#6C7893'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        item.severity,
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: color,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 18),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _pdfColor('#EAFBF7'),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                'Catatan: Angka pada laporan mengikuti data bisnis yang tersedia di dashboard saat laporan dibuat.',
                style: pw.TextStyle(fontSize: 9, color: _pdfColor('#1F2A44')),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfEmptyCard(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _pdfColor('#F6F8FC'),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _pdfColor('#E8ECF4')),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(fontSize: 10, color: _pdfColor('#6C7893')),
      ),
    );
  }

  PdfColor _pdfInsightColor(String severity) {
    final value = severity.toLowerCase();

    if (value.contains('warning')) {
      return _pdfColor('#F4A340');
    }

    if (value.contains('positive') || value.contains('success')) {
      return _pdfColor('#38B26C');
    }

    if (value.contains('critical') || value.contains('danger')) {
      return _pdfColor('#E25555');
    }

    return _pdfColor('#4C8BF5');
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Owner')),
      body: Obx(() {
        final points = _filteredTrend(dashboard);
        final hasReportData = _hasReportData(dashboard);

        if (dashboard.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!hasReportData) {
          return AppPage(
            children: const [
              EmptyState(
                title: 'Report belum tersedia',
                message:
                    'Report dapat dibuat setelah data bisnis retail tersedia.',
              ),
            ],
          );
        }

        return AppPage(
          children: [
            GradientHeader(
              title: 'Laporan Owner',
              subtitle:
                  'Preview laporan performa retail berdasarkan data bisnis terbaru.',
              badge: filter,
              icon: Icons.picture_as_pdf_rounded,
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Bulanan', 'Tahunan'].map((item) {
                final active = filter == item;

                return ChoiceChip(
                  label: Text(item),
                  selected: active,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.borderSoft.withOpacity(.65),
                  labelStyle: AppText.caption.copyWith(
                    color: active ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: active
                          ? AppColors.primary
                          : AppColors.borderSoft.withOpacity(.2),
                    ),
                  ),
                  onSelected: (_) {
                    setState(() => filter = item);
                  },
                );
              }).toList(),
            ),

            const SectionHeader(title: 'KPI Bisnis'),

            if (dashboard.ownerKpis.isEmpty)
              const EmptyState(
                title: 'Belum ada KPI',
                message: 'Data KPI bisnis belum tersedia.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 360;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dashboard.ownerKpis.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: isSmall ? 162 : 150,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (_, index) {
                      return KpiCard(metric: dashboard.ownerKpis[index]);
                    },
                  );
                },
              ),

            const SectionHeader(title: 'Revenue Trend'),

            LineChartCard(
              title: filter == 'Tahunan'
                  ? 'Total Revenue Tahunan'
                  : 'Revenue Bulanan',
              points: points,
            ),

            const SectionHeader(title: 'Top Product'),

            if (dashboard.ownerTopProducts.isEmpty)
              const EmptyState(
                title: 'Belum ada produk',
                message: 'Data produk belum tersedia.',
              )
            else
              ...dashboard.ownerTopProducts
                  .take(6)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                        RankCard(item: entry.value, index: entry.key + 1),
                  ),

            const SectionHeader(title: 'Insight Bisnis'),

            if (dashboard.ownerInsights.isEmpty)
              const EmptyState(
                title: 'Tidak ada insight prioritas',
                message:
                    'Bisnis dalam kondisi stabil berdasarkan data yang tersedia.',
              )
            else
              ...dashboard.ownerInsights.map((item) {
                final style = statusStyleForText(
                  '${item.label} ${item.value} ${item.severity}',
                );

                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  borderColor: style.background,
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: style.background,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(style.icon, color: style.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label, style: AppText.cardTitle),
                            const SizedBox(height: 4),
                            Text(item.value, style: AppText.body),
                          ],
                        ),
                      ),
                      InsightBadge(label: item.severity, color: style.color),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Printing.layoutPdf(
                        name: 'preview_laporan_pantau_retail.pdf',
                        onLayout: (_) => _buildPdf(dashboard),
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Printing.sharePdf(
                        bytes: await _buildPdf(dashboard),
                        filename: 'laporan_pantau_retail_$filter.pdf',
                      );

                      Get.snackbar(
                        'Report dibuat',
                        'Laporan berhasil dibuat dan siap dibagikan.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
