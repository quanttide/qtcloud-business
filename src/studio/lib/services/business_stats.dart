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
