import 'package:flutter/material.dart';

import '../models/contract.dart';
import '../models/log_entry.dart';
import '../models/store.dart';
import '../services/pdf_export.dart';
import '../widgets/cards/logs_card.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/sidebar.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/toast.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';

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

  /// 交付与验收：勾选记日期，取消勾清空
  void _toggleDeliverable(int index) {
    final items = List<Fulfillment>.from(contract.deliverables);
    final item = items[index];
    final done = item.status != 'done';
    items[index] = Fulfillment(
      name: item.name,
      status: done ? 'done' : 'todo',
      date: done ? DateTime.now().toIso8601String().substring(0, 10) : '',
    );
    final updated = contract.copyWith(deliverables: items);
    setState(() => _contract = updated);
    BusinessStore.instance.updateContract(updated);
  }

  /// 新增交付物
  Future<void> _addDeliverable() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '添加交付物',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '如：数据审计报告 / 培训材料',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(ctrl.text.trim()),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                        ),
                        child: const Text('添加'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final updated = contract.copyWith(
      deliverables: [
        ...contract.deliverables,
        Fulfillment(name: name, status: 'todo', date: ''),
      ],
    );
    setState(() => _contract = updated);
    BusinessStore.instance.updateContract(updated);
    if (mounted) showAppToast(context, '✅ 已添加交付物：$name');
  }

  void _addLog(LogEntry entry) {
    final updated = contract.copyWith(logs: [...contract.logs, entry]);
    setState(() => _contract = updated);
    BusinessStore.instance.updateContract(updated);
    showAppToast(context, '✅ 已登记留痕：${entry.type}');
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
        // 执行与验收：交付物清单逐项勾选记日期
        _sectionTitle('交付与验收'),
        const SizedBox(height: 8),
        _buildDeliverablesCard(),
        const SizedBox(height: 16),
        // 付款到账
        if (contract.payments.isNotEmpty) ...[
          _sectionTitle('付款到账'),
          const SizedBox(height: 8),
          _buildPaymentsCard(),
          const SizedBox(height: 16),
        ],
        // 收款与结项：款项全部到账且未归档 → 一键结项
        if (contract.status != '已归档' &&
            contract.payments.isNotEmpty &&
            contract.payments.every((p) => p.received)) ...[
          FilledButton.icon(
            onPressed: _closeContract,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            icon: const Icon(Icons.verified_outlined, size: 16),
            label: const Text('确认结项并归档'),
          ),
          const SizedBox(height: 16),
        ],
        // 合同信息
        _sectionTitle('往来留痕'),
        const SizedBox(height: 8),
        LogsCard(logs: contract.logs, onAdd: _addLog),
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
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
        const SizedBox(width: 8),
        // 按单归档导出（需求四：订单档案支撑审计）
        Tooltip(
          message: '导出订单归档 PDF',
          child: InkWell(
            onTap: _exportArchive,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.archive_outlined,
                size: 16,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 删除（顶部显眼入口）
        Tooltip(
          message: '删除该合同',
          child: InkWell(
            onTap: _deleteContract,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFFEF4444),
              ),
            ),
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

  Future<void> _deleteContract() async {
    final ok = await confirmDelete(
      context,
      title: '删除「${contract.name}」？',
      content: '删除后不可恢复。',
    );
    if (!ok || !mounted) return;
    await BusinessStore.instance.deleteContract(contract.id);
    if (mounted) Navigator.of(context).pop();
  }

  /// 按单归档：导出合同信息+付款+履约+交付+留痕的汇总 PDF
  Future<void> _exportArchive() async {
    var businessName = '';
    for (final b in BusinessStore.instance.data.businesses) {
      if (b.id == contract.businessId) {
        businessName = b.name;
        break;
      }
    }
    final filename = await exportContractArchivePdf(
      contract,
      businessName: businessName,
    );
    if (mounted) showAppToast(context, '📄 已导出归档：$filename');
  }

  /// 收款与结项：全部到账后归档结项（订单档案留存，支撑审计与复盘）
  void _closeContract() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final steps = contract.fulfillments
        .map(
          (f) => Fulfillment(
            name: f.name,
            status: 'done',
            date: f.date.isEmpty ? today : f.date,
          ),
        )
        .toList();
    final updated = contract.copyWith(status: '已归档', fulfillments: steps);
    setState(() => _contract = updated);
    BusinessStore.instance.updateContract(updated);
    showAppToast(context, '🎉 已结项归档：${contract.name}');
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < contract.fulfillments.length; i++)
            _buildStep(
              contract.fulfillments[i],
              isLast: i == contract.fulfillments.length - 1,
              onTap: () => _advanceStep(i),
            ),
          const SizedBox(height: 4),
          Text(
            '点按步骤即可标记完成并记录日期（书面确认优先：完成后请补邮件留痕）',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  /// 推进签署流程：把第 i 步及其之前全部标为完成，其后顺延激活；
  /// 客户签署完成 → 合同转为已签署；归档完成 → 已归档
  void _advanceStep(int index) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final steps = <Fulfillment>[];
    for (var i = 0; i < contract.fulfillments.length; i++) {
      final f = contract.fulfillments[i];
      if (i <= index) {
        steps.add(
          Fulfillment(
            name: f.name,
            status: 'done',
            date: f.date.isEmpty ? today : f.date,
          ),
        );
      } else if (f.status == 'done') {
        steps.add(f);
      } else {
        steps.add(Fulfillment(name: f.name, status: 'todo', date: ''));
      }
    }
    var status = contract.status;
    var signed = contract.signed;
    if (index >= 1 && status == '待签署') {
      status = '已签署';
      signed = signed.isEmpty ? today : signed;
    }
    if (index == contract.fulfillments.length - 1) {
      status = '已归档';
      if (status != '已签署' && signed.isEmpty && index >= 1) signed = today;
    }
    final nextActive = index + 1 < steps.length
        ? Fulfillment(
            name: steps[index + 1].name,
            status: 'active',
            date: '',
          )
        : null;
    if (nextActive != null) steps[index + 1] = nextActive;

    final updated = contract.copyWith(
      fulfillments: steps,
      status: status,
      signed: signed,
    );
    setState(() => _contract = updated);
    BusinessStore.instance.updateContract(updated);
    showAppToast(context, '✅ 「${steps[index].name}」已完成（$today）');
  }

  Widget _buildStep(Fulfillment f, {required bool isLast, VoidCallback? onTap}) {
    final (color, icon) = switch (f.status) {
      'done' => (const Color(0xFF10B981), Icons.check),
      'active' => (const Color(0xFF4F46E5), Icons.radio_button_checked),
      _ => (const Color(0xFFCBD5E1), Icons.radio_button_unchecked),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Column(
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
  /// 交付与验收清单：点按勾选记日期，可添加条目
  Widget _buildDeliverablesCard() {
    final items = contract.deliverables;
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
          if (items.isEmpty)
            const Text(
              '暂无交付物——建议把报告、培训等交付逐项列出，完成后勾选',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          for (var i = 0; i < items.length; i++)
            InkWell(
              onTap: () => _toggleDeliverable(i),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: items[i].status == 'done'
                            ? const Color(0xFF10B981)
                            : Colors.white,
                        border: Border.all(
                          color: items[i].status == 'done'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: items[i].status == 'done'
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].name,
                        style: TextStyle(
                          fontSize: 13,
                          color: items[i].status == 'done'
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1E293B),
                          decoration: items[i].status == 'done'
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    Text(
                      items[i].date.isEmpty ? '待交付' : '${items[i].date} 验收',
                      style: TextStyle(
                        fontSize: 11,
                        color: items[i].status == 'done'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addDeliverable,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
            ),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('添加交付物'),
          ),
        ],
      ),
    );
  }

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
