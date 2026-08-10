import 'package:flutter/material.dart';

import '../models/template.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/toast.dart';
import '../widgets/dialogs/export_dialog.dart';

/// 新建报价（US1）：选择方案模板 → 填充客户信息 → 调整产品明细和价格 → 导出 PDF
class QuotationEditScreen extends StatefulWidget {
  final List<BusinessTemplate> quotationTemplates;

  const QuotationEditScreen({super.key, required this.quotationTemplates});

  @override
  State<QuotationEditScreen> createState() => _QuotationEditScreenState();
}

class _QuotationEditScreenState extends State<QuotationEditScreen> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();

  BusinessTemplate? _template;
  late final List<_ProductRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [];
    if (widget.quotationTemplates.isNotEmpty) {
      _applyTemplate(widget.quotationTemplates.first);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    for (final r in _rows) {
      r.nameCtrl.dispose();
      r.priceCtrl.dispose();
      r.qtyCtrl.dispose();
      r.discountCtrl.dispose();
    }
    super.dispose();
  }

  void _applyTemplate(BusinessTemplate template) {
    setState(() {
      _template = template;
      _rows
        ..clear()
        ..addAll(
          template.products.map(
            (p) => _ProductRow(
              name: p.name,
              price: p.unitPrice,
              qty: p.quantity,
              discount: p.discount,
            ),
          ),
        );
    });
  }

  double get _total {
    var sum = 0.0;
    for (final r in _rows) {
      sum += r.subtotal;
    }
    return sum;
  }

  void _save() {
    final client = _clientCtrl.text.trim();
    if (client.isEmpty) {
      showAppToast(context, '请填写客户名称');
      return;
    }
    if (_rows.isEmpty || _rows.every((r) => r.nameCtrl.text.trim().isEmpty)) {
      showAppToast(context, '请至少添加一条产品明细');
      return;
    }
    showAppToast(context, '✅ 报价单已保存（v1，待发送）');
    Navigator.of(context).pop();
  }

  void _export() {
    showExportDialog(
      context,
      quotationName: _nameCtrl.text.trim().isEmpty
          ? '未命名报价'
          : _nameCtrl.text.trim(),
      version: 1,
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
    return ListView(
      padding: pageHPadding(context).add(const EdgeInsets.only(top: 16)),
      children: [
        // 头部
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
            const Text(
              '新建报价',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 模板选择
        _sectionTitle('方案模板'),
        const SizedBox(height: 8),
        _buildTemplatePicker(),
        const SizedBox(height: 16),
        // 客户信息
        _sectionTitle('客户信息'),
        const SizedBox(height: 8),
        _buildInfoCard(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecoration('报价名称（选填）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clientCtrl,
              decoration: _inputDecoration('客户名称（必填）'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 产品明细
        _sectionTitle('产品明细（可调整价格与折扣）'),
        const SizedBox(height: 8),
        _buildProductsEditor(),
        const SizedBox(height: 12),
        // 合计
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '合计：${_total.toStringAsFixed(1)} 万元',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F46E5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 操作
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('导出 PDF'),
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
                label: const Text('保存报价'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===== 模板选择 =====
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
          final t = widget.quotationTemplates.firstWhere((e) => e.id == id);
          _applyTemplate(t);
        },
        child: Column(
          children: widget.quotationTemplates
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

  // ===== 产品明细编辑器 =====
  Widget _buildProductsEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _rows.length; i++) _buildProductRow(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _rows.add(_ProductRow.empty())),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加明细'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(int index) {
    final r = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: r.nameCtrl,
              decoration: _inputDecoration('产品名称'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: r.priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('单价(万)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: r.qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('数量'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: r.discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('折扣(0-1)'),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _rows.removeAt(index)),
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

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(children: children),
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

/// 产品明细编辑行状态
class _ProductRow {
  _ProductRow({
    required String name,
    required double price,
    required double qty,
    required double discount,
  }) : nameCtrl = TextEditingController(text: name),
       priceCtrl = TextEditingController(text: price.toStringAsFixed(1)),
       qtyCtrl = TextEditingController(text: qty.toStringAsFixed(0)),
       discountCtrl = TextEditingController(text: discount.toStringAsFixed(1));

  _ProductRow.empty()
    : nameCtrl = TextEditingController(),
      priceCtrl = TextEditingController(text: '0.1'),
      qtyCtrl = TextEditingController(text: '1'),
      discountCtrl = TextEditingController(text: '1.0');

  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController discountCtrl;

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  double get subtotal => _num(priceCtrl) * _num(qtyCtrl) * _num(discountCtrl);
}
