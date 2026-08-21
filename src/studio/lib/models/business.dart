import 'quotation.dart';

/// 业务模型：商务活动的组织中心，订单是业务的实例
/// 报价规则、商业模型、毛利底线与付款节点模板定义在业务上
class Business {
  const Business({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.pricingRule,
    required this.created,
    required this.updated,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? BusinessStatus.active,
      pricingRule: PricingRule.fromJson(
        json['pricingRule'] as Map<String, dynamic>? ?? {},
      ),
      created: json['created'] as String? ?? '',
      updated: json['updated'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String description;

  /// 经营状态：在营 / 观望 / 退出
  final String status;

  /// 报价规则（难度/量级/工时公式 + 毛利底线）
  final PricingRule pricingRule;

  final String created;
  final String updated;
}

/// 报价规则：定义在业务上，订单实例化时代入参数执行
class PricingRule {
  const PricingRule({
    required this.unitPrice,
    required this.stageDefaults,
    required this.minGrossMargin,
    required this.paymentTerms,
  });

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    return PricingRule(
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.1,
      stageDefaults: (json['stageDefaults'] as List<dynamic>? ?? [])
          .map((e) => StageDefault.fromJson(e as Map<String, dynamic>))
          .toList(),
      minGrossMargin: (json['minGrossMargin'] as num?)?.toDouble() ?? 0.3,
      paymentTerms: json['paymentTerms'] as String? ?? '',
    );
  }

  /// 人天单价（万元）
  final double unitPrice;

  /// 标准阶段工时基线（人天）
  final List<StageDefault> stageDefaults;

  /// 毛利底线（0~1）
  final double minGrossMargin;

  /// 付款节点模板
  final String paymentTerms;

  /// 成本法估算总价（万元）= Σ(阶段工时 × 人天单价)
  double get costEstimate =>
      stageDefaults.fold(0.0, (sum, s) => sum + s.workload * unitPrice);
}

/// 阶段工时基线（采集/建模/导入/治理/报告等）
class StageDefault {
  const StageDefault({
    required this.name,
    required this.workload,
  });

  factory StageDefault.fromJson(Map<String, dynamic> json) {
    return StageDefault(
      name: json['name'] as String,
      workload: (json['workload'] as num).toDouble(),
    );
  }

  final String name;

  /// 工时基线（人天）
  final double workload;
}

/// 业务经营状态常量
class BusinessStatus {
  static const String active = '在营';
  static const String watching = '观望';
  static const String retired = '退出';
}

/// 业务 + 其名下订单（报价、合同）的聚合视图
class BusinessOverview {
  const BusinessOverview({
    required this.business,
    required this.quotations,
    required this.contracts,
  });

  final Business business;
  final List<Quotation> quotations;
  final List<QuotationContractRef> contracts;

  /// 在手订单金额（万元）
  double get totalAmount =>
      contracts.fold(0.0, (sum, c) => sum + c.amount);
}

/// 合同在业务视图下的轻量引用
class QuotationContractRef {
  const QuotationContractRef({
    required this.id,
    required this.name,
    required this.status,
    required this.amount,
  });

  final String id;
  final String name;
  final String status;
  final double amount;
}
