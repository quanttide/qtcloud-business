import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/seed.dart';
import '../models/store.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/sidebar.dart';
import 'business_detail_screen.dart';
import 'business_edit_screen.dart';

/// 业务经营：业务列表（业务是类，订单是实例）
class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  BusinessData? _data;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await BusinessStore.instance.load();
    if (!mounted) return;
    setState(() {
      _loadFailed = BusinessStore.instance.loadFailed;
      _data = BusinessStore.instance.data;
    });
  }

  /// 打开页面，返回后刷新
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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
              const Sidebar(route: '/businesses'),
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
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '业务经营',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '业务是类，订单是实例：报价规则与模板定义在业务上',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _open(const BusinessEditScreen()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新建业务'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent(compact: compact)),
        ],
      ),
    );
  }

  Widget _buildContent({required bool compact}) {
    if (_loadFailed) {
      return const Center(
        child: Text('种子数据加载失败', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = _data!;
    if (data.businesses.isEmpty) {
      return const Center(
        child: Text('暂无业务，先定义一个业务', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    return ListView.separated(
      itemCount: data.businesses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final business = data.businesses[index];
        final quotations = data.quotationsOf(business.id);
        final contracts = data.contractsOf(business.id);
        return _BusinessCard(
          business: business,
          quotationCount: quotations.length,
          contractCount: contracts.length,
          totalAmount: contracts.fold(0.0, (sum, c) => sum + c.amount),
          onTap: () => _open(
            BusinessDetailScreen(business: business, data: data),
          ),
        );
      },
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final Business business;
  final int quotationCount;
  final int contractCount;
  final double totalAmount;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.business,
    required this.quotationCount,
    required this.contractCount,
    required this.totalAmount,
    required this.onTap,
  });

  Color get _statusColor {
    switch (business.status) {
      case BusinessStatus.active:
        return const Color(0xFF10B981);
      case BusinessStatus.watching:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.business_center_outlined,
                size: 22,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          business.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '订单 $contractCount · 报价 $quotationCount',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalAmount.toStringAsFixed(1)} 万元',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
