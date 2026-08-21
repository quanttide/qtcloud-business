import 'dart:convert';

import 'package:flutter/services.dart';

import 'business.dart';
import 'contract.dart';
import 'quotation.dart';
import 'template.dart';

/// seed JSON 解析结果
class BusinessData {
  const BusinessData({
    required this.businesses,
    required this.quotations,
    required this.contracts,
    required this.templates,
  });

  factory BusinessData.fromJson(Map<String, dynamic> json) {
    return BusinessData(
      businesses: (json['businesses'] as List<dynamic>? ?? [])
          .map((e) => Business.fromJson(e as Map<String, dynamic>))
          .toList(),
      quotations: (json['quotations'] as List<dynamic>? ?? [])
          .map((e) => Quotation.fromJson(e as Map<String, dynamic>))
          .toList(),
      contracts: (json['contracts'] as List<dynamic>? ?? [])
          .map((e) => Contract.fromJson(e as Map<String, dynamic>))
          .toList(),
      templates: (json['templates'] as List<dynamic>? ?? [])
          .map((e) => BusinessTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 业务（类）：报价规则与模板定义在此
  final List<Business> businesses;
  final List<Quotation> quotations;
  final List<Contract> contracts;
  final List<BusinessTemplate> templates;

  List<BusinessTemplate> get quotationTemplates =>
      templates.where((t) => t.isQuotation).toList();

  List<BusinessTemplate> get contractTemplates =>
      templates.where((t) => t.isContract).toList();

  Business? businessById(String id) {
    for (final b in businesses) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<Quotation> quotationsOf(String businessId) =>
      quotations.where((q) => q.businessId == businessId).toList();

  List<Contract> contractsOf(String businessId) =>
      contracts.where((c) => c.businessId == businessId).toList();

  Map<String, dynamic> toJson() => {
    'businesses': businesses.map((e) => e.toJson()).toList(),
    'quotations': quotations.map((e) => e.toJson()).toList(),
    'contracts': contracts.map((e) => e.toJson()).toList(),
    'templates': templates.map((e) => e.toJson()).toList(),
  };
}

/// 从 seed JSON 异步加载商务数据（业务、报价、合同、模板）
Future<BusinessData> loadSeedBusiness() async {
  final raw = await rootBundle.loadString('assets/data/seed_business.json');
  return BusinessData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
