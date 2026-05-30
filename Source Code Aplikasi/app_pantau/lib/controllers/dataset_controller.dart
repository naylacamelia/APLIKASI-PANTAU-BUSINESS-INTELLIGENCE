import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../data/supabase_repository.dart';
import '../models/models.dart';
import 'auth_controller.dart';
import 'dashboard_controller.dart';

class DatasetController extends GetxController {
  DatasetController(this._repository, this._authController);

  final SupabaseRepository _repository;
  final AuthController _authController;

  @override
  void onInit() {
    super.onInit();
    loadDatasets();
  }

  final summaries = <DatasetSummary>[].obs;
  final previewRows = <Map<String, dynamic>>[].obs;
  final selectedCategory = Rxn<DatasetCategory>();

  final isLoading = false.obs;
  final errorMessage = RxnString();

  final selectedImportCategory = Rxn<DatasetCategory>();
  final selectedFileName = ''.obs;
  final parsedRows = <Map<String, dynamic>>[].obs;
  final importError = RxnString();
  final importSuccessMessage = RxnString();
  final isParsingFile = false.obs;
  final isUploadingDataset = false.obs;

  final selectedSiteId = RxnString();
  final availableSites = <SiteOption>[].obs;

  bool get canDeleteDataset {
    return _authController.currentRole != UserRole.operational;
  }

  void selectGlobalScope() async {
    selectedSiteId.value = null;
    await _reloadDashboardIfReady();

    if (selectedCategory.value != null) {
      await loadPreview(selectedCategory.value!);
    }
  }

  void selectSiteScope(String siteId) async {
    selectedSiteId.value = siteId;
    await _reloadDashboardIfReady();

    if (selectedCategory.value != null) {
      await loadPreview(selectedCategory.value!);
    }
  }

  List<Map<String, dynamic>> _filterRowsBySelectedSite(
    List<Map<String, dynamic>> rows,
  ) {
    final siteId = selectedSiteId.value;

    if (siteId == null || siteId.trim().isEmpty) return rows;

    return rows.where((row) {
      return row['site_id']?.toString().trim() == siteId;
    }).toList();
  }

  List<DatasetCategory> get accessibleCategories {
    switch (_authController.effectiveRole) {
      case UserRole.owner:
        return const [
          DatasetCategory.sales,
          DatasetCategory.product,
          DatasetCategory.inventory,
          DatasetCategory.customer,
          DatasetCategory.promotion,
          DatasetCategory.planning,
        ];

      case UserRole.operational:
        return const [
          DatasetCategory.sales,
          DatasetCategory.product,
          DatasetCategory.inventory,
          DatasetCategory.logistic,
        ];

      case UserRole.superadmin:
        return DatasetCategory.values;
    }
  }

  void resetImportState({DatasetCategory? category}) {
    selectedImportCategory.value = category;
    selectedFileName.value = '';
    parsedRows.clear();
    importError.value = null;
    importSuccessMessage.value = null;
    isParsingFile.value = false;
    isUploadingDataset.value = false;
  }

  void selectImportCategory(DatasetCategory category) {
    selectedImportCategory.value = category;
    selectedFileName.value = '';
    parsedRows.clear();
    importError.value = null;
    importSuccessMessage.value = null;
  }

  Future<void> loadDatasets() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait([
        _repository.fetchDatasetSummaries(accessibleCategories),
        _repository.fetchSites(),
      ]);

      summaries.assignAll(results[0] as List<DatasetSummary>);
      availableSites.assignAll(results[1] as List<SiteOption>);
    } catch (error) {
      errorMessage.value = 'Gagal memuat data: $error';
      summaries.clear();
      availableSites.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPreview(DatasetCategory category) async {
    selectedCategory.value = category;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final rows = await _repository.fetchDatasetPreview(category);
      previewRows.assignAll(_filterRowsBySelectedSite(rows));
    } catch (error) {
      errorMessage.value = 'Gagal membuka detail data: $error';
      previewRows.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickCsvForImport() async {
    final category = selectedImportCategory.value;

    if (category == null) {
      importError.value = 'Pilih jenis data terlebih dahulu.';
      return;
    }

    isParsingFile.value = true;
    importError.value = null;
    importSuccessMessage.value = null;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        importError.value = 'File tidak bisa dibaca.';
        return;
      }

      selectedFileName.value = file.name;

      final rows = _parseCsv(category, bytes);
      parsedRows.assignAll(rows);

      if (rows.isEmpty) {
        importError.value = 'File tidak memiliki baris data.';
      }
    } catch (error) {
      importError.value = 'Gagal membaca file: $error';
      parsedRows.clear();
    } finally {
      isParsingFile.value = false;
    }
  }

  Future<void> uploadParsedDataset() async {
    final category = selectedImportCategory.value;

    if (category == null) {
      importError.value = 'Pilih jenis data terlebih dahulu.';
      return;
    }

    if (parsedRows.isEmpty) {
      importError.value = 'Tidak ada data yang bisa diupload.';
      return;
    }

    isUploadingDataset.value = true;
    importError.value = null;
    importSuccessMessage.value = null;

    try {
      await _repository.replaceDataset(
        category: category,
        rows: parsedRows.toList(),
      );

      await loadDatasets();

      if (selectedCategory.value == category) {
        await loadPreview(category);
      }

      await _reloadDashboardIfReady();

      importSuccessMessage.value =
          '${category.label} berhasil diupload. Ringkasan akan diperbarui setelah data selesai diolah.';
    } catch (error) {
      importError.value = 'Gagal upload data: $error';
    } finally {
      isUploadingDataset.value = false;
    }
  }

  Future<void> pickAndReplaceDataset(DatasetCategory category) async {
    resetImportState(category: category);
    await pickCsvForImport();

    if (importError.value == null && parsedRows.isNotEmpty) {
      await uploadParsedDataset();
    }
  }

  Future<void> replaceDatasetFromCsv({
    required DatasetCategory category,
    required Uint8List bytes,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final rows = _parseCsv(category, bytes);

      await _repository.replaceDataset(
        category: category,
        rows: rows,
      );

      await loadDatasets();

      if (selectedCategory.value == category) {
        await loadPreview(category);
      }

      await _reloadDashboardIfReady();
    } catch (error) {
      errorMessage.value = 'Gagal update data: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDataset(DatasetCategory category) async {
    if (!canDeleteDataset) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.deleteDataset(category);
      await loadDatasets();

      if (selectedCategory.value == category) {
        previewRows.clear();
      }

      await _reloadDashboardIfReady();
    } catch (error) {
      errorMessage.value = 'Gagal hapus data: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetAllDatasets() async {
    if (!_authController.canResetDatasets) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.resetAllDatasets();
      await loadDatasets();
      previewRows.clear();
      await _reloadDashboardIfReady();
    } catch (error) {
      errorMessage.value = 'Gagal reset data: $error';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _reloadDashboardIfReady() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboard();
    }
  }

  List<Map<String, dynamic>> _parseCsv(
    DatasetCategory category,
    Uint8List bytes,
  ) {
    var csvString = utf8.decode(bytes, allowMalformed: true);

    csvString = csvString
        .replaceFirst('\ufeff', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final expected =
        category.columns.map((column) => _normalizeHeader(column)).toList();

    final parsed = _parseCsvWithBestDelimiter(csvString, expected);

    final table = parsed['table'] as List<List<dynamic>>;
    final headers = parsed['headers'] as List<String>;

    if (table.isEmpty) return [];

    final missing =
        expected.where((column) => !headers.contains(column)).toList();

    if (missing.isNotEmpty) {
      throw 'Struktur file belum sesuai. Gunakan file hasil olah dengan kolom: ${category.columns.join(', ')}';
    }

    final rows = <Map<String, dynamic>>[];

    for (final rawRow in table.skip(1)) {
      final isEmptyRow = rawRow.every(
        (cell) => cell == null || cell.toString().trim().isEmpty,
      );

      if (isEmptyRow) continue;

      final map = <String, dynamic>{};

      for (final column in expected) {
        final index = headers.indexOf(column);
        final value = index < rawRow.length ? rawRow[index] : null;

        map[column] = _cleanValue(value);
      }

      for (final column in expected) {
        map[column] = _convertRupeeToRupiahIfNeeded(
          category: category,
          column: column,
          value: map[column],
          row: map,
        );
      }

      rows.add(map);
    }

    return rows;
  }

  Map<String, dynamic> _parseCsvWithBestDelimiter(
    String csvString,
    List<String> expected,
  ) {
    final delimiters = [',', ';', '\t'];

    List<List<dynamic>> bestTable = <List<dynamic>>[];
    List<String> bestHeaders = <String>[];
    int bestScore = -1;

    for (final delimiter in delimiters) {
      try {
        final table = CsvToListConverter(
          shouldParseNumbers: true,
          fieldDelimiter: delimiter,
          eol: '\n',
        ).convert(csvString);

        if (table.isEmpty) continue;

        final headers =
            table.first.map((cell) => _normalizeHeader(cell)).toList();

        final score =
            expected.where((column) => headers.contains(column)).length;

        if (score > bestScore) {
          bestScore = score;
          bestTable = table;
          bestHeaders = headers;
        }
      } catch (_) {
        continue;
      }
    }

    return {
      'table': bestTable,
      'headers': bestHeaders,
    };
  }

  String _normalizeHeader(dynamic value) {
    return value
        .toString()
        .replaceAll('\ufeff', '')
        .replaceAll('\r', '')
        .trim()
        .toLowerCase();
  }

  dynamic _cleanValue(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return text;
    }

    return value;
  }

  static const double _inrToIdrRate = 183.0;

  dynamic _convertRupeeToRupiahIfNeeded({
    required DatasetCategory category,
    required String column,
    required dynamic value,
    required Map<String, dynamic> row,
  }) {
    if (value == null) return null;

    final shouldConvert = _isMoneyColumnForRupeeDataset(
      category: category,
      column: column,
      row: row,
    );

    if (!shouldConvert) return value;

    final numericValue = _toDouble(value);
    if (numericValue == null) return value;

    return numericValue * _inrToIdrRate;
  }

  bool _isMoneyColumnForRupeeDataset({
    required DatasetCategory category,
    required String column,
    required Map<String, dynamic> row,
  }) {
    switch (category) {
      case DatasetCategory.sales:
        return column == 'revenue' || column == 'discounts';

      case DatasetCategory.product:
        return column == 'unit_cost' || column == 'unit_price';

      case DatasetCategory.customer:
        return column == 'average_spend';

      case DatasetCategory.planning:
        return column == 'forecasted_sales' || column == 'actual_sales';

      case DatasetCategory.promotion:
        if (column != 'discount_amount') return false;

        final discountType =
            row['discount_type']?.toString().toLowerCase().trim();

        return discountType == 'flat';

      case DatasetCategory.inventory:
      case DatasetCategory.logistic:
      case DatasetCategory.site:
        return false;
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is int) return value.toDouble();
    if (value is double) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final cleaned = text
        .replaceAll('₹', '')
        .replaceAll('INR', '')
        .replaceAll('inr', '')
        .replaceAll(' ', '')
        .replaceAll(',', '');

    return double.tryParse(cleaned);
  }
}