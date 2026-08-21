import 'package:flutter/material.dart';

import '../models/contract.dart';
import '../models/store.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/sidebar.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/toast.dart';

/// 合同详情：签署进度（发送→签署→归档，US4）+ 付款到账 + 履约跟踪 + 签署提醒
class ContractDetailScreen extends StatefulWidget {
  final Contract contract;

  const ContractDetailScreen({super.key, required this.contract});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  // 页面持有当前合同状态：打勾后用新对象重建，UI 才会刷新
  late Contract _contract = widget.contract;
  Contract get contract => _contract;

  void _togglePayment(int index) {
    final payments = List<PaymentNode>.from(contract.payments);
    final node = payments[index];
    final received = !node.received;
    payments[index] = node.copyWith(
      received: received,
      date: received
          ? DateTime.now().toIso8601String().substring(0, 10)
          : '',
    );
    final updated = contract.copyWith(payments: payments);
    // 先更新界面，持久化在后台进行，不阻塞交互
    setState(() => _contract = updated);
    BusinessStore.instance.updateContract(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Responsive(
          mobile: _buildDetail(context, compact: true),
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Sidebar(),
              Expanded(child: _buildDetail(context, compact: false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, {required bool compact}) {
    return ListView(
      padding: pageHPadding(context).add(const EdgeInsets.only(top: 16)),
      children: [
        _buildHeader(context, compact: compact),
        const SizedBox(height: 16),
        // 签署进度（US4）
        _sectionTitle('签署进度'),
        const SizedBox(height: 8),
        _buildProgressCard(),
        const SizedBox(height: 16),
        // 付款到账
        if (contract.payments.isNotEmpty) ...[
          _sectionTitle('付款到账'),
          const SizedBox(height: 8),
          _buildPaymentsCard(),
          const SizedBox(height: 16),
        ],
        // 合同信息
        _sectionTitle('合同信息'),
        const SizedBox(height: 8),
        _buildInfoCard(),
        if (contract.status == '待签署') ...[
          const SizedBox(height: 16),
          // 签署提醒（US4）
          FilledButton.icon(
            onPressed: () =>
                showAppToast(context, '🔔 已发送签署提醒给 ${contract.client}'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
            ),
            icon: const Icon(Icons.notifications_active_outlined, size: 16),
            label: const Text('提醒客户签署'),
          ),
        ],
      ],
    );
  }

  // ===== 头部 =====
  Widget _buildHeader(BuildContext context, {required bool compact}) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    contract.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  StatusBadge(status: contract.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '客户：${contract.client} ｜ 模板：${contract.template}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 2),
              Text(
                '创建于 ${contract.created} ｜ '
                '${contract.signed.isEmpty ? '尚未签署' : '签署于 ${contract.signed}'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${contract.amount.toStringAsFixed(1)} 万元',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  // ===== 签署进度步骤条 =====
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < contract.fulfillments.length; i++)
            _buildStep(
              contract.fulfillments[i],
              isLast: i == contract.fulfillments.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildStep(Fulfillment f, {required bool isLast}) {
    final (color, icon) = switch (f.status) {
      'done' => (const Color(0xFF10B981), Icons.check),
      'active' => (const Color(0xFF4F46E5), Icons.radio_button_checked),
      _ => (const Color(0xFFCBD5E1), Icons.radio_button_unchecked),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 节点 + 连线
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFE2E8F0)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 步骤内容
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        f.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      if (f.date.isNotEmpty)
                        Text(
                          f.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    switch (f.status) {
                      'done' => '已完成',
                      'active' => '进行中',
                      _ => '待启动',
                    },
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 付款到账 =====
  Widget _buildPaymentsCard() {
    final received = contract.receivedAmount;
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
              Text(
                '已到账 ${received.toStringAsFixed(2)} 万元 / 共 ${contract.amount.toStringAsFixed(1)} 万元',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                '${contract.payments.where((p) => p.received).length}/${contract.payments.length} 笔',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < contract.payments.length; i++)
            _buildPaymentRow(i),
          const SizedBox(height: 4),
          Text(
            '点击勾选记录到账，日期自动记为当天',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(int index) {
    final p = contract.payments[index];
    final amount = p.ratio * contract.amount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _togglePayment(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(
                p.received
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
                color: p.received
                    ? const Color(0xFF10B981)
                    : const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.received
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF1E293B),
                    decoration: p.received
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              Text(
                amount > 0 ? '${amount.toStringAsFixed(2)} 万' : '',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                child: Text(
                  p.date.isEmpty ? '未到账' : p.date,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    color: p.received
                        ? const Color(0xFF10B981)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 合同信息 =====
  Widget _buildInfoCard() {
    final rows = [
      ('合同编号', contract.id),
      ('客户', contract.client),
      ('合同模板', contract.template),
      ('合同金额', '${contract.amount.toStringAsFixed(1)} 万元'),
      ('已到账', '${contract.receivedAmount.toStringAsFixed(2)} 万元'),
      ('创建时间', contract.created),
      ('签署时间', contract.signed.isEmpty ? '—' : contract.signed),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
