/// 合同模型（合同管理 · 签约流程与履约跟踪）
class Contract {
  const Contract({
    required this.id,
    required this.businessId,
    required this.name,
    required this.client,
    required this.template,
    required this.status,
    required this.amount,
    required this.created,
    required this.signed,
    required this.fulfillments,
    this.payments = const [],
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String,
      businessId: json['businessId'] as String? ?? '',
      name: json['name'] as String,
      client: json['client'] as String,
      template: json['template'] as String? ?? '',
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      created: json['created'] as String,
      signed: json['signed'] as String? ?? '',
      fulfillments: (json['fulfillments'] as List<dynamic>? ?? [])
          .map((e) => Fulfillment.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => PaymentNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessId': businessId,
    'name': name,
    'client': client,
    'template': template,
    'status': status,
    'amount': amount,
    'created': created,
    'signed': signed,
    'fulfillments': fulfillments.map((e) => e.toJson()).toList(),
    'payments': payments.map((e) => e.toJson()).toList(),
  };

  final String id;

  /// 所属业务 id（订单是业务的实例）
  final String businessId;
  final String name;
  final String client;
  final String template;
  final String status;
  final double amount;
  final String created;
  final String signed;
  final List<Fulfillment> fulfillments;

  /// 付款节点（到账进度：到一笔勾一笔）
  final List<PaymentNode> payments;

  /// 已到账金额（万元）
  double get receivedAmount => payments
      .where((p) => p.received)
      .fold(0.0, (sum, p) => sum + p.ratio * amount);

  Contract copyWith({
    String? id,
    String? businessId,
    String? name,
    String? client,
    String? template,
    String? status,
    double? amount,
    String? created,
    String? signed,
    List<Fulfillment>? fulfillments,
    List<PaymentNode>? payments,
  }) {
    return Contract(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      client: client ?? this.client,
      template: template ?? this.template,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      created: created ?? this.created,
      signed: signed ?? this.signed,
      fulfillments: fulfillments ?? this.fulfillments,
      payments: payments ?? this.payments,
    );
  }
}

/// 履约条目（发送签署、签署、付款、交付等）
class Fulfillment {
  const Fulfillment({
    required this.name,
    required this.status,
    required this.date,
  });

  factory Fulfillment.fromJson(Map<String, dynamic> json) {
    return Fulfillment(
      name: json['name'] as String,
      status: json['status'] as String,
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'status': status, 'date': date};

  final String name;
  final String status;
  final String date;
}

/// 付款节点：名称 + 比例 + 是否到账
class PaymentNode {
  const PaymentNode({
    required this.name,
    required this.ratio,
    this.received = false,
    this.date = '',
  });

  factory PaymentNode.fromJson(Map<String, dynamic> json) {
    return PaymentNode(
      name: json['name'] as String,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      received: json['received'] as bool? ?? false,
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'ratio': ratio,
    'received': received,
    'date': date,
  };

  final String name;

  /// 占合同金额的比例（0~1）
  final double ratio;
  final bool received;

  /// 到账日期（勾选时记录）
  final String date;

  PaymentNode copyWith({bool? received, String? date}) {
    return PaymentNode(
      name: name,
      ratio: ratio,
      received: received ?? this.received,
      date: date ?? this.date,
    );
  }
}
