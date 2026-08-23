import '../models/quotation.dart';
import '../models/seed.dart';

/// 时限跟进提醒项（中游机制：48小时跟进 / 7天催收 / 结项提示）
class FollowUpItem {
  const FollowUpItem({
    required this.kind,
    required this.title,
    required this.detail,
    this.quotationId,
    this.contractId,
  });

  final String kind; // 报价跟进 / 签署跟进 / 尾款催收 / 可结项
  final String title;
  final String detail;
  final String? quotationId;
  final String? contractId;
}

/// 汇总所有超时未跟进事项，工作台「需要跟进」区块直接展示
///
/// 规则：
/// - 报价：非终态且 updated 超过 2 天未动 → 跟进提醒（约 48 小时）
/// - 合同：待签署超过 3 天 → 签署跟进
/// - 合同：已签署但超 7 天仍有款项未到账 → 催收提醒
/// - 合同：款项全部到账但未归档 → 提示可结项
List<FollowUpItem> collectFollowUps(BusinessData data, {DateTime? now}) {
  final n = now ?? DateTime.now();
  int daysSince(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return -1;
    return n.difference(d).inDays;
  }

  bool isQuotationClosed(Quotation q) =>
      q.status.contains('已确认') || q.status.contains('成交');

  final items = <FollowUpItem>[];

  for (final q in data.quotations) {
    final days = daysSince(q.updated);
    if (!isQuotationClosed(q) && days > 2) {
      items.add(
        FollowUpItem(
          kind: '报价跟进',
          title: '「${q.name}」已 $days 天没有进展',
          detail: '${q.client} · 当前 v${q.version} ${q.status}',
          quotationId: q.id,
        ),
      );
    }
  }

  for (final c in data.contracts) {
    if (c.status == '待签署') {
      final days = daysSince(c.created);
      if (days >= 3) {
        items.add(
          FollowUpItem(
            kind: '签署跟进',
            title: '「${c.name}」发出 $days 天仍未签署',
            detail: '${c.client} · ${(c.amount).toStringAsFixed(1)} 万元',
            contractId: c.id,
          ),
        );
      }
      continue;
    }
    if (c.signed.isEmpty || c.status == '已归档') continue;

    final unpaid = c.payments.where((p) => !p.received).toList();
    final signedDays = daysSince(c.signed);
    if (unpaid.isNotEmpty && signedDays > 7) {
      items.add(
        FollowUpItem(
          kind: '尾款催收',
          title: '「${c.name}」签约 $signedDays 天，${unpaid.length} 笔款项未到账',
          detail:
              '${c.client} · 未到账 ${unpaid.map((p) => p.name).join('、')} · 建议发函催收并留痕',
          contractId: c.id,
        ),
      );
    }
    if (unpaid.isEmpty && c.payments.isNotEmpty) {
      items.add(
        FollowUpItem(
          kind: '可结项',
          title: '「${c.name}」款项已全部到账，可确认结项',
          detail: '${c.client} · 合计 ${c.receivedAmount.toStringAsFixed(1)} 万元',
          contractId: c.id,
        ),
      );
    }
  }

  return items;
}
