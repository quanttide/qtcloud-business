import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/seed.dart';
import '../models/store.dart';
import '../widgets/cards/contract_card.dart';
import '../widgets/cards/quotation_card.dart';
import '../widgets/common/responsive.dart';
import 'contract_detail_screen.dart';
import 'contract_edit_screen.dart';
import 'quotation_detail_screen.dart';
import 'quotation_edit_screen.dart';

/// 业务详情：报价规则 + 名下订单（报价、合同）
class BusinessDetailScreen extends StatefulWidget {
  final Business business;
  final BusinessData data;

  const BusinessDetailScreen({
    super.key,
    required this.business,
    required this.data,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // 从存储取最新数据（发起报价返回后能看到新报价）
    final data = BusinessStore.instance.data;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Responsive(
          mobile: _buildBody(context, compact: true, data: data),
          desktop: _buildBody(context, compact: false, data: data),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool compact,
    required BusinessData data,
  }) {
    final business = widget.business;
    final quotations = data.quotationsOf(business.id);
    final contracts = data.contractsOf(business.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 16 : 28,
        compact ? 16 : 28,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                business.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContractEditScreen(
                        contractTemplates:
                            BusinessStore.instance.data.contractTemplates,
                        business: business,
                      ),
                    ),
                  );
                  if (context.mounted) setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('登记合同'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuotationEditScreen(
                        quotationTemplates:
                            BusinessStore.instance.data.quotationTemplates,
                        business: business,
                      ),
                    ),
                  );
                  if (context.mounted) setState(() {});
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('发起报价'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            business.description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildPricingRuleCard(),
                const SizedBox(height: 16),
                _buildSectionTitle('名下合同（${contracts.length}）'),
                const SizedBox(height: 8),
                ...contracts.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ContractCard(
                      contract: c,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContractDetailScreen(contract: c),
                        ),
                      ),
                    ),
                  ),
                ),
                if (contracts.isEmpty)
                  const _EmptyHint(text: '该业务暂无合同订单'),
                const SizedBox(height: 16),
                _buildSectionTitle('名下报价（${quotations.length}）'),
                const SizedBox(height: 8),
                ...quotations.map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: QuotationCard(
                      quotation: q,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuotationDetailScreen(quotation: q),
                        ),
                      ),
                    ),
                  ),
                ),
                if (quotations.isEmpty) const _EmptyHint(text: '该业务暂无报价'),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 报价规则卡片 =====
  Widget _buildPricingRuleCard() {
    final rule = widget.business.pricingRule;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '报价规则',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '毛利底线 ${(rule.minGrossMargin * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ruleStat('人天单价', '${rule.unitPrice.toStringAsFixed(2)} 万元'),
              _ruleStat('成本法估算', '${rule.costEstimate.toStringAsFixed(1)} 万元'),
            ],
          ),
          if (rule.paymentTerms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '付款节点：${rule.paymentTerms}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (rule.stageDefaults.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '阶段工时基线',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rule.stageDefaults
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '${s.name} ${s.workload.toStringAsFixed(1)} 人天',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ruleStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
