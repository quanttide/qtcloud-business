import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/contract.dart';
import '../models/quotation.dart';
import '../widgets/status_badge.dart';

/// 商务云仪表盘：报价与合同总览
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Quotation> _quotations = [];
  List<Contract> _contracts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSeed();
  }

  Future<void> _loadSeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/data/seed_business.json');
      final json = jsonDecode(data) as Map<String, dynamic>;
      final quotations = (json['quotations'] as List<dynamic>? ?? [])
          .map((e) => Quotation.fromJson(e as Map<String, dynamic>))
          .toList();
      final contracts = (json['contracts'] as List<dynamic>? ?? [])
          .map((e) => Contract.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _quotations = quotations;
        _contracts = contracts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('加载失败'),
            Text(_error!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadSeed, child: const Text('重试')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCards(),
        const SizedBox(height: 24),
        _buildSectionTitle('报价', _quotations.length),
        ..._quotations.map(_buildQuotationCard),
        const SizedBox(height: 24),
        _buildSectionTitle('合同', _contracts.length),
        ..._contracts.map(_buildContractCard),
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$title（$count）',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildStatCards() {
    final confirmed = _quotations.where((q) => q.status == '已确认').length;
    final pending = _contracts.where((c) => c.status == '待签署').length;
    final signed = _contracts.where((c) => c.status == '已签署').length;
    final cards = [
      ('报价总数', _quotations.length, ItemStatusStyle.todo),
      ('已确认', confirmed, ItemStatusStyle.active),
      ('待签署', pending, ItemStatusStyle.active),
      ('已签署', signed, ItemStatusStyle.done),
    ];
    return Row(
      children: [
        for (final (label, value, color) in cards)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatCard(label: label, value: value, color: color),
            ),
          ),
      ],
    );
  }

  Widget _buildQuotationCard(Quotation q) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${q.name}  v${q.version}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${q.client} · ${q.template} · ${q.updated}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${q.totalAmount.toStringAsFixed(1)} 万元',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            StatusBadge(label: q.status, status: _statusKey(q.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(Contract c) {
    final doneCount = c.fulfillments.where((f) => f.status == 'done').length;
    final total = c.fulfillments.length;
    final progress = total == 0 ? 0.0 : doneCount / total;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          c.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.client} · ${c.template}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: ItemStatusStyle.active,
                      backgroundColor: const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$doneCount/$total 履约',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${c.amount.toStringAsFixed(1)} 万元',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            StatusBadge(label: c.status, status: _statusKey(c.status)),
          ],
        ),
      ),
    );
  }

  /// 文本状态 → 三态语义色键
  String _statusKey(String status) {
    switch (status) {
      case '已确认':
      case '已签署':
      case '已归档':
        return 'done';
      case '已发送':
      case '待签署':
        return 'active';
      default:
        return 'todo';
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
