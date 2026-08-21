import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/seed.dart';
import '../models/store.dart';
import '../widgets/cards/contract_card.dart';
import '../widgets/cards/quotation_card.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/sidebar.dart';
import 'business_detail_screen.dart';
import 'business_edit_screen.dart';
import 'contract_detail_screen.dart';
import 'contract_edit_screen.dart';
import 'contract_list_screen.dart';
import 'quotation_detail_screen.dart';
import 'quotation_edit_screen.dart';
import 'quotation_list_screen.dart';

/// 商务工作台：报价与合同管理总览
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  BusinessData? _data;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await BusinessStore.instance.load();
      if (!mounted) return;
      setState(() => _data = BusinessStore.instance.data);
    } catch (e) {
      debugPrint('种子数据加载失败: $e');
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  /// 打开页面，返回后刷新（新建的数据要立刻可见）
  Future<void> _open(Future<void> Function() push) async {
    await push();
    if (mounted) setState(() => _data = BusinessStore.instance.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Responsive(
          mobile: _buildBody(context, compact: true),
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Sidebar(),
              Expanded(child: _buildBody(context, compact: false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool compact}) {
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
          const Text(
            '商务工作台',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '报价与合同管理总览',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loadFailed) {
      return const Center(
        child: Text('种子数据加载失败', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = _data!;
    return ListView(
      children: [
        _buildStatCards(data),
        const SizedBox(height: 16),
        _buildSectionHeader(
          '业务',
          count: data.businesses.length,
          onNew: () => _open(
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessEditScreen()),
            ),
          ),
          onViewAll: () => _openBusinesses(),
        ),
        const SizedBox(height: 8),
        ...data.businesses.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DashboardBusinessCard(
              business: b,
              contractCount: data.contractsOf(b.id).length,
              onTap: () => _openDetail(
                BusinessDetailScreen(business: b, data: data),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader(
          '报价',
          count: data.quotations.length,
          onNew: () => _open(
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuotationEditScreen(
                  quotationTemplates: data.quotationTemplates,
                ),
              ),
            ),
          ),
          onViewAll: () => _open(
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuotationListScreen(quotations: data.quotations),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...data.quotations.map(
          (q) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuotationCard(
              quotation: q,
              onTap: () => _openDetail(QuotationDetailScreen(quotation: q)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader(
          '合同',
          count: data.contracts.length,
          onNew: () => _open(
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ContractEditScreen(contractTemplates: data.contractTemplates),
              ),
            ),
          ),
          onViewAll: () => _open(
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContractListScreen(contracts: data.contracts),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...data.contracts.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ContractCard(
              contract: c,
              onTap: () => _openDetail(ContractDetailScreen(contract: c)),
            ),
          ),
        ),
      ],
    );
  }

  // ===== 统计卡片 =====
  Widget _buildStatCards(BusinessData data) {
    final confirmed = data.quotations.where((q) => q.status == '已确认').length;
    final pending = data.contracts.where((c) => c.status == '待签署').length;
    final signed = data.contracts.where((c) => c.status == '已签署').length;
    final cards = [
      ('${data.quotations.length}', '报价总数', const Color(0xFF4F46E5)),
      ('$confirmed', '已确认', const Color(0xFFF59E0B)),
      ('$pending', '待签署', const Color(0xFF3B82F6)),
      ('$signed', '已签署', const Color(0xFF10B981)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: cards
              .map(
                (c) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.$1,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: c.$3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.$2,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ===== 区块标题 =====
  Widget _buildSectionHeader(
    String title, {
    required int count,
    VoidCallback? onNew,
    required VoidCallback onViewAll,
  }) {
    return Row(
      children: [
        Text(
          '$title（$count）',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          child: const Text('查看全部', style: TextStyle(fontSize: 12)),
        ),
        if (onNew != null) ...[
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onNew,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.add, size: 16),
            label: Text('新建$title'),
          ),
        ],
      ],
    );
  }

  void _openBusinesses() {
    Navigator.of(context).pushReplacementNamed('/businesses');
  }

  void _openDetail(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

/// 工作台业务卡片：业务概览入口
class _DashboardBusinessCard extends StatelessWidget {
  final Business business;
  final int contractCount;
  final VoidCallback onTap;

  const _DashboardBusinessCard({
    required this.business,
    required this.contractCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.business_center_outlined,
                size: 19,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${business.name}（${business.status}）',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '订单 $contractCount · 人天单价 ${business.pricingRule.unitPrice.toStringAsFixed(2)} 万元 · 毛利底线 ${(business.pricingRule.minGrossMargin * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
