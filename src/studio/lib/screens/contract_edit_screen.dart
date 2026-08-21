import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/contract.dart';
import '../models/store.dart';
import '../models/template.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/toast.dart';

/// 登记合同（US3）：选择合同模板 → 填客户与金额 → 确认付款节点 → 存入业务名下
/// 传入 business 时即"在业务下登记合同"，付款节点按业务模板预填
class ContractEditScreen extends StatefulWidget {
  final List<BusinessTemplate> contractTemplates;
  final Business? business;

  const ContractEditScreen({
    super.key,
    required this.contractTemplates,
    this.business,
  });

  @override
  State<ContractEditScreen> createState() => _ContractEditScreenState();
}

class _ContractEditScreenState extends State<ContractEditScreen> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  BusinessTemplate? _template;
  late final List<_PaymentRow> _payments;

  @override
  void initState() {
    super.initState();
    if (widget.contractTemplates.isNotEmpty) {
      _template = widget.contractTemplates.first;
    }
    final business = widget.business;
    _payments = BusinessStore.paymentNodesFromTerms(
      business?.pricingRule.paymentTerms ?? '',
    ).map((p) => _PaymentRow(name: p.name, ratio: p.ratio)).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    _amountCtrl.dispose();
    for (final p in _payments) {
      p.nameCtrl.dispose();
      p.ratioCtrl.dispose();
    }
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_amountCtrl.text.trim()) ?? 0;

  double get _ratioSum =>
      _payments.fold(0.0, (sum, p) => sum + p.ratio);

  void _save() {
    final client = _clientCtrl.text.trim();
    if (client.isEmpty) {
      showAppToast(context, '请填写客户名称');
      return;
    }
    if (_amount <= 0) {
      showAppToast(context, '请填写合同金额');
      return;
    }
    if (_payments.isEmpty) {
      showAppToast(context, '请至少添加一个付款节点');
      return;
    }
    final business = widget.business;
    final now = DateTime.now().toIso8601String().substring(0, 10);
    BusinessStore.instance
        .addContract(
          Contract(
            id: BusinessStore.instance.nextContractId(),
            businessId: business?.id ?? '',
            name: _nameCtrl.text.trim().isEmpty
                ? '$client · 合同'
                : _nameCtrl.text.trim(),
            client: client,
            template: _template?.name ?? '',
            status: '待签署',
            amount: _amount,
            created: now,
            signed: '',
            fulfillments: [
              Fulfillment(name: '发送签署', status: 'active', date: ''),
              Fulfillment(name: '客户签署', status: 'todo', date: ''),
              Fulfillment(name: '合同归档', status: 'todo', date: ''),
            ],
            payments: _payments
                .map(
                  (p) => PaymentNode(
                    name: p.nameCtrl.text.trim(),
                    ratio: p.ratio,
                  ),
                )
                .toList(),
          ),
        )
        .then((_) {});
    showAppToast(context, '✅ 合同已登记（待签署）');
    Navigator.of(context).pop();
  }

  void _preview() {
    final template = _template;
    if (template == null) {
      showAppToast(context, '请先选择合同模板');
      return;
    }
    final client = _clientCtrl.text.trim();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '预览 · 甲方：量潮科技 ｜ 乙方：${client.isEmpty ? '（未填写客户）' : client}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              const Text(
                '合同条款：',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              for (final section in template.sections)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        section,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                  ),
                  child: const Text('关闭预览'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            children: [Expanded(child: _buildBody(context, compact: false))],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool compact}) {
    final business = widget.business;
    return ListView(
      padding: pageHPadding(context).add(const EdgeInsets.only(top: 16)),
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
              business == null ? '新建合同' : '登记合同',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 所属业务
        if (business != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.business_center_outlined,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '所属业务：${business.name} · 付款模板：${business.pricingRule.paymentTerms}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3730A3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _sectionTitle('合同模板'),
        const SizedBox(height: 8),
        _buildTemplatePicker(),
        const SizedBox(height: 16),
        _sectionTitle('客户信息'),
        const SizedBox(height: 8),
        _buildInfoCard(),
        const SizedBox(height: 16),
        _sectionTitle('付款节点（到账进度按此跟踪）'),
        const SizedBox(height: 8),
        _buildPaymentsEditor(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _preview,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('预览合同'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('保存合同'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTemplatePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: RadioGroup<String>(
        groupValue: _template?.id,
        onChanged: (id) {
          if (id == null) return;
          setState(() {
            _template = widget.contractTemplates.firstWhere((e) => e.id == id);
          });
        },
        child: Column(
          children: widget.contractTemplates
              .map(
                (t) => RadioListTile<String>(
                  value: t.id,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    t.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    t.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: _inputDecoration('合同名称（选填）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clientCtrl,
            decoration: _inputDecoration('客户名称（必填）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('合同金额（万元，必填）'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsEditor() {
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
          for (var i = 0; i < _payments.length; i++) _buildPaymentRow(i),
          Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    setState(() => _payments.add(_PaymentRow.empty())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加节点'),
              ),
              const Spacer(),
              Text(
                '比例合计 ${(_ratioSum * 100).toStringAsFixed(0)}%'
                '${(_ratioSum - 1).abs() < 0.001 ? '' : '（建议合计 100%）'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (_ratioSum - 1).abs() < 0.001
                      ? const Color(0xFF10B981)
                      : const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          if (_amount > 0)
            Text(
              '各节点金额：${_payments.map((p) => '${p.nameCtrl.text.trim().isEmpty ? '未命名' : p.nameCtrl.text.trim()} ${(p.ratio * _amount).toStringAsFixed(2)} 万').join(' ｜ ')}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(int index) {
    final p = _payments[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: p.nameCtrl,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('节点名称（如 签约）'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: p.ratioCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('比例%'),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _payments.removeAt(index)),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}

/// 付款节点编辑行状态
class _PaymentRow {
  _PaymentRow({required String name, required double ratio})
    : nameCtrl = TextEditingController(text: name),
      ratioCtrl = TextEditingController(
        text: (ratio * 100).toStringAsFixed(0),
      );

  _PaymentRow.empty()
    : nameCtrl = TextEditingController(),
      ratioCtrl = TextEditingController(text: '50');

  final TextEditingController nameCtrl;
  final TextEditingController ratioCtrl;

  double get ratio =>
      (double.tryParse(ratioCtrl.text.trim()) ?? 0) / 100;
}
