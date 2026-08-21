/// 报价单模型（报价制定 · 报价单生成）
class Quotation {
  const Quotation({
    required this.id,
    required this.businessId,
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
    required this.versions,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final versions = (json['versions'] as List<dynamic>? ?? [])
        .map((e) => QuotationVersion.fromJson(e as Map<String, dynamic>))
        .toList();
    return Quotation(
      id: json['id'] as String,
      businessId: json['businessId'] as String? ?? '',
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
      versions: versions,
    );
  }

  final String id;

  /// 所属业务 id（订单是业务的实例）
  final String businessId;
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

  /// 报价历史版本（降序：最新在前）
  final List<QuotationVersion> versions;

  /// 当前版本是否为最新
  bool get isLatest => versions.isEmpty || versions.first.version == version;
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

  /// 小计 = 单价 × 数量 × 折扣
  double get subtotal => unitPrice * quantity * discount;
}

/// 报价历史版本记录
class QuotationVersion {
  const QuotationVersion({
    required this.version,
    required this.updated,
    required this.totalAmount,
    required this.note,
  });

  factory QuotationVersion.fromJson(Map<String, dynamic> json) {
    return QuotationVersion(
      version: json['version'] as int,
      updated: json['updated'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      note: json['note'] as String? ?? '',
    );
  }

  final int version;
  final String updated;
  final double totalAmount;
  final String note;
}
