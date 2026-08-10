/// 合同模型（合同管理 · 签约流程与履约跟踪）
class Contract {
  const Contract({
    required this.id,
    required this.name,
    required this.client,
    required this.template,
    required this.status,
    required this.amount,
    required this.created,
    required this.signed,
    required this.fulfillments,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String,
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
    );
  }

  final String id;
  final String name;
  final String client;
  final String template;
  final String status;
  final double amount;
  final String created;
  final String signed;
  final List<Fulfillment> fulfillments;
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

  final String name;
  final String status;
  final String date;
}
