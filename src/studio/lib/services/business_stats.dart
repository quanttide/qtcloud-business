import '../models/business.dart';
import '../models/seed.dart';

DateTime? _parseDate(String s) {
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// 业务经营统计（需求五：数据回流——订单实例的数据回流到业务类，支撑复盘与校准）
class BusinessStats {
  const BusinessStats({
    required this.quotationCount,
    required this.contractCount,
    required this.contractAmount,
    required this.receivedAmount,
    required this.avgCollectionDays,
    required this.overdueReceivable,
    required this.staleQuotationCount,
  });

  /// 名下报价数
  final int quotationCount;

  /// 名下合同数（报价转化为订单）
  final int contractCount;

  /// 名下合同总额（万元）
  final double contractAmount;

  /// 已到账金额（万元）
  final double receivedAmount;

  /// 平均回款周期（天）：签约日 → 最后一笔到账日；无已完成回款的合同时为 null
  final double? avgCollectionDays;

  /// 超期应收（万元）：签约超 30 天仍未到账的款项
  final double overdueReceivable;

  /// 草稿超 30 天未动的报价数（线索沉睡）
  final int staleQuotationCount;

  /// 报价转化率：名下报价中转化为合同的比例
  double get conversionRate =>
      quotationCount == 0 ? 0 : contractCount / quotationCount;

  /// 回款进度（0~1）
  double get receivedRatio =>
      contractAmount <= 0 ? 0 : (receivedAmount / contractAmount).clamp(0, 1);
}

/// 规则校准建议（需求五：用实际数据反推业务规则偏差）
class CalibrationAdvice {
  const CalibrationAdvice(this.level, this.message);

  /// ok / warn / danger
  final String level;
  final String message;
}

/// 对比经营统计与业务定义的规则，给出校准建议
List<CalibrationAdvice> buildCalibrationAdvice(
  BusinessStats stats,
  Business business,
) {
  final advices = <CalibrationAdvice>[];

  if (stats.overdueReceivable > 0) {
    advices.add(
      CalibrationAdvice(
        'danger',
        '有 ${stats.overdueReceivable.toStringAsFixed(1)} 万超期应收：优先催收，'
        '并考虑提高签约款比例。',
      ),
    );
  }

  final cycle = stats.avgCollectionDays;
  if (cycle != null && cycle > 45) {
    advices.add(
      CalibrationAdvice(
        'warn',
        '平均回款周期 ${cycle.toStringAsFixed(0)} 天偏长：'
        '校准付款节点模板，缩短尾款账期。',
      ),
    );
  }

  if (stats.quotationCount >= 3 && stats.conversionRate < 0.3) {
    advices.add(
      CalibrationAdvice(
        'warn',
        '报价转化率 ${(stats.conversionRate * 100).toStringAsFixed(0)}% 偏低：'
        '复盘定价水平与客户筛选标准。',
      ),
    );
  }

  if (stats.contractCount > 0) {
    final avgContract = stats.contractAmount / stats.contractCount;
    final cost = business.pricingRule.costEstimate;
    if (cost > 0 && avgContract < cost) {
      advices.add(
        CalibrationAdvice(
          'danger',
          '平均客单价 ${avgContract.toStringAsFixed(1)} 万低于成本法估算 '
          '${cost.toStringAsFixed(1)} 万：报价需上调或收敛范围。',
        ),
      );
    }
  }

  if (advices.isEmpty) {
    advices.add(
      const CalibrationAdvice('ok', '经营健康：实际数据与规则匹配，暂无需调整。'),
    );
  }
  return advices;
}

/// 章程执行率汇总（需求七）：全部订单检查项的完成比例
class ChecklistSummary {
  const ChecklistSummary({
    required this.totalItems,
    required this.doneItems,
    required this.orderCount,
  });

  /// 检查项总数
  final int totalItems;

  /// 已完成项数
  final int doneItems;

  /// 涉及订单数
  final int orderCount;

  /// 完成比例（0~1）
  double get completion =>
      totalItems == 0 ? 0 : (doneItems / totalItems).clamp(0, 1);
}

ChecklistSummary summarizeChecklists(BusinessData data) {
  var total = 0;
  var done = 0;
  var orders = 0;
  for (final c in data.contracts) {
    // 已归档订单不再计入执行率
    if (c.status == '已归档') continue;
    if (c.checklist.isEmpty) continue;
    orders++;
    for (final item in c.checklist) {
      total++;
      if (item.status == 'done') done++;
    }
  }
  return ChecklistSummary(
    totalItems: total,
    doneItems: done,
    orderCount: orders,
  );
}

/// 汇总某业务名下全部订单的经营指标
BusinessStats computeBusinessStats(
  BusinessData data,
  String businessId, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  var amount = 0.0;
  var received = 0.0;
  var overdue = 0.0;
  final cycles = <int>[];

  final contracts = data.contractsOf(businessId);
  for (final c in contracts) {
    amount += c.amount;
    received += c.receivedAmount;

    final signed = _parseDate(c.signed);
    final unpaid = c.payments
        .where((p) => !p.received)
        .fold(0.0, (s, p) => s + p.ratio) *
        c.amount;
    if (unpaid > 0 && signed != null && at.difference(signed).inDays > 30) {
      overdue += unpaid;
    }

    final receivedDates = c.payments
        .where((p) => p.received && p.date.isNotEmpty)
        .map((p) => _parseDate(p.date))
        .whereType<DateTime>()
        .toList()
      ..sort();
    if (signed != null && receivedDates.isNotEmpty) {
      final days = receivedDates.last.difference(signed).inDays;
      if (days >= 0) cycles.add(days);
    }
  }

  var stale = 0;
  for (final q in data.quotationsOf(businessId)) {
    if (q.status != '草稿') continue;
    final updated = _parseDate(q.updated);
    if (updated != null && at.difference(updated).inDays > 30) stale++;
  }

  return BusinessStats(
    quotationCount: data.quotationsOf(businessId).length,
    contractCount: contracts.length,
    contractAmount: amount,
    receivedAmount: received,
    avgCollectionDays:
        cycles.isEmpty ? null : cycles.reduce((a, b) => a + b) / cycles.length,
    overdueReceivable: overdue,
    staleQuotationCount: stale,
  );
}
