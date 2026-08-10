import 'dart:convert';

import 'package:flutter/services.dart';

import 'contract.dart';
import 'quotation.dart';
import 'template.dart';

/// seed JSON 解析结果
class BusinessData {
  const BusinessData({
    required this.quotations,
    required this.contracts,
    required this.templates,
  });

  factory BusinessData.fromJson(Map<String, dynamic> json) {
    return BusinessData(
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

  final List<Quotation> quotations;
  final List<Contract> contracts;
  final List<BusinessTemplate> templates;

  List<BusinessTemplate> get quotationTemplates =>
      templates.where((t) => t.isQuotation).toList();

  List<BusinessTemplate> get contractTemplates =>
      templates.where((t) => t.isContract).toList();
}

/// 从 seed JSON 异步加载商务数据（报价、合同、模板）
Future<BusinessData> loadSeedBusiness() async {
  final raw = await rootBundle.loadString('assets/data/seed_business.json');
  return BusinessData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
