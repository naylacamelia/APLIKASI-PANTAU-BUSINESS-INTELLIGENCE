import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class SupabaseRepository {
  SupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  dynamic _table(String name) => _client.schema('app').from(name);

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final response = await _table('users')
        .select()
        .ilike('email', email.trim())
        .eq('password', password.trim())
        .maybeSingle();

    if (response == null) return null;
    return _userFromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<List<AppUser>> fetchUsers() async {
    final response = await _table(
      'users',
    ).select().order('id', ascending: true);

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(_userFromMap).toList();
  }

  Future<void> insertUser({
    required String name,
    required String email,
    required UserRole role,
    required String password,
  }) async {
    final users = await fetchUsers();
    final nextId = users
            .map((user) => int.tryParse(user.id) ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b) +
        1;

    await _table('users').insert({
      'id': nextId,
      'created_at': DateTime.now().toIso8601String(),
      'nama_lengkap': name,
      'email': email,
      'no_telp': 0,
      'roles': _roleToDatabase(role),
      'password': password,
      'role_id': _roleId(role),
      'role_description': _roleDescription(role),
    });
  }

  Future<void> updateUser({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    String? password,
  }) async {
    final payload = <String, dynamic>{
      'nama_lengkap': name,
      'email': email,
      'roles': _roleToDatabase(role),
      'role_id': _roleId(role),
      'role_description': _roleDescription(role),
    };

    final cleanPassword = password?.trim();

    if (cleanPassword != null &&
        cleanPassword.isNotEmpty &&
        cleanPassword != '********') {
      payload['password'] = cleanPassword;
    }

    await _table('users').update(payload).eq('id', int.tryParse(id) ?? id);
  }

  Future<void> deleteUser(String id) async {
    await _table('users').delete().eq('id', int.tryParse(id) ?? id);
  }

  Future<List<DatasetSummary>> fetchDatasetSummaries(
    List<DatasetCategory> categories,
  ) async {
    final result = <DatasetSummary>[];

    for (final category in categories) {
      try {
        final rows = await _table(
          category.tableName,
        ).select(category.keyColumn);

        final count = (rows as List).length;

        result.add(
          DatasetSummary(
            category: category,
            rows: count,
            statusLabel: count > 0 ? 'Data Siap' : 'Belum Ada',
          ),
        );
      } catch (_) {
        result.add(
          DatasetSummary(
            category: category,
            rows: 0,
            statusLabel: 'Perlu Dicek',
          ),
        );
      }
    }

    return result;
  }

  Future<bool> hasDatasetRows(DatasetCategory category) async {
    final response = await _table(
      category.tableName,
    ).select(category.keyColumn).limit(1);

    return (response as List).isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> fetchDatasetPreview(
    DatasetCategory category, {
    int limit = 20,
  }) async {
    final response = await _table(category.tableName).select().limit(limit);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> replaceDataset({
    required DatasetCategory category,
    required List<Map<String, dynamic>> rows,
  }) async {
    await _clearSourceDataset(category);

    if (rows.isNotEmpty) {
      const chunkSize = 500;

      for (var i = 0; i < rows.length; i += chunkSize) {
        final end = (i + chunkSize > rows.length) ? rows.length : i + chunkSize;

        await _table(category.tableName).insert(rows.sublist(i, end));
      }
    }

    await clearDependentAnalytics(category);
  }

  Future<void> deleteDataset(DatasetCategory category) async {
    await _clearSourceDataset(category);
    await clearDependentAnalytics(category);
  }

  Future<void> resetAllDatasets() async {
    for (final category in DatasetCategory.values) {
      await deleteDataset(category);
    }
  }

  Future<void> _clearSourceDataset(DatasetCategory category) async {
    await _table(
      category.tableName,
    ).delete().neq(category.keyColumn, '__delete_all__');
  }

  Future<void> _clearAnalyticsTable({
    required String tableName,
    required String idColumn,
  }) async {
    await _table(tableName).delete().gte(idColumn, 0);
  }

  Future<void> clearDependentAnalytics(DatasetCategory category) async {
    final targets = <({String tableName, String idColumn})>[];

    switch (category) {
      case DatasetCategory.sales:
        targets.addAll([
          (tableName: 'owner_kpi_summary', idColumn: 'kpi_id'),
          (tableName: 'sales_monthly_trend', idColumn: 'sales_monthly_id'),
          (
            tableName: 'product_performance',
            idColumn: 'product_performance_id',
          ),
          (tableName: 'customer_analysis', idColumn: 'customer_analysis_id'),
          (
            tableName: 'promotion_performance',
            idColumn: 'promotion_performance_id',
          ),
          (tableName: 'final_sales_dataset', idColumn: 'final_sales_id'),
        ]);
        break;

      case DatasetCategory.product:
        targets.addAll([
          (
            tableName: 'product_performance',
            idColumn: 'product_performance_id',
          ),
          (
            tableName: 'inventory_monitoring',
            idColumn: 'inventory_monitoring_id',
          ),
          (
            tableName: 'promotion_performance',
            idColumn: 'promotion_performance_id',
          ),
          (tableName: 'final_sales_dataset', idColumn: 'final_sales_id'),
        ]);
        break;

      case DatasetCategory.inventory:
        targets.addAll([
          (
            tableName: 'inventory_monitoring',
            idColumn: 'inventory_monitoring_id',
          ),
          (
            tableName: 'product_performance',
            idColumn: 'product_performance_id',
          ),
          (tableName: 'final_sales_dataset', idColumn: 'final_sales_id'),
        ]);
        break;

      case DatasetCategory.customer:
        targets.addAll([
          (tableName: 'customer_analysis', idColumn: 'customer_analysis_id'),
          (tableName: 'owner_kpi_summary', idColumn: 'kpi_id'),
          (tableName: 'final_sales_dataset', idColumn: 'final_sales_id'),
        ]);
        break;

      case DatasetCategory.promotion:
        targets.addAll([
          (
            tableName: 'promotion_performance',
            idColumn: 'promotion_performance_id',
          ),
          (tableName: 'final_sales_dataset', idColumn: 'final_sales_id'),
        ]);
        break;

      case DatasetCategory.logistic:
        targets.addAll([
          (
            tableName: 'logistics_performance',
            idColumn: 'logistics_performance_id',
          ),
        ]);
        break;

      case DatasetCategory.planning:
        targets.addAll([
          (
            tableName: 'seasonal_planning_performance',
            idColumn: 'planning_performance_id',
          ),
        ]);
        break;

      case DatasetCategory.site:
        targets.addAll([
          (tableName: 'final_sales_dataset', idColumn: 'final_sales_id'),
        ]);
        break;
    }

    for (final target in targets) {
      await _clearAnalyticsTable(
        tableName: target.tableName,
        idColumn: target.idColumn,
      );
    }
  }

  Future<Map<String, dynamic>?> fetchOwnerKpiSummary() async {
    final response = await _table('owner_kpi_summary').select().limit(1);
    final rows = List<Map<String, dynamic>>.from(response as List);

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> fetchSalesMonthlyTrend() async {
    final response = await _table(
      'sales_monthly_trend',
    ).select().order('year', ascending: true).order('month', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchProductPerformance({
    int limit = 10,
  }) async {
    final response = await _table(
      'product_performance',
    ).select().order('product_rank', ascending: true).limit(limit);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchInventoryMonitoring({
    int limit = 30,
  }) async {
    final response = await _table('inventory_monitoring').select().limit(limit);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchCustomerAnalysis({
    int limit = 10,
  }) async {
    final response = await _table(
      'customer_analysis',
    ).select().order('total_net_revenue', ascending: false).limit(limit);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchPromotionPerformance({
    int limit = 10,
  }) async {
    final response = await _table(
      'promotion_performance',
    ).select().order('total_net_revenue', ascending: false).limit(limit);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchLogisticsPerformance() async {
    final response = await _table('logistics_performance').select();

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchPlanningPerformance({
    int limit = 20,
  }) async {
    final response = await _table(
      'seasonal_planning_performance',
    ).select().order('month_date', ascending: true).limit(limit);

    return List<Map<String, dynamic>>.from(response as List);
  }

  AppUser _userFromMap(Map<String, dynamic> row) {
    return AppUser(
      id: row['id']?.toString() ?? '',
      name: row['nama_lengkap']?.toString() ?? '-',
      email: row['email']?.toString() ?? '-',
      role: _roleFromDatabase(row['roles']?.toString()),
      isActive: true,
    );
  }

  UserRole _roleFromDatabase(String? value) {
    final role = value?.toLowerCase().trim();

    switch (role) {
      case 'administrator':
      case 'superadmin':
        return UserRole.superadmin;

      case 'admin_operasional':
      case 'operasional':
      case 'operational':
      case 'staff':
        return UserRole.operational;

      case 'owner':
      default:
        return UserRole.owner;
    }
  }

  String _roleToDatabase(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'owner';

      case UserRole.operational:
        return 'admin_operasional';

      case UserRole.superadmin:
        return 'administrator';
    }
  }

  int _roleId(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return 1;

      case UserRole.owner:
        return 2;

      case UserRole.operational:
        return 3;
    }
  }

  String _roleDescription(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return 'Mengelola seluruh sistem, user, role, dan data aplikasi';

      case UserRole.owner:
        return 'Melihat ringkasan strategis bisnis untuk pemilik';

      case UserRole.operational:
        return 'Mengelola dan memantau inventory, stock, logistics, dan dataset';
    }
  }

  Future<List<Map<String, dynamic>>> fetchSourceSales() async {
    final response = await _table('sales').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchSourceProduct() async {
    final response = await _table('product').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchSourceCustomer() async {
    final response = await _table('customer').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchSourcePromotion() async {
    final response = await _table('promotion').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchSourcePlanning() async {
    final response = await _table('planning').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchSourceInventory() async {
    final response = await _table('inventory').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> fetchSourceLogistic() async {
    final response = await _table('logistic').select();
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<SiteOption>> fetchSites() async {
    final response = await _table('site')
        .select('site_id, site_name, site_format, city, state')
        .order('site_name', ascending: true);

    final rows = List<Map<String, dynamic>>.from(response as List);

    return rows
        .map((row) {
          return SiteOption(
            siteId: row['site_id']?.toString() ?? '',
            siteName: row['site_name']?.toString() ?? '-',
            siteFormat: row['site_format']?.toString(),
            city: row['city']?.toString(),
            state: row['state']?.toString(),
          );
        })
        .where((site) => site.siteId.trim().isNotEmpty)
        .toList();
  }
}
