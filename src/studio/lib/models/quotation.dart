/// 报价单模型（报价制定 · 报价单生成）
class Quotation {
  const Quotation({
    required this.id,
    required this.name,
    required this.client,
    required this.template,
    required this.status,
    required this.version,
    required this.created,
    required this.updated,
    required this.pricingNote,
    required this.products,
    required this.totalAmount,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] as String,
      name: json['name'] as String,
      client: json['client'] as String,
      template: json['template'] as String? ?? '',
      status: json['status'] as String,
      version: json['version'] as int,
      created: json['created'] as String,
      updated: json['updated'] as String,
      pricingNote: json['pricingNote'] as String? ?? '',
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => QuotationProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String client;
  final String template;
  final String status;
  final int version;
  final String created;
  final String updated;
  final String pricingNote;
  final List<QuotationProduct> products;
  final double totalAmount;
}

/// 报价单产品明细（产品、单价、数量、折扣）
class QuotationProduct {
  const QuotationProduct({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.discount,
  });

  factory QuotationProduct.fromJson(Map<String, dynamic> json) {
    return QuotationProduct(
      name: json['name'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
    );
  }

  final String name;
  final double unitPrice;
  final double quantity;
  final double discount;
}
