import 'quotation.dart';

/// 业务模板（报价单模板 / 合同模板）
class BusinessTemplate {
  const BusinessTemplate({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.products,
    required this.sections,
  });

  factory BusinessTemplate.fromJson(Map<String, dynamic> json) {
    return BusinessTemplate(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => QuotationProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  static const String typeQuotation = 'quotation';
  static const String typeContract = 'contract';

  final String id;
  final String type;
  final String name;
  final String description;

  /// 报价单模板：默认产品明细
  final List<QuotationProduct> products;

  /// 合同模板：条款章节
  final List<String> sections;

  bool get isQuotation => type == typeQuotation;
  bool get isContract => type == typeContract;
}
