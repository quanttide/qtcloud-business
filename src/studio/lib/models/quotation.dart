import 'log_entry.dart';

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
    this.logs = const [],
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
      logs: (json['logs'] as List<dynamic>? ?? [])
          .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
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

  /// 往来留痕（追加式：邮件确认/电话/会议/变更协议）
  final List<LogEntry> logs;

  /// 当前版本是否为最新
  bool get isLatest => versions.isEmpty || versions.first.version == version;

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'name': name,
    'client': client,
    'template': template,
    'status': status,
    'version': version,
    'created': created,
    'updated': updated,
    'pricingNote': pricingNote,
    'products': products.map((e) => e.toJson()).toList(),
    'totalAmount': totalAmount,
    'versions': versions.map((e) => e.toJson()).toList(),
    'logs': logs.map((e) => e.toJson()).toList(),
  };

  Quotation copyWith({
    String? id,
    String? businessId,
    String? name,
    String? client,
    String? template,
    String? status,
    int? version,
    String? created,
    String? updated,
    String? pricingNote,
    List<QuotationProduct>? products,
    double? totalAmount,
    List<QuotationVersion>? versions,
    List<LogEntry>? logs,
  }) {
    return Quotation(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      client: client ?? this.client,
      template: template ?? this.template,
      status: status ?? this.status,
      version: version ?? this.version,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      pricingNote: pricingNote ?? this.pricingNote,
      products: products ?? this.products,
      totalAmount: totalAmount ?? this.totalAmount,
      versions: versions ?? this.versions,
      logs: logs ?? this.logs,
    );
  }
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'discount': discount,
  };
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

  Map<String, dynamic> toJson() => {
    'version': version,
    'updated': updated,
    'totalAmount': totalAmount,
    'note': note,
  };
}
