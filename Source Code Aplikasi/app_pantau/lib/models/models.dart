import 'package:flutter/material.dart';

enum UserRole { owner, operational, superadmin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.operational:
        return 'Admin Operasional';
      case UserRole.superadmin:
        return 'Superadmin';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.owner:
        return Icons.storefront_rounded;
      case UserRole.operational:
        return Icons.inventory_2_rounded;
      case UserRole.superadmin:
        return Icons.admin_panel_settings_rounded;
    }
  }
}

enum DatasetCategory {
  sales,
  product,
  inventory,
  customer,
  promotion,
  logistic,
  planning,
  site,
}

extension DatasetCategoryX on DatasetCategory {
  String get label {
    switch (this) {
      case DatasetCategory.sales:
        return 'Sales';
      case DatasetCategory.product:
        return 'Product';
      case DatasetCategory.inventory:
        return 'Inventory';
      case DatasetCategory.customer:
        return 'Customer';
      case DatasetCategory.promotion:
        return 'Promotion';
      case DatasetCategory.logistic:
        return 'Logistic';
      case DatasetCategory.planning:
        return 'Planning';
      case DatasetCategory.site:
        return 'Site';
    }
  }

  String get tableName {
    switch (this) {
      case DatasetCategory.sales:
        return 'sales';
      case DatasetCategory.product:
        return 'product';
      case DatasetCategory.inventory:
        return 'inventory';
      case DatasetCategory.customer:
        return 'customer';
      case DatasetCategory.promotion:
        return 'promotion';
      case DatasetCategory.logistic:
        return 'logistic';
      case DatasetCategory.planning:
        return 'planning';
      case DatasetCategory.site:
        return 'site';
    }
  }

  String get keyColumn {
    switch (this) {
      case DatasetCategory.sales:
        return 'site_id';
      case DatasetCategory.product:
        return 'product_id';
      case DatasetCategory.inventory:
        return 'site_id';
      case DatasetCategory.customer:
        return 'customer_id';
      case DatasetCategory.promotion:
        return 'promotion_id';
      case DatasetCategory.logistic:
        return 'shipment_id';
      case DatasetCategory.planning:
        return 'month';
      case DatasetCategory.site:
        return 'site_id';
    }
  }

  IconData get icon {
    switch (this) {
      case DatasetCategory.sales:
        return Icons.trending_up_rounded;
      case DatasetCategory.product:
        return Icons.category_rounded;
      case DatasetCategory.inventory:
        return Icons.warehouse_rounded;
      case DatasetCategory.customer:
        return Icons.groups_rounded;
      case DatasetCategory.promotion:
        return Icons.local_offer_rounded;
      case DatasetCategory.logistic:
        return Icons.local_shipping_rounded;
      case DatasetCategory.planning:
        return Icons.calendar_month_rounded;
      case DatasetCategory.site:
        return Icons.store_mall_directory_rounded;
    }
  }

  List<String> get columns {
    switch (this) {
      case DatasetCategory.customer:
        return [
          'customer_id',
          'age',
          'gender',
          'income_bracket',
          'purchase_frequency',
          'average_spend'
        ];
      case DatasetCategory.inventory:
        return [
          'site_id',
          'product_id',
          'beginning_inventory',
          'ending_inventory',
          'replenishment',
          'stockout_flag'
        ];
      case DatasetCategory.logistic:
        return [
          'shipment_id',
          'site_id',
          'product_id',
          'shipment_date',
          'quantity',
          'delivery_status',
          'transportation_type'
        ];
      case DatasetCategory.planning:
        return [
          'month',
          'site_id',
          'product_category',
          'forecasted_sales',
          'actual_sales',
          'seasonal_adjustments',
          'month_date'
        ];
      case DatasetCategory.product:
        return [
          'product_id',
          'product_name',
          'category',
          'subcategory',
          'unit_cost',
          'unit_price',
          'supplier',
          'shelf_life'
        ];
      case DatasetCategory.promotion:
        return [
          'promotion_id',
          'product_id',
          'site_id',
          'start_date',
          'end_date',
          'discount_type',
          'discount_amount'
        ];
      case DatasetCategory.sales:
        return [
          'date',
          'site_id',
          'product_id',
          'units_sold',
          'revenue',
          'discounts',
          'returns',
          'customer_id',
          'sales_date',
          'year',
          'quarter',
          'month',
          'month_name',
          'day',
          'day_name'
        ];
      case DatasetCategory.site:
        return [
          'site_id',
          'site_name',
          'site_format',
          'region',
          'city',
          'state',
          'store_size',
          'open_date',
          'status'
        ];
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;

  AppUser copyWith(
      {String? id,
      String? name,
      String? email,
      UserRole? role,
      bool? isActive}) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

class DatasetSummary {
  const DatasetSummary({
    required this.category,
    required this.rows,
    required this.statusLabel,
  });

  final DatasetCategory category;
  final int rows;
  final String statusLabel;
}

class KpiMetric {
  const KpiMetric(
      {required this.title,
      required this.value,
      required this.badge,
      required this.icon});
  final String title;
  final String value;
  final String badge;
  final IconData icon;
}

class ChartPoint {
  const ChartPoint(this.label, this.value);
  final String label;
  final double value;
}

class RankItem {
  const RankItem(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.badge});
  final String title;
  final String subtitle;
  final String value;
  final String badge;
}

class InsightItem {
  const InsightItem(
      {required this.label, required this.value, required this.severity});
  final String label;
  final String value;
  final String severity;
}

class AnalyticsCategory {
  const AnalyticsCategory({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String metric;
  final String badge;
  final IconData icon;
}

class SiteOption {
  const SiteOption({
    required this.siteId,
    required this.siteName,
    this.siteFormat,
    this.city,
    this.state,
  });

  final String siteId;
  final String siteName;
  final String? siteFormat;
  final String? city;
  final String? state;
}
