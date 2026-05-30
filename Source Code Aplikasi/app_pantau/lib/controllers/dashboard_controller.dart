import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../data/supabase_repository.dart';
import '../models/models.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository, this._authController);

  final SupabaseRepository _repository;
  final AuthController _authController;

  final isLoading = false.obs;
  final errorMessage = RxnString();

  final selectedSiteId = RxnString();
  final availableSites = <SiteOption>[].obs;

  final ownerKpis = <KpiMetric>[].obs;
  final ownerRevenueTrend = <ChartPoint>[].obs;
  final ownerTopProducts = <RankItem>[].obs;
  final ownerInsights = <InsightItem>[].obs;

  final ownerProductChart = <ChartPoint>[].obs;
  final ownerInventoryChart = <ChartPoint>[].obs;
  final ownerCustomerChart = <ChartPoint>[].obs;
  final ownerPromoChart = <ChartPoint>[].obs;
  final ownerPlanningChart = <ChartPoint>[].obs;
  final ownerPlanningForecastChart = <ChartPoint>[].obs;
  final ownerPlanningActualChart = <ChartPoint>[].obs;
  final ownerPlanningErrorChart = <ChartPoint>[].obs;

  final ownerCustomerRanks = <RankItem>[].obs;
  final ownerPromoRanks = <RankItem>[].obs;
  final ownerPlanningRanks = <RankItem>[].obs;

  final ownerCriticalStockItems = <RankItem>[].obs;
  final ownerRestockPriority = <RankItem>[].obs;
  final ownerOverstockItems = <RankItem>[].obs;
  final ownerStockStatusChart = <ChartPoint>[].obs;

  final operationalKpis = <KpiMetric>[].obs;
  final restockPriority = <RankItem>[].obs;
  final criticalStockItems = <RankItem>[].obs;
  final overstockItems = <RankItem>[].obs;
  final fastMovingProducts = <RankItem>[].obs;
  final slowMovingProducts = <RankItem>[].obs;
  final logisticsIssues = <RankItem>[].obs;

  final operationalInventoryChart = <ChartPoint>[].obs;
  final operationalProductChart = <ChartPoint>[].obs;
  final operationalLogisticsChart = <ChartPoint>[].obs;
  final operationalStockStatusChart = <ChartPoint>[].obs;
  final operationalLogisticStatusChart = <ChartPoint>[].obs;

  final hasOperationalInventoryData = false.obs;
  final hasOperationalProductData = false.obs;
  final hasOperationalLogisticData = false.obs;

  final ownerAnalytics = <AnalyticsCategory>[].obs;
  final operationalAnalytics = <AnalyticsCategory>[].obs;

  final currency = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );

  final number = NumberFormat.decimalPattern('id_ID');

  bool get _hasSelectedSiteFilter {
    final siteId = selectedSiteId.value;
    return siteId != null && siteId.trim().isNotEmpty;
  }

  Future<void> loadSites() async {
    try {
      final sites = await _repository.fetchSites();

      final uniqueSites = <String, SiteOption>{};

      for (final site in sites) {
        final id = site.siteId.trim();
        if (id.isEmpty) continue;
        uniqueSites[id] = site;
      }

      availableSites.assignAll(uniqueSites.values.toList());
    } catch (_) {
      availableSites.clear();
    }
  }

  Future<void> selectGlobalScope() async {
    selectedSiteId.value = null;
    await loadDashboard();
  }

  Future<void> selectSiteScope(String siteId) async {
    final cleanSiteId = siteId.trim();

    if (cleanSiteId.isEmpty) {
      await selectGlobalScope();
      return;
    }

    selectedSiteId.value = cleanSiteId;
    await loadDashboard();
  }

  List<Map<String, dynamic>> _filterRowsBySelectedSite(
    List<Map<String, dynamic>> rows,
  ) {
    final siteId = selectedSiteId.value?.trim();

    if (siteId == null || siteId.isEmpty) return rows;

    return rows.where((row) {
      return row['site_id']?.toString().trim() == siteId;
    }).toList();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (availableSites.isEmpty) {
        await loadSites();
      }

      final role = _authController.effectiveRole;

      if (role == UserRole.owner) {
        await _loadOwnerDashboard();
      } else if (role == UserRole.operational) {
        await _loadOperationalDashboard();
      } else {
        _clearAll();
      }
    } catch (error) {
      errorMessage.value = 'Gagal memuat ringkasan: $error';
      _clearAll();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadOwnerDashboard() async {
    _clearAll();

    final hasSales = await _repository.hasDatasetRows(DatasetCategory.sales);
    final hasProduct =
        await _repository.hasDatasetRows(DatasetCategory.product);
    final hasInventory =
        await _repository.hasDatasetRows(DatasetCategory.inventory);
    final hasCustomer =
        await _repository.hasDatasetRows(DatasetCategory.customer);
    final hasPromotion =
        await _repository.hasDatasetRows(DatasetCategory.promotion);
    final hasPlanning =
        await _repository.hasDatasetRows(DatasetCategory.planning);

    final sourceSales = hasSales
        ? _filterRowsBySelectedSite(await _repository.fetchSourceSales())
        : <Map<String, dynamic>>[];

    final sourceProduct = hasProduct
        ? await _repository.fetchSourceProduct()
        : <Map<String, dynamic>>[];

    final sourceInventory = hasInventory
        ? _filterRowsBySelectedSite(await _repository.fetchSourceInventory())
        : <Map<String, dynamic>>[];

    final sourceCustomer = hasCustomer
        ? await _repository.fetchSourceCustomer()
        : <Map<String, dynamic>>[];

    final sourcePromotion = hasPromotion
        ? _filterRowsBySelectedSite(await _repository.fetchSourcePromotion())
        : <Map<String, dynamic>>[];

    final sourcePlanning = hasPlanning
        ? _filterRowsBySelectedSite(await _repository.fetchSourcePlanning())
        : <Map<String, dynamic>>[];

    final kpi = hasSales
        ? _buildOwnerKpiFromSource(
            salesRows: sourceSales,
            productRows: sourceProduct,
          )
        : null;

    final salesTrend = hasSales
        ? _buildSalesTrendFromSource(sourceSales)
        : <Map<String, dynamic>>[];

    final products = hasSales && hasProduct
        ? _buildProductMovementFromSource(
            salesRows: sourceSales,
            productRows: sourceProduct,
          )
        : <Map<String, dynamic>>[];

    final inventory = hasInventory
        ? _buildInventoryFromSource(
            inventoryRows: sourceInventory,
            productRows: sourceProduct,
            salesRows: sourceSales,
          )
        : <Map<String, dynamic>>[];

    final customers = hasCustomer && hasSales
        ? _buildCustomerAnalysisFromSource(
            salesRows: sourceSales,
            customerRows: sourceCustomer,
          )
        : <Map<String, dynamic>>[];

    final promos = hasPromotion && hasSales && hasProduct
        ? _buildPromotionPerformanceFromSource(
            salesRows: sourceSales,
            productRows: sourceProduct,
            promotionRows: sourcePromotion,
          )
        : <Map<String, dynamic>>[];

    final planning = hasPlanning
        ? _buildPlanningPerformanceFromSource(sourcePlanning)
        : <Map<String, dynamic>>[];

    ownerKpis.assignAll(_ownerKpisFrom(kpi));

    ownerRevenueTrend.assignAll(
      salesTrend.map(
        (row) => ChartPoint(
          row['month_name']?.toString() ?? row['month']?.toString() ?? '-',
          _toDouble(row['total_net_revenue']),
        ),
      ),
    );

    ownerTopProducts.assignAll(
      products.take(10).map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: currency.format(_toDouble(row['total_net_revenue'])),
              badge: _stockBadge(row['stock_status']),
            ),
          ),
    );

    ownerProductChart.assignAll(
      products.take(8).map(
            (row) => ChartPoint(
              row['product_name']?.toString() ?? '-',
              _toDouble(row['total_net_revenue']),
            ),
          ),
    );

    final inventoryByStock = [...inventory];
    inventoryByStock.sort(
      (a, b) => _toDouble(b['total_ending_inventory']).compareTo(
        _toDouble(a['total_ending_inventory']),
      ),
    );

    ownerInventoryChart.assignAll(
      inventoryByStock.take(8).map(
            (row) => ChartPoint(
              row['product_name']?.toString() ?? '-',
              _toDouble(row['total_ending_inventory']),
            ),
          ),
    );

    ownerCustomerChart.assignAll(
      customers.take(8).map(
            (row) => ChartPoint(
              row['customer_id']?.toString() ?? '-',
              _toDouble(row['total_net_revenue']),
            ),
          ),
    );

    ownerPromoChart.assignAll(
      promos.take(8).map(
            (row) => ChartPoint(
              row['product_name']?.toString() ?? '-',
              _toDouble(row['total_net_revenue']),
            ),
          ),
    );

    final monthlyPlanning = _aggregatePlanningByMonth(planning);

    ownerPlanningChart.assignAll(
      monthlyPlanning.map(
        (row) => ChartPoint(
          row['month_name']?.toString() ?? '-',
          _toDouble(row['forecast_accuracy']),
        ),
      ),
    );

    ownerPlanningForecastChart.assignAll(
      monthlyPlanning.map(
        (row) => ChartPoint(
          row['month_name']?.toString() ?? '-',
          _toDouble(row['forecasted_sales']),
        ),
      ),
    );

    ownerPlanningActualChart.assignAll(
      monthlyPlanning.map(
        (row) => ChartPoint(
          row['month_name']?.toString() ?? '-',
          _toDouble(row['actual_sales']),
        ),
      ),
    );

    ownerPlanningErrorChart.assignAll(
      monthlyPlanning.map(
        (row) => ChartPoint(
          row['month_name']?.toString() ?? '-',
          _toDouble(row['forecast_error']),
        ),
      ),
    );

    final planningByGap = [...monthlyPlanning];
    planningByGap.sort(
      (a, b) => _toDouble(b['forecast_error']).compareTo(
        _toDouble(a['forecast_error']),
      ),
    );

    ownerPlanningRanks.assignAll(
      planningByGap.take(6).map(
            (row) => RankItem(
              title: row['month_name']?.toString() ?? '-',
              subtitle: 'Forecast vs Actual',
              value:
                  '${_toDouble(row['forecast_accuracy']).toStringAsFixed(1)}%',
              badge: row['planning_status']?.toString() ?? 'Planning',
            ),
          ),
    );

    ownerCustomerRanks.assignAll(
      customers.take(6).map(
            (row) => RankItem(
              title: row['customer_id']?.toString() ?? '-',
              subtitle: row['customer_value_segment']?.toString() ?? '-',
              value: currency.format(_toDouble(row['total_net_revenue'])),
              badge: row['buying_frequency_segment']?.toString() ?? 'Customer',
            ),
          ),
    );

    ownerPromoRanks.assignAll(
      promos.take(6).map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: currency.format(_toDouble(row['total_net_revenue'])),
              badge: row['effectiveness_status']?.toString() ?? 'Promo',
            ),
          ),
    );

    final criticalRows = inventory.where((row) {
      final status = _normalize(row['stock_status']);
      return status == 'low_stock' || status == 'out_of_stock';
    }).toList();

    final overstockRows = inventory.where((row) {
      return _normalize(row['stock_status']) == 'overstock';
    }).toList();

    final restockRows = inventory.where((row) {
      final status = _normalize(row['stock_status']);
      final priority = _normalize(row['restock_priority']);

      final isCritical = status == 'low_stock' || status == 'out_of_stock';
      final isOverstock = status == 'overstock';
      final needsRestock = ['urgent', 'high', 'medium'].contains(priority);

      return needsRestock && !isCritical && !isOverstock;
    }).toList();

    final safeRows = inventory.where((row) {
      final status = _normalize(row['stock_status']);
      return ['safe', 'normal', 'aman'].contains(status);
    }).toList();

    final critical = criticalRows.length;
    final restock = restockRows.length;
    final overstock = overstockRows.length;
    final safe = safeRows.length;

    ownerStockStatusChart.assignAll([
      ChartPoint('Aman', safe.toDouble()),
      ChartPoint('Restock', restock.toDouble()),
      ChartPoint('Stok Kritis', critical.toDouble()),
      ChartPoint('Berlebih', overstock.toDouble()),
    ]);

    ownerCriticalStockItems.assignAll(
      criticalRows.take(6).map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: 'Sisa ${_toInt(row['total_ending_inventory'])} stok',
              badge: 'Kritis',
            ),
          ),
    );

    ownerRestockPriority.assignAll(
      restockRows.take(6).map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: 'Sisa ${_toInt(row['total_ending_inventory'])} stok',
              badge: 'Restock',
            ),
          ),
    );

    ownerOverstockItems.assignAll(
      overstockRows.take(6).map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: 'Tersedia ${_toInt(row['total_ending_inventory'])} stok',
              badge: 'Berlebih',
            ),
          ),
    );

    final topProduct = products.isNotEmpty
        ? products.first['product_name']?.toString() ?? '-'
        : '-';

    final insights = <InsightItem>[];

    if (critical > 0) {
      insights.add(
        InsightItem(
          label: 'Stok Kritis',
          value: '$critical produk perlu dicek',
          severity: 'warning',
        ),
      );
    }

    if (topProduct != '-') {
      insights.add(
        InsightItem(
          label: 'Top Seller',
          value: topProduct,
          severity: 'positive',
        ),
      );
    }

    if (customers.isNotEmpty) {
      insights.add(
        InsightItem(
          label: 'Top Customer',
          value: '${customers.length} customer teratas',
          severity: 'neutral',
        ),
      );
    }

    if (promos.isNotEmpty) {
      insights.add(
        InsightItem(
          label: 'Promo',
          value: '${promos.length} promo teratas',
          severity: 'neutral',
        ),
      );
    }

    ownerInsights.assignAll(insights);

    ownerAnalytics.assignAll([
      if (salesTrend.isNotEmpty)
        AnalyticsCategory(
          title: 'Sales',
          subtitle: 'Revenue dan tren penjualan',
          metric: currency.format(
            salesTrend.fold<double>(
              0,
              (a, b) => a + _toDouble(b['total_net_revenue']),
            ),
          ),
          badge: 'Revenue',
          icon: Icons.trending_up_rounded,
        ),
      if (products.isNotEmpty)
        AnalyticsCategory(
          title: 'Product',
          subtitle: 'Produk terlaris dan kontribusi',
          metric: '${products.length} Top Produk',
          badge: 'Top Seller',
          icon: Icons.category_rounded,
        ),
      if (inventory.isNotEmpty)
        AnalyticsCategory(
          title: 'Inventory Ringkas',
          subtitle: 'Stok yang memengaruhi penjualan',
          metric: critical > 0 ? '$critical Perlu Cek' : 'Aman',
          badge: critical > 0 ? 'Stok' : 'Aman',
          icon: Icons.warehouse_rounded,
        ),
      if (customers.isNotEmpty)
        AnalyticsCategory(
          title: 'Customer',
          subtitle: 'Customer dengan nilai pembelian tinggi',
          metric: '${customers.length} Top Customer',
          badge: 'Customer',
          icon: Icons.groups_rounded,
        ),
      if (promos.isNotEmpty)
        AnalyticsCategory(
          title: 'Promotion',
          subtitle: 'Efektivitas promo retail',
          metric: '${promos.length} Top Promo',
          badge: 'Promo',
          icon: Icons.local_offer_rounded,
        ),
      if (monthlyPlanning.isNotEmpty)
        AnalyticsCategory(
          title: 'Planning',
          subtitle: 'Forecast dibanding actual',
          metric: '${monthlyPlanning.length} Bulan',
          badge: 'Forecast',
          icon: Icons.calendar_month_rounded,
        ),
    ]);
  }

  Future<void> _loadOperationalDashboard() async {
    _clearAll();

    final hasSales = await _repository.hasDatasetRows(DatasetCategory.sales);
    final hasProduct =
        await _repository.hasDatasetRows(DatasetCategory.product);
    final hasInventory =
        await _repository.hasDatasetRows(DatasetCategory.inventory);
    final hasLogistic =
        await _repository.hasDatasetRows(DatasetCategory.logistic);

    final canShowInventory = hasInventory;
    final canShowProductMovement = hasSales && hasProduct;
    final canShowLogistics = hasLogistic;

    hasOperationalInventoryData.value = canShowInventory;
    hasOperationalProductData.value = canShowProductMovement;
    hasOperationalLogisticData.value = canShowLogistics;

    final sourceInventory = canShowInventory
        ? _filterRowsBySelectedSite(await _repository.fetchSourceInventory())
        : <Map<String, dynamic>>[];

    final sourceSales = hasSales
        ? _filterRowsBySelectedSite(await _repository.fetchSourceSales())
        : <Map<String, dynamic>>[];

    final sourceProduct = hasProduct
        ? await _repository.fetchSourceProduct()
        : <Map<String, dynamic>>[];

    final sourceLogistic = canShowLogistics
        ? _filterRowsBySelectedSite(await _repository.fetchSourceLogistic())
        : <Map<String, dynamic>>[];

    final inventory = canShowInventory
        ? _buildInventoryFromSource(
            inventoryRows: sourceInventory,
            productRows: sourceProduct,
            salesRows: sourceSales,
          )
        : <Map<String, dynamic>>[];

    final products = canShowProductMovement
        ? _buildProductMovementFromSource(
            salesRows: sourceSales,
            productRows: sourceProduct,
          )
        : <Map<String, dynamic>>[];

    final logistics = canShowLogistics
        ? _buildLogisticsFromSource(sourceLogistic)
        : <Map<String, dynamic>>[];

    final lowStock = inventory
        .where((row) => _normalize(row['stock_status']) == 'low_stock')
        .length;

    final outOfStock = inventory
        .where((row) => _normalize(row['stock_status']) == 'out_of_stock')
        .length;

    final critical = lowStock + outOfStock;

    final restock = inventory
        .where(
          (row) => ['urgent', 'high', 'medium']
              .contains(_normalize(row['restock_priority'])),
        )
        .length;

    final overstock = inventory
        .where((row) => _normalize(row['stock_status']) == 'overstock')
        .length;

    final normalStock = inventory
        .where(
          (row) => ['normal', 'safe'].contains(_normalize(row['stock_status'])),
        )
        .length;

    final delayed = logistics.fold<int>(
      0,
      (total, row) => total + _toInt(row['delayed_shipments']),
    );

    final delivered = logistics.fold<int>(
      0,
      (total, row) => total + _toInt(row['delivered_shipments']),
    );

    final cancelled = logistics.fold<int>(
      0,
      (total, row) => total + _toInt(row['cancelled_shipments']),
    );

    if (!canShowInventory && !canShowProductMovement && !canShowLogistics) {
      _clearOperational();
      return;
    }

    operationalKpis.assignAll([
      KpiMetric(
        title: 'Stok Kritis',
        value: canShowInventory ? number.format(critical) : '-',
        badge: !canShowInventory
            ? 'Butuh Data'
            : critical > 0
                ? 'Cek'
                : 'Aman',
        icon: Icons.warning_rounded,
      ),
      KpiMetric(
        title: 'Restock Priority',
        value: canShowInventory ? number.format(restock) : '-',
        badge: !canShowInventory
            ? 'Butuh Data'
            : restock > 0
                ? 'Prioritaskan'
                : 'Aman',
        icon: Icons.playlist_add_check_rounded,
      ),
      KpiMetric(
        title: 'Delay Risk',
        value: canShowLogistics ? number.format(delayed) : '-',
        badge: !canShowLogistics
            ? 'Butuh Data'
            : delayed > 0
                ? 'Logistik'
                : 'Aman',
        icon: Icons.local_shipping_rounded,
      ),
      KpiMetric(
        title: 'Overstock',
        value: canShowInventory ? number.format(overstock) : '-',
        badge: !canShowInventory
            ? 'Butuh Data'
            : overstock > 0
                ? 'Evaluasi'
                : 'Aman',
        icon: Icons.inventory_2_rounded,
      ),
    ]);

    restockPriority.assignAll(
      inventory
          .where(
            (row) => ['urgent', 'high', 'medium']
                .contains(_normalize(row['restock_priority'])),
          )
          .take(8)
          .map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: '${_toInt(row['total_ending_inventory'])} stok',
              badge: row['restock_priority']?.toString() ?? 'Restock',
            ),
          ),
    );

    criticalStockItems.assignAll(
      inventory
          .where(
            (row) => ['low_stock', 'out_of_stock']
                .contains(_normalize(row['stock_status'])),
          )
          .take(8)
          .map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: '${_toInt(row['total_ending_inventory'])} stok',
              badge: 'Stok Kritis',
            ),
          ),
    );

    overstockItems.assignAll(
      inventory
          .where((row) => _normalize(row['stock_status']) == 'overstock')
          .take(8)
          .map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value: '${_toInt(row['total_ending_inventory'])} stok',
              badge: 'Overstock',
            ),
          ),
    );

    fastMovingProducts.assignAll(
      products.take(5).map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value:
                  '${number.format(_toInt(row['total_units_sold']))} terjual',
              badge: 'Fast Moving',
            ),
          ),
    );

    slowMovingProducts.assignAll(
      products.reversed.take(5).map(
            (row) => RankItem(
              title: row['product_name']?.toString() ?? '-',
              subtitle: row['category']?.toString() ?? '-',
              value:
                  '${number.format(_toInt(row['total_units_sold']))} terjual',
              badge: 'Slow Moving',
            ),
          ),
    );

    logisticsIssues.assignAll(
      logistics
          .where(
            (row) =>
                _toInt(row['delayed_shipments']) > 0 ||
                _toInt(row['cancelled_shipments']) > 0,
          )
          .take(5)
          .map(
            (row) => RankItem(
              title: row['delivery_status']?.toString() ?? '-',
              subtitle: row['transportation_type']?.toString() ?? '-',
              value: '${_toInt(row['total_shipments'])} shipment',
              badge: _toInt(row['delayed_shipments']) > 0
                  ? 'Delay Risk'
                  : 'Cancelled',
            ),
          ),
    );

    operationalInventoryChart.assignAll(
      inventory.take(8).map(
            (row) => ChartPoint(
              row['product_name']?.toString() ?? '-',
              _toDouble(row['total_ending_inventory']),
            ),
          ),
    );

    operationalProductChart.assignAll(
      products.take(8).map(
            (row) => ChartPoint(
              row['product_name']?.toString() ?? '-',
              _toDouble(row['total_units_sold']),
            ),
          ),
    );

    operationalLogisticsChart.assignAll(
      logistics.map(
        (row) => ChartPoint(
          row['transportation_type']?.toString() ?? '-',
          _toDouble(row['delayed_shipments']),
        ),
      ),
    );

    operationalStockStatusChart.assignAll([
      ChartPoint('Aman', normalStock.toDouble()),
      ChartPoint('Menipis', lowStock.toDouble()),
      ChartPoint('Kritis', outOfStock.toDouble()),
      ChartPoint('Overstock', overstock.toDouble()),
    ]);

    operationalLogisticStatusChart.assignAll([
      ChartPoint('Lancar', delivered.toDouble()),
      ChartPoint('Delay', delayed.toDouble()),
      ChartPoint('Cancelled', cancelled.toDouble()),
    ]);

    final analytics = <AnalyticsCategory>[];

    if (canShowInventory) {
      analytics.add(
        AnalyticsCategory(
          title: 'Inventory',
          subtitle: _hasSelectedSiteFilter
              ? 'Status stok dan restock cabang'
              : 'Status stok dan restock',
          metric: '$critical Kritis',
          badge: 'Stok',
          icon: Icons.warehouse_rounded,
        ),
      );
    }

    if (canShowProductMovement) {
      analytics.add(
        AnalyticsCategory(
          title: 'Product Movement',
          subtitle: _hasSelectedSiteFilter
              ? 'Fast/slow moving product cabang'
              : 'Fast/slow moving product',
          metric: '${products.length} Produk',
          badge: 'Movement',
          icon: Icons.category_rounded,
        ),
      );
    }

    if (canShowLogistics) {
      analytics.add(
        AnalyticsCategory(
          title: 'Logistics',
          subtitle: _hasSelectedSiteFilter
              ? 'Shipment dan delivery risk cabang'
              : 'Shipment dan delivery risk',
          metric: '$delayed Delay',
          badge: 'Delay Risk',
          icon: Icons.local_shipping_rounded,
        ),
      );
    }

    operationalAnalytics.assignAll(analytics);
  }

  Map<String, dynamic> _buildOwnerKpiFromSource({
    required List<Map<String, dynamic>> salesRows,
    required List<Map<String, dynamic>> productRows,
  }) {
    final productCostById = <String, double>{};

    for (final product in productRows) {
      final productId = product['product_id']?.toString();

      if (productId != null && productId.isNotEmpty) {
        productCostById[productId] = _toDouble(product['unit_cost']);
      }
    }

    var totalRevenue = 0.0;
    var totalDiscounts = 0.0;
    var totalReturns = 0.0;
    var totalUnitsSold = 0;
    var estimatedCost = 0.0;

    for (final sale in salesRows) {
      final productId = sale['product_id']?.toString() ?? '';
      final units = _toInt(sale['units_sold']);

      totalRevenue += _toDouble(sale['revenue']);
      totalDiscounts += _toDouble(sale['discounts']);
      totalReturns += _toDouble(sale['returns']);
      totalUnitsSold += units;
      estimatedCost += units * (productCostById[productId] ?? 0);
    }

    final totalNetRevenue = totalRevenue - totalDiscounts - totalReturns;
    final estimatedProfit = totalNetRevenue - estimatedCost;

    return {
      'total_revenue': totalRevenue,
      'total_net_revenue': totalNetRevenue,
      'estimated_profit': estimatedProfit < 0 ? 0 : estimatedProfit,
      'total_units_sold': totalUnitsSold,
    };
  }

  List<Map<String, dynamic>> _buildSalesTrendFromSource(
    List<Map<String, dynamic>> salesRows,
  ) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final sale in salesRows) {
      final rawMonth = _toInt(sale['month']);
      final rawYear = _toInt(sale['year']);
      final parsedDate = _parseDate(sale['sales_date'] ?? sale['date']);

      final year = rawYear > 0 ? rawYear : parsedDate?.year ?? 0;
      final month = rawMonth > 0 ? rawMonth : parsedDate?.month ?? 0;

      if (year <= 0 || month <= 0) continue;

      final key = '$year-${month.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(
        key,
        () => {
          'year': year,
          'month': month,
          'month_name': _monthName(month),
          'total_revenue': 0.0,
          'total_net_revenue': 0.0,
        },
      );

      final target = grouped[key]!;

      final revenue = _toDouble(sale['revenue']);
      final discounts = _toDouble(sale['discounts']);
      final returns = _toDouble(sale['returns']);

      target['total_revenue'] = _toDouble(target['total_revenue']) + revenue;
      target['total_net_revenue'] = _toDouble(target['total_net_revenue']) +
          revenue -
          discounts -
          returns;
    }

    final rows = grouped.values.toList();

    rows.sort((a, b) {
      final yearCompare = _toInt(a['year']).compareTo(_toInt(b['year']));
      if (yearCompare != 0) return yearCompare;
      return _toInt(a['month']).compareTo(_toInt(b['month']));
    });

    return rows;
  }

  List<Map<String, dynamic>> _buildCustomerAnalysisFromSource({
    required List<Map<String, dynamic>> salesRows,
    required List<Map<String, dynamic>> customerRows,
  }) {
    final customerById = <String, Map<String, dynamic>>{};

    for (final customer in customerRows) {
      final customerId = customer['customer_id']?.toString();

      if (customerId != null && customerId.isNotEmpty) {
        customerById[customerId] = customer;
      }
    }

    final grouped = <String, Map<String, dynamic>>{};

    for (final sale in salesRows) {
      final customerId = sale['customer_id']?.toString();

      if (customerId == null || customerId.isEmpty) continue;

      grouped.putIfAbsent(
        customerId,
        () => {
          'customer_id': customerId,
          'total_net_revenue': 0.0,
          'purchase_count': 0,
        },
      );

      final target = grouped[customerId]!;

      final revenue = _toDouble(sale['revenue']);
      final discounts = _toDouble(sale['discounts']);
      final returns = _toDouble(sale['returns']);

      target['total_net_revenue'] = _toDouble(target['total_net_revenue']) +
          revenue -
          discounts -
          returns;
      target['purchase_count'] = _toInt(target['purchase_count']) + 1;
    }

    final rows = grouped.values.toList();

    rows.sort(
      (a, b) => _toDouble(b['total_net_revenue']).compareTo(
        _toDouble(a['total_net_revenue']),
      ),
    );

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final customer = customerById[row['customer_id']?.toString() ?? ''];

      row['customer_value_segment'] = i < 3
          ? 'high_value'
          : i < 8
              ? 'medium_value'
              : 'low_value';

      final purchaseCount = _toInt(row['purchase_count']);

      row['buying_frequency_segment'] = purchaseCount >= 5
          ? 'frequent'
          : purchaseCount >= 2
              ? 'regular'
              : 'occasional';

      if (customer != null) {
        row['gender'] = customer['gender'];
        row['income_bracket'] = customer['income_bracket'];
        row['age'] = customer['age'];
      }
    }

    return rows;
  }

  List<Map<String, dynamic>> _buildPromotionPerformanceFromSource({
    required List<Map<String, dynamic>> salesRows,
    required List<Map<String, dynamic>> productRows,
    required List<Map<String, dynamic>> promotionRows,
  }) {
    final productById = <String, Map<String, dynamic>>{};

    for (final product in productRows) {
      final productId = product['product_id']?.toString();

      if (productId != null && productId.isNotEmpty) {
        productById[productId] = product;
      }
    }

    final grouped = <String, Map<String, dynamic>>{};

    for (final promo in promotionRows) {
      final promotionId = promo['promotion_id']?.toString() ?? '';
      final promoProductId = promo['product_id']?.toString() ?? '';
      final promoSiteId = promo['site_id']?.toString() ?? '';
      final start = _parseDate(promo['start_date']);
      final end = _parseDate(promo['end_date']);

      if (promotionId.isEmpty || promoProductId.isEmpty) continue;

      for (final sale in salesRows) {
        final saleProductId = sale['product_id']?.toString() ?? '';
        final saleSiteId = sale['site_id']?.toString() ?? '';
        final saleDate = _parseDate(sale['sales_date'] ?? sale['date']);

        final sameProduct = saleProductId == promoProductId;
        final sameSite = promoSiteId.isEmpty || saleSiteId == promoSiteId;
        final inPeriod = saleDate == null ||
            start == null ||
            end == null ||
            (!saleDate.isBefore(start) && !saleDate.isAfter(end));

        if (!sameProduct || !sameSite || !inPeriod) continue;

        grouped.putIfAbsent(promotionId, () {
          final product = productById[promoProductId];

          return {
            'promotion_id': promotionId,
            'product_id': promoProductId,
            'product_name':
                product?['product_name']?.toString() ?? promoProductId,
            'category': product?['category']?.toString() ?? '-',
            'total_net_revenue': 0.0,
            'effectiveness_status': 'Promo Aktif',
          };
        });

        final target = grouped[promotionId]!;

        final revenue = _toDouble(sale['revenue']);
        final discounts = _toDouble(sale['discounts']);
        final returns = _toDouble(sale['returns']);

        target['total_net_revenue'] = _toDouble(target['total_net_revenue']) +
            revenue -
            discounts -
            returns;
      }
    }

    final rows = grouped.values.toList();

    rows.sort(
      (a, b) => _toDouble(b['total_net_revenue']).compareTo(
        _toDouble(a['total_net_revenue']),
      ),
    );

    return rows;
  }

  List<Map<String, dynamic>> _buildPlanningPerformanceFromSource(
    List<Map<String, dynamic>> planningRows,
  ) {
    final rows = planningRows.map((row) {
      final forecast = _toDouble(row['forecasted_sales']);
      final actual = _toDouble(row['actual_sales']);
      final error = (actual - forecast).abs();
      final accuracy = forecast <= 0
          ? 0.0
          : ((1 - (error / forecast)) * 100).clamp(0, 100).toDouble();

      return {
        'month': row['month'],
        'month_name': row['month']?.toString() ?? '-',
        'month_date': row['month_date'],
        'product_category': row['product_category']?.toString() ?? '-',
        'forecasted_sales': forecast,
        'actual_sales': actual,
        'forecast_error': error,
        'forecast_accuracy': accuracy,
        'planning_status': accuracy >= 80
            ? 'Forecast Akurat'
            : accuracy >= 60
                ? 'Perlu Evaluasi'
                : 'Gap Tinggi',
      };
    }).toList();

    rows.sort((a, b) {
      final aDate = _parseDate(a['month_date'] ?? a['month']);
      final bDate = _parseDate(b['month_date'] ?? b['month']);

      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });

    return rows;
  }

  List<Map<String, dynamic>> _buildInventoryFromSource({
    required List<Map<String, dynamic>> inventoryRows,
    required List<Map<String, dynamic>> productRows,
    required List<Map<String, dynamic>> salesRows,
  }) {
    final productById = <String, Map<String, dynamic>>{};

    for (final product in productRows) {
      final productId = product['product_id']?.toString();

      if (productId != null && productId.isNotEmpty) {
        productById[productId] = product;
      }
    }

    final salesByProduct = <String, int>{};

    for (final sale in salesRows) {
      final productId = sale['product_id']?.toString();

      if (productId == null || productId.isEmpty) continue;

      salesByProduct[productId] =
          (salesByProduct[productId] ?? 0) + _toInt(sale['units_sold']);
    }

    final groupedInventory = <String, Map<String, dynamic>>{};

    for (final row in inventoryRows) {
      final productId = row['product_id']?.toString() ?? '';

      if (productId.isEmpty) continue;

      groupedInventory.putIfAbsent(
        productId,
        () => {
          'product_id': productId,
          'beginning_inventory': 0,
          'ending_inventory': 0,
          'replenishment': 0,
          'stockout_flag': 'No',
        },
      );

      final target = groupedInventory[productId]!;

      target['beginning_inventory'] = _toInt(target['beginning_inventory']) +
          _toInt(row['beginning_inventory']);

      target['ending_inventory'] =
          _toInt(target['ending_inventory']) + _toInt(row['ending_inventory']);

      target['replenishment'] =
          _toInt(target['replenishment']) + _toInt(row['replenishment']);

      final flag = _normalize(row['stockout_flag']);

      if (flag == 'yes' ||
          flag == 'true' ||
          flag == '1' ||
          flag == 'stockout') {
        target['stockout_flag'] = 'Yes';
      }
    }

    final rows = groupedInventory.values.map((row) {
      final productId = row['product_id']?.toString() ?? '';
      final product = productById[productId];

      final beginningInventory = _toInt(row['beginning_inventory']);
      final endingInventory = _toInt(row['ending_inventory']);
      final replenishment = _toInt(row['replenishment']);
      final sold = salesByProduct[productId] ?? 0;

      final stockoutFlag = _normalize(row['stockout_flag']);
      final baseStock = beginningInventory + replenishment;

      var lowThreshold = baseStock <= 0 ? 10 : (baseStock * 0.20).round();
      if (lowThreshold < 10) lowThreshold = 10;

      var overstockThreshold = baseStock <= 0 ? 80 : (baseStock * 0.80).round();
      if (overstockThreshold < 50) overstockThreshold = 50;

      final isStockout = stockoutFlag == 'yes' ||
          stockoutFlag == 'true' ||
          stockoutFlag == '1' ||
          stockoutFlag == 'stockout';

      String stockStatus;
      String restockPriority;

      if (isStockout || endingInventory <= 0) {
        stockStatus = 'out_of_stock';
        restockPriority = 'urgent';
      } else if (sold > 0 && endingInventory <= (sold * 0.5).round()) {
        stockStatus = 'low_stock';
        restockPriority = 'high';
      } else if (endingInventory <= lowThreshold) {
        stockStatus = 'low_stock';
        restockPriority = 'medium';
      } else if (endingInventory >= overstockThreshold && sold <= 10) {
        stockStatus = 'overstock';
        restockPriority = 'low';
      } else {
        stockStatus = 'safe';
        restockPriority = 'low';
      }

      return {
        'product_id': productId,
        'product_name': product?['product_name']?.toString() ??
            (productId.isEmpty ? 'Produk tanpa ID' : productId),
        'category': product?['category']?.toString() ?? '-',
        'total_beginning_inventory': beginningInventory,
        'total_ending_inventory': endingInventory,
        'total_replenishment': replenishment,
        'total_units_sold': sold,
        'stock_status': stockStatus,
        'restock_priority': restockPriority,
      };
    }).toList();

    rows.sort(
      (a, b) => _toInt(b['total_ending_inventory']).compareTo(
        _toInt(a['total_ending_inventory']),
      ),
    );

    return rows;
  }

  List<Map<String, dynamic>> _buildProductMovementFromSource({
    required List<Map<String, dynamic>> salesRows,
    required List<Map<String, dynamic>> productRows,
  }) {
    final productById = <String, Map<String, dynamic>>{};

    for (final product in productRows) {
      final productId = product['product_id']?.toString();

      if (productId != null && productId.isNotEmpty) {
        productById[productId] = product;
      }
    }

    final unitsByProduct = <String, int>{};
    final revenueByProduct = <String, double>{};
    final returnsByProduct = <String, int>{};

    for (final sale in salesRows) {
      final productId = sale['product_id']?.toString();

      if (productId == null || productId.isEmpty) continue;

      unitsByProduct[productId] =
          (unitsByProduct[productId] ?? 0) + _toInt(sale['units_sold']);

      final netRevenue = _toDouble(sale['revenue']) -
          _toDouble(sale['discounts']) -
          _toDouble(sale['returns']);

      revenueByProduct[productId] =
          (revenueByProduct[productId] ?? 0) + netRevenue;

      returnsByProduct[productId] =
          (returnsByProduct[productId] ?? 0) + _toInt(sale['returns']);
    }

    final rows = unitsByProduct.entries.map((entry) {
      final productId = entry.key;
      final product = productById[productId];

      return {
        'product_id': productId,
        'product_name': product?['product_name']?.toString() ?? productId,
        'category': product?['category']?.toString() ?? '-',
        'total_units_sold': entry.value,
        'total_revenue': revenueByProduct[productId] ?? 0,
        'total_net_revenue': revenueByProduct[productId] ?? 0,
        'total_returns': returnsByProduct[productId] ?? 0,
        'stock_status': 'safe',
      };
    }).toList();

    rows.sort(
      (a, b) => _toInt(b['total_units_sold'])
          .compareTo(_toInt(a['total_units_sold'])),
    );

    return rows;
  }

  List<Map<String, dynamic>> _buildLogisticsFromSource(
    List<Map<String, dynamic>> logisticRows,
  ) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final row in logisticRows) {
      final transportationType =
          row['transportation_type']?.toString() ?? 'Tidak diketahui';
      final deliveryStatus = row['delivery_status']?.toString() ?? '-';
      final normalizedStatus = _normalize(deliveryStatus);

      grouped.putIfAbsent(
        transportationType,
        () => {
          'delivery_status': 'Ringkasan',
          'transportation_type': transportationType,
          'total_shipments': 0,
          'total_quantity_shipped': 0,
          'delivered_shipments': 0,
          'delayed_shipments': 0,
          'cancelled_shipments': 0,
        },
      );

      final target = grouped[transportationType]!;

      target['total_shipments'] = _toInt(target['total_shipments']) + 1;
      target['total_quantity_shipped'] =
          _toInt(target['total_quantity_shipped']) + _toInt(row['quantity']);

      if (normalizedStatus.contains('delay')) {
        target['delayed_shipments'] = _toInt(target['delayed_shipments']) + 1;
      } else if (normalizedStatus.contains('cancel')) {
        target['cancelled_shipments'] =
            _toInt(target['cancelled_shipments']) + 1;
      } else {
        target['delivered_shipments'] =
            _toInt(target['delivered_shipments']) + 1;
      }
    }

    return grouped.values.toList();
  }

  List<KpiMetric> _ownerKpisFrom(Map<String, dynamic>? row) {
    if (row == null) return [];

    final totalRevenue = _toDouble(row['total_revenue']);
    final totalNetRevenue = _toDouble(row['total_net_revenue']);
    final estimatedProfit = _toDouble(row['estimated_profit']);
    final totalUnitsSold = _toInt(row['total_units_sold']);

    final kpis = <KpiMetric>[
      KpiMetric(
        title: 'Total Revenue',
        value: currency.format(totalRevenue),
        badge: 'Revenue',
        icon: Icons.payments_rounded,
      ),
      KpiMetric(
        title: 'Net Revenue',
        value: currency.format(totalNetRevenue),
        badge: 'Net',
        icon: Icons.account_balance_wallet_rounded,
      ),
      KpiMetric(
        title: 'Produk Terjual',
        value: number.format(totalUnitsSold),
        badge: 'Terjual',
        icon: Icons.shopping_bag_rounded,
      ),
    ];

    if (estimatedProfit > 0) {
      kpis.insert(
        2,
        KpiMetric(
          title: 'Estimasi Profit',
          value: currency.format(estimatedProfit),
          badge: 'Profit',
          icon: Icons.trending_up_rounded,
        ),
      );
    }

    return kpis;
  }

  String _stockBadge(dynamic status) {
    switch (_normalize(status)) {
      case 'low_stock':
      case 'out_of_stock':
        return 'Stok Kritis';
      case 'overstock':
        return 'Overstock';
      default:
        return 'Top Seller';
    }
  }

  List<Map<String, dynamic>> _aggregatePlanningByMonth(
    List<Map<String, dynamic>> rows,
  ) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final monthDate = row['month_date']?.toString().trim();
      final month = row['month']?.toString().trim();

      final key = monthDate != null && monthDate.isNotEmpty
          ? monthDate
          : month != null && month.isNotEmpty
              ? month
              : '-';

      grouped.putIfAbsent(
        key,
        () => {
          'month_date': monthDate,
          'month_name': month != null && month.isNotEmpty
              ? month
              : _monthNameFromDateText(monthDate),
          'forecasted_sales': 0.0,
          'actual_sales': 0.0,
        },
      );

      grouped[key]!['forecasted_sales'] =
          _toDouble(grouped[key]!['forecasted_sales']) +
              _toDouble(row['forecasted_sales']);

      grouped[key]!['actual_sales'] = _toDouble(grouped[key]!['actual_sales']) +
          _toDouble(row['actual_sales']);
    }

    final result = grouped.values.toList();

    result.sort((a, b) {
      final aDate = _parseDate(a['month_date'] ?? a['month_name']);
      final bDate = _parseDate(b['month_date'] ?? b['month_name']);

      if (aDate != null && bDate != null) {
        return aDate.compareTo(bDate);
      }

      return a['month_name'].toString().compareTo(b['month_name'].toString());
    });

    for (final row in result) {
      final forecast = _toDouble(row['forecasted_sales']);
      final actual = _toDouble(row['actual_sales']);
      final error = (actual - forecast).abs();
      final gapPercent = forecast <= 0 ? 0.0 : (error / forecast) * 100;
      final accuracy = forecast <= 0
          ? 0.0
          : ((1 - (error / forecast)) * 100).clamp(0, 100).toDouble();

      row['forecast_error'] = error;
      row['forecast_gap_percent'] = gapPercent;
      row['forecast_accuracy'] = accuracy;
      row['planning_status'] = accuracy >= 80
          ? 'Forecast Akurat'
          : accuracy >= 60
              ? 'Perlu Evaluasi'
              : 'Gap Tinggi';
    }

    return result;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final isoDate = DateTime.tryParse(text);
    if (isoDate != null) return isoDate;

    final numericDatePattern = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
    final numericMatch = numericDatePattern.firstMatch(text);

    if (numericMatch != null) {
      final day = int.tryParse(numericMatch.group(1) ?? '');
      final month = int.tryParse(numericMatch.group(2) ?? '');
      final year = int.tryParse(numericMatch.group(3) ?? '');

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    final monthYearPattern = RegExp(r'^([A-Za-z]+)[-\s](\d{4})$');
    final monthYearMatch = monthYearPattern.firstMatch(text);

    if (monthYearMatch != null) {
      final monthText = monthYearMatch.group(1)?.toLowerCase();
      final year = int.tryParse(monthYearMatch.group(2) ?? '');

      final month = _monthNumber(monthText);

      if (month != null && year != null) {
        return DateTime(year, month, 1);
      }
    }

    return null;
  }

  int? _monthNumber(String? value) {
    switch (value?.toLowerCase()) {
      case 'jan':
      case 'january':
      case 'januari':
        return 1;
      case 'feb':
      case 'february':
      case 'februari':
        return 2;
      case 'mar':
      case 'march':
      case 'maret':
        return 3;
      case 'apr':
      case 'april':
        return 4;
      case 'may':
      case 'mei':
        return 5;
      case 'jun':
      case 'june':
      case 'juni':
        return 6;
      case 'jul':
      case 'july':
      case 'juli':
        return 7;
      case 'aug':
      case 'august':
      case 'agu':
      case 'agustus':
        return 8;
      case 'sep':
      case 'sept':
      case 'september':
        return 9;
      case 'oct':
      case 'october':
      case 'okt':
      case 'oktober':
        return 10;
      case 'nov':
      case 'november':
        return 11;
      case 'dec':
      case 'december':
      case 'des':
      case 'desember':
        return 12;
      default:
        return null;
    }
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    if (month < 1 || month > 12) return '-';

    return names[month - 1];
  }

  String _monthNameFromDateText(String? value) {
    final date = _parseDate(value);

    if (date == null) return value?.toString() ?? '-';

    return _monthName(date.month);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    var text = value.toString().trim();

    if (text.isEmpty || text == '-') return 0;

    text = text
        .replaceAll('Rp', '')
        .replaceAll('IDR', '')
        .replaceAll('₹', '')
        .replaceAll('INR', '')
        .replaceAll('%', '')
        .replaceAll(' ', '')
        .trim();

    final hasComma = text.contains(',');
    final hasDot = text.contains('.');

    if (hasComma && hasDot) {
      if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (hasComma) {
      text = text.replaceAll(',', '.');
    }

    return double.tryParse(text) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();

    return _toDouble(value).round();
  }

  String _normalize(dynamic value) {
    return value
            ?.toString()
            .trim()
            .toLowerCase()
            .replaceAll('-', '_')
            .replaceAll(' ', '_') ??
        '';
  }

  void _clearAll() {
    _clearOwner();
    _clearOperational();
  }

  void _clearOwner() {
    ownerKpis.clear();
    ownerRevenueTrend.clear();
    ownerTopProducts.clear();
    ownerInsights.clear();

    ownerProductChart.clear();
    ownerInventoryChart.clear();
    ownerCustomerChart.clear();
    ownerPromoChart.clear();
    ownerPlanningChart.clear();
    ownerPlanningForecastChart.clear();
    ownerPlanningActualChart.clear();
    ownerPlanningErrorChart.clear();

    ownerCustomerRanks.clear();
    ownerPromoRanks.clear();
    ownerPlanningRanks.clear();

    ownerCriticalStockItems.clear();
    ownerRestockPriority.clear();
    ownerOverstockItems.clear();
    ownerStockStatusChart.clear();

    ownerAnalytics.clear();
  }

  void _clearOperational() {
    operationalKpis.clear();
    restockPriority.clear();
    criticalStockItems.clear();
    overstockItems.clear();
    fastMovingProducts.clear();
    slowMovingProducts.clear();
    logisticsIssues.clear();

    operationalInventoryChart.clear();
    operationalProductChart.clear();
    operationalLogisticsChart.clear();
    operationalStockStatusChart.clear();
    operationalLogisticStatusChart.clear();

    hasOperationalInventoryData.value = false;
    hasOperationalProductData.value = false;
    hasOperationalLogisticData.value = false;

    operationalAnalytics.clear();
  }
}
