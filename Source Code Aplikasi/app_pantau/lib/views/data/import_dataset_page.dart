import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dataset_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../shared/widgets.dart';

class ImportDatasetPage extends StatefulWidget {
  const ImportDatasetPage({super.key, this.initialCategory});

  final DatasetCategory? initialCategory;

  @override
  State<ImportDatasetPage> createState() => _ImportDatasetPageState();
}

class _ImportDatasetPageState extends State<ImportDatasetPage> {
  final dataset = Get.find<DatasetController>();

  bool get isLockedCategory => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessible = dataset.accessibleCategories;

      final initial =
          widget.initialCategory ??
          (accessible.isNotEmpty ? accessible.first : DatasetCategory.sales);

      dataset.resetImportState(category: initial);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = isLockedCategory ? 'Update Data' : 'Import Data';

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: AppPage(
        children: [
          GradientHeader(
            title: pageTitle,
            subtitle:
                'Upload file CSV yang sudah sesuai format agar dashboard dapat menampilkan ringkasan terbaru.',
            badge: 'Data Management',
            icon: Icons.cloud_upload_rounded,
          ),
          const SizedBox(height: 18),
          _ImportGuideCard(isLockedCategory: isLockedCategory),
          const SectionHeader(title: 'Pilih Tipe Data'),
          _DatasetTypeSelector(isLockedCategory: isLockedCategory),
          const SizedBox(height: 18),
          _UploadBox(),
          const SizedBox(height: 14),
          _SelectedFileCard(),
          _ImportErrorMessage(),
          _ImportSuccessMessage(),
          const SizedBox(height: 18),
          _UploadButton(isLockedCategory: isLockedCategory),
          const SizedBox(height: 12),
          const _ImportNoteCard(),
        ],
      ),
    );
  }
}

class _ImportGuideCard extends StatelessWidget {
  const _ImportGuideCard({required this.isLockedCategory});

  final bool isLockedCategory;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: AppColors.card,
      borderColor: AppColors.primarySoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isLockedCategory ? Icons.sync_rounded : Icons.upload_file_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLockedCategory
                      ? 'Perbarui data yang dipilih'
                      : 'Import data operasional',
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 5),
                Text(
                  isLockedCategory
                      ? 'File baru akan mengganti data lama pada kategori ini.'
                      : 'Pilih tipe data, unggah file CSV, lalu data akan digunakan untuk memperbarui dashboard.',
                  style: AppText.body.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatasetTypeSelector extends StatelessWidget {
  const _DatasetTypeSelector({required this.isLockedCategory});

  final bool isLockedCategory;

  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();

    return Obx(() {
      final selected = dataset.selectedImportCategory.value;
      final categories = dataset.accessibleCategories;

      if (categories.isEmpty) {
        return const EmptyState(
          title: 'Tidak ada akses data',
          message: 'Akun ini belum memiliki akses untuk import data.',
        );
      }

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: categories.map((category) {
          final isSelected = selected == category;

          return ChoiceChip(
            label: Text(category.label),
            selected: isSelected,
            avatar: Icon(
              category.icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.borderSoft.withOpacity(.65),
            disabledColor: AppColors.borderSoft.withOpacity(.45),
            labelStyle: AppText.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.borderSoft.withOpacity(.2),
              ),
            ),
            onSelected: isLockedCategory
                ? null
                : (_) {
                    dataset.selectImportCategory(category);
                  },
          );
        }).toList(),
      );
    });
  }
}

class _UploadBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();

    return Obx(() {
      final category = dataset.selectedImportCategory.value;
      final isParsing = dataset.isParsingFile.value;
      final fileName = dataset.selectedFileName.value;
      final hasFile = fileName.isNotEmpty;

      return GestureDetector(
        onTap: isParsing
            ? null
            : () async {
                await dataset.pickCsvForImport();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: hasFile ? AppColors.success : AppColors.primary,
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(.045),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: hasFile
                      ? AppColors.successSoft
                      : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFile
                      ? Icons.check_circle_outline_rounded
                      : Icons.cloud_upload_outlined,
                  color: hasFile ? AppColors.success : AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                hasFile ? 'File berhasil dipilih' : 'Pilih file CSV',
                textAlign: TextAlign.center,
                style: AppText.sectionTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                category == null
                    ? 'Pilih tipe data terlebih dahulu'
                    : 'Pastikan file sesuai format ${category.label}',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isParsing
                      ? AppColors.borderSoft
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isParsing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      isParsing ? 'Membaca file...' : 'Pilih File',
                      style: AppText.cardTitle.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SelectedFileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();

    return Obx(() {
      final fileName = dataset.selectedFileName.value;
      final rows = dataset.parsedRows.length;
      final category = dataset.selectedImportCategory.value;

      if (fileName.isEmpty && rows == 0) {
        return const SizedBox.shrink();
      }

      return AppCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppColors.successSoft,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rows > 0
                        ? '$rows baris terbaca untuk ${category?.label ?? 'dataset'}'
                        : 'File dipilih, menunggu proses baca data.',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (rows > 0) InsightBadge(label: 'Siap', color: AppColors.success),
          ],
        ),
      );
    });
  }
}

class _ImportErrorMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();

    return Obx(() {
      final error = dataset.importError.value;

      if (error == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: ErrorState(message: error),
      );
    });
  }
}

class _ImportSuccessMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();

    return Obx(() {
      final message = dataset.importSuccessMessage.value;

      if (message == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: AppCard(
          color: AppColors.successSoft,
          borderColor: AppColors.success.withOpacity(.18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.isLockedCategory});

  final bool isLockedCategory;

  @override
  Widget build(BuildContext context) {
    final dataset = Get.find<DatasetController>();

    return Obx(() {
      final canUpload =
          dataset.selectedImportCategory.value != null &&
          dataset.parsedRows.isNotEmpty &&
          dataset.importError.value == null &&
          !dataset.isUploadingDataset.value;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canUpload
              ? () async {
                  final confirm = await _showUploadConfirmation(
                    context,
                    isLockedCategory: isLockedCategory,
                  );

                  if (confirm == true) {
                    await dataset.uploadParsedDataset();
                  }
                }
              : null,
          icon: dataset.isUploadingDataset.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_upload_rounded),
          label: Text(
            dataset.isUploadingDataset.value
                ? 'Mengupload...'
                : isLockedCategory
                    ? 'Update Data'
                    : 'Upload Data',
          ),
        ),
      );
    });
  }

  Future<bool?> _showUploadConfirmation(
    BuildContext context, {
    required bool isLockedCategory,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(isLockedCategory ? 'Update Data?' : 'Upload Data?'),
          content: const Text(
            'Data pada kategori ini akan diperbarui menggunakan file yang dipilih. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isLockedCategory ? 'Update' : 'Upload'),
            ),
          ],
        );
      },
    );
  }
}

class _ImportNoteCard extends StatelessWidget {
  const _ImportNoteCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.warningSoft,
      borderColor: AppColors.warning.withOpacity(.18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.72),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gunakan file CSV yang sudah rapi dan sesuai kolom data. Ringkasan dashboard akan berubah setelah data berhasil diproses.',
              style: AppText.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}