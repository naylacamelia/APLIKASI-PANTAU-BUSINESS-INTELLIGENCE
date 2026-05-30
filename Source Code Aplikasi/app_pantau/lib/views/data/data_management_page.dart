import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/dataset_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../shared/widgets.dart';
import 'dataset_detail_page.dart';
import 'import_dataset_page.dart';

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final dataset = Get.find<DatasetController>();

    return Obx(
      () => AppPage(
        children: [
          GradientHeader(
            title: 'Kelola Data',
            subtitle: 'Upload dan update data bisnis.',
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
              ),
              onPressed: () => Get.to(() => const ImportDatasetPage()),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Import'),
            ),
          ),
          const SizedBox(height: 14),
          if (dataset.errorMessage.value != null)
            ErrorState(
              message: dataset.errorMessage.value!,
              onRetry: dataset.loadDatasets,
            ),
          if (auth.canResetDatasets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () => _confirmReset(dataset),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset Semua Data'),
              ),
            ),
          const SectionHeader(title: 'Dataset'),
          if (dataset.isLoading.value)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (dataset.summaries.isEmpty)
            EmptyState(
              title: 'Belum ada data',
              message: 'Data akan tampil setelah file diupload.',
              action: ElevatedButton(
                onPressed: () => Get.to(() => const ImportDatasetPage()),
                child: const Text('Import Dataset'),
              ),
            )
          else
            ...dataset.summaries.map(
              (summary) => _DatasetCard(summary: summary),
            ),
        ],
      ),
    );
  }

  void _confirmReset(DatasetController dataset) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Semua Data?'),
        content: const Text(
          'Semua data bisnis akan dihapus. Ringkasan dan grafik bisa menjadi kosong sampai data diupload dan diolah kembali.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await dataset.resetAllDatasets();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _DatasetCard extends StatelessWidget {
  const _DatasetCard({required this.summary});

  final DatasetSummary summary;

  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              summary.category.icon,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.category.label} Dataset',
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.rows} baris data',
                  style: AppText.small,
                ),
                const SizedBox(height: 8),
                InsightBadge(
                  label: summary.statusLabel,
                  color: summary.rows > 0 ? AppColors.mint : AppColors.orange,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'detail') {
                await dataset.loadPreview(summary.category);
                Get.to(() => DatasetDetailPage(category: summary.category));
              }

              if (value == 'update') {
                Get.to(
                  () => ImportDatasetPage(
                    initialCategory: summary.category,
                  ),
                );
              }

              if (value == 'delete') {
                _confirmDelete(dataset, summary);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'detail',
                child: Text('Detail'),
              ),
              const PopupMenuItem(
                value: 'update',
                child: Text('Update File'),
              ),
              if (dataset.canDeleteDataset)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus Dataset'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DatasetController dataset, DatasetSummary summary) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Dataset?'),
        content: Text(
          'Data ${summary.category.label} akan dihapus. Ringkasan dan grafik terkait bisa menjadi kosong sampai data diupload dan diolah kembali.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await dataset.deleteDataset(summary.category);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
