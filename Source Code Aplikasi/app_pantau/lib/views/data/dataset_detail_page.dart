import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../controllers/dataset_controller.dart';
import '../../models/models.dart';
import '../shared/widgets.dart';

class DatasetDetailPage extends StatelessWidget {
  const DatasetDetailPage({super.key, required this.category});
  final DatasetCategory category;

  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();
    return Scaffold(
      appBar: AppBar(title: Text('${category.label} Detail')),
      body: Obx(() => AppPage(children: [
            GradientHeader(title: '${category.label} Dataset', subtitle: 'Preview data dari tabel app.${category.tableName}.'),
            const SiteSelector(),
            const SectionHeader(title: 'Struktur Kolom'),
            AppCard(child: Text(category.columns.join(', '), style: AppText.small)),
            const SectionHeader(title: 'Preview Rows'),
            if (dataset.isLoading.value)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (dataset.previewRows.isEmpty)
              const EmptyState(title: 'Belum ada data', message: 'Tabel ini masih kosong di database.')
            else
              ...dataset.previewRows.take(20).map((row) => AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: row.entries.take(6).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('${e.key}: ${e.value}', style: AppText.small),
                          )).toList(),
                    ),
                  )),
          ])),
    );
  }
}
