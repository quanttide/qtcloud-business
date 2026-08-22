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
    this.commercialModel = '',
    this.changeRuleTemplate = '',
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
      commercialModel: json['commercialModel'] as String? ?? '',
      changeRuleTemplate: json['changeRuleTemplate'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String description;

  /// 经营状态：在营 / 观望 / 退出
  final String status;

  /// 报价规则（难度/量级/工时公式 + 毛利底线）
  final PricingRule pricingRule;

  /// 商业模型：人天制 / 资源包 / 会员制 / 按交付收费 / 处理费+存储费
  final String commercialModel;

  /// 变更规则模板：范围/工期/费用影响的书面评估与确认约定
  final String changeRuleTemplate;

  final String created;
  final String updated;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'status': status,
    'pricingRule': pricingRule.toJson(),
    if (commercialModel.isNotEmpty) 'commercialModel': commercialModel,
    if (changeRuleTemplate.isNotEmpty) 'changeRuleTemplate': changeRuleTemplate,
    'created': created,
    'updated': updated,
  };

  /// 规则没写清的项：写清报价公式与毛利底线才算业务明确，
  /// 有缺口时不允许进入订单执行（发起报价被拦截）
  List<String> missingRuleFields() {
    final gaps = <String>[];
    if (pricingRule.unitPrice <= 0) gaps.add('人天单价');
    if (pricingRule.minGrossMargin <= 0) gaps.add('毛利底线');
    if (pricingRule.paymentTerms.trim().isEmpty) gaps.add('付款节点');
    if (pricingRule.stageDefaults.isEmpty ||
        pricingRule.stageDefaults.any((s) => s.workload <= 0)) {
      gaps.add('阶段工时基线');
    }
    return gaps;
  }

  bool get isRuleComplete => missingRuleFields().isEmpty;
}

/// 商业模型预设（按业务配置定价模式）
class CommercialModels {
  static const List<String> presets = [
    '人天制',
    '资源包',
    '会员制',
    '按交付收费',
    '处理费+存储费',
  ];
}

/// 报价规则：定义在业务上，订单实例化时代入参数执行
/// 工时公式：报价工时 = 阶段基线工时 × 难度系数 × 量级系数
class PricingRule {
  const PricingRule({
    required this.unitPrice,
    required this.stageDefaults,
    required this.minGrossMargin,
    required this.paymentTerms,
    this.difficultyLevels = defaultDifficultyLevels,
    this.scaleLevels = defaultScaleLevels,
  });

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    final difficulties = (json['difficultyLevels'] as List<dynamic>? ?? [])
        .map((e) => FactorLevel.fromJson(e as Map<String, dynamic>))
        .toList();
    final scales = (json['scaleLevels'] as List<dynamic>? ?? [])
        .map((e) => FactorLevel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PricingRule(
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.1,
      stageDefaults: (json['stageDefaults'] as List<dynamic>? ?? [])
          .map((e) => StageDefault.fromJson(e as Map<String, dynamic>))
          .toList(),
      minGrossMargin: (json['minGrossMargin'] as num?)?.toDouble() ?? 0.3,
      paymentTerms: json['paymentTerms'] as String? ?? '',
      difficultyLevels: difficulties.isEmpty
          ? defaultDifficultyLevels
          : difficulties,
      scaleLevels: scales.isEmpty ? defaultScaleLevels : scales,
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

  /// 难度档位与系数（作用于工时）
  final List<FactorLevel> difficultyLevels;

  /// 量级档位与系数（作用于工时）
  final List<FactorLevel> scaleLevels;

  /// 工时公式：报价工时 = 阶段基线 × 难度系数 × 量级系数
  double stageHours(StageDefault s, FactorLevel difficulty, FactorLevel scale) =>
      s.workload * difficulty.factor * scale.factor;

  /// 成本法估算总价（万元）= Σ(阶段工时 × 人天单价)
  double get costEstimate =>
      stageDefaults.fold(0.0, (sum, s) => sum + s.workload * unitPrice);

  Map<String, dynamic> toJson() => {
    'unitPrice': unitPrice,
    'stageDefaults': stageDefaults.map((e) => e.toJson()).toList(),
    'minGrossMargin': minGrossMargin,
    'paymentTerms': paymentTerms,
    'difficultyLevels': difficultyLevels.map((e) => e.toJson()).toList(),
    'scaleLevels': scaleLevels.map((e) => e.toJson()).toList(),
  };

  static const defaultDifficultyLevels = [
    FactorLevel(name: '低', factor: 1.0),
    FactorLevel(name: '中', factor: 1.3),
    FactorLevel(name: '高', factor: 1.6),
  ];

  static const defaultScaleLevels = [
    FactorLevel(name: '小', factor: 1.0),
    FactorLevel(name: '中', factor: 1.5),
    FactorLevel(name: '大', factor: 2.0),
  ];
}

/// 系数档位：难度/量级等，factor 乘在工时上
class FactorLevel {
  const FactorLevel({required this.name, required this.factor});

  factory FactorLevel.fromJson(Map<String, dynamic> json) => FactorLevel(
    name: json['name'] as String? ?? '',
    factor: (json['factor'] as num?)?.toDouble() ?? 1.0,
  );

  final String name;
  final double factor;

  Map<String, dynamic> toJson() => {'name': name, 'factor': factor};
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

  Map<String, dynamic> toJson() => {'name': name, 'workload': workload};
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
