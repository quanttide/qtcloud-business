import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/quotation.dart';
import '../models/store.dart';
import '../models/template.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/toast.dart';
import '../widgets/dialogs/export_dialog.dart';

/// 新建报价（US1）：选择方案模板 → 填充客户信息 → 调整产品明细和价格 → 导出 PDF
/// 传入 business 时即"从业务发起报价"：按业务报价规则预填明细
class QuotationEditScreen extends StatefulWidget {
  final List<BusinessTemplate> quotationTemplates;
  final Business? business;

  const QuotationEditScreen({
    super.key,
    required this.quotationTemplates,
    this.business,
  });

  @override
  State<QuotationEditScreen> createState() => _QuotationEditScreenState();
}

class _QuotationEditScreenState extends State<QuotationEditScreen> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();

  BusinessTemplate? _template;
  late final List<_ProductRow> _rows;

  /// 所属业务：从业务详情进入时由外部传入；
  /// 从工作台新建时必须手动选择——订单不能脱离业务独立存在
  String? _businessId;

  /// 从业务发起时选中的难度 / 量级档位（工时公式参数）
  FactorLevel? _difficulty;
  FactorLevel? _scale;

  /// 下拉选择的业务（与外部传入二选一）
  Business? get _pickedBusiness {
    if (_businessId == null) return null;
    for (final b in BusinessStore.instance.data.businesses) {
      if (b.id == _businessId) return b;
    }
    return null;
  }

  Business? get _business => widget.business ?? _pickedBusiness;

  /// 业务规则没写清 → 拦截进入订单执行
  bool get _ruleBlocked => _business != null && !_business!.isRuleComplete;

  @override
  void initState() {
    super.initState();
    _rows = [];
    final business = widget.business;
    if (business != null) {
      _initFromBusinessRule(business);
    } else if (widget.quotationTemplates.isNotEmpty) {
      _applyTemplate(widget.quotationTemplates.first);
    }
  }

  void _initFromBusinessRule(Business business) {
    if (!business.isRuleComplete) return;
    FactorLevel? pick(List<FactorLevel> levels) =>
        levels.isEmpty ? null : levels[levels.length > 1 ? 1 : 0];
    // 默认取中间档位（如 低/中/高 → 中）
    _difficulty = pick(business.pricingRule.difficultyLevels);
    _scale = pick(business.pricingRule.scaleLevels);
    // 代入业务的报价规则（工时公式算出各阶段人天）
    final fresh = BusinessStore.productsFromRule(
      business.pricingRule,
      difficulty: _difficulty,
      scale: _scale,
    )
        .map(
          (p) => _ProductRow(
            name: p.name,
            price: p.unitPrice,
            qty: p.quantity,
            discount: p.discount,
          ),
        )
        .toList();
    _rows
      ..clear()
      ..addAll(fresh);
  }

  /// 切换难度/量级后按工时公式重算明细（保留已改的单价与折扣）
  void _applyFactors() {
    final business = _business;
    if (business == null || _difficulty == null || _scale == null) return;
    final fresh = BusinessStore.productsFromRule(
      business.pricingRule,
      difficulty: _difficulty,
      scale: _scale,
    );
    setState(() {
      for (var i = 0; i < fresh.length && i < _rows.length; i++) {
        _rows[i].nameCtrl.text = fresh[i].name;
        _rows[i].qtyCtrl.text = fresh[i].quantity.toStringAsFixed(1);
      }
    });
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

  /// 定价说明：写明工时公式代入的难度/量级参数，报价可复核
  String get _pricingNote {
    final business = _business;
    if (business == null) return '';
    final factors = (_difficulty != null || _scale != null)
        ? '（难度 ${_difficulty?.name ?? '-'} ×${_difficulty?.factor.toStringAsFixed(1) ?? '-'}'
            ' · 量级 ${_scale?.name ?? '-'} ×${_scale?.factor.toStringAsFixed(1) ?? '-'}）'
        : '';
    return '按业务「${business.name}」报价规则核算$factors，'
        '毛利底线 ${(business.pricingRule.minGrossMargin * 100).toStringAsFixed(0)}%';
  }

  void _save() {
    final client = _clientCtrl.text.trim();
    if (_business == null) {
      showAppToast(context, '订单必须挂在业务下：请先选择所属业务');
      return;
    }
    if (client.isEmpty) {
      showAppToast(context, '请填写客户名称');
      return;
    }
    if (_rows.isEmpty || _rows.every((r) => r.nameCtrl.text.trim().isEmpty)) {
      showAppToast(context, '请至少添加一条产品明细');
      return;
    }
    final business = _business;
    final products = _rows
        .where((r) => r.nameCtrl.text.trim().isNotEmpty)
        .map(
          (r) => QuotationProduct(
            name: r.nameCtrl.text.trim(),
            unitPrice: r.price,
            quantity: r.qty,
            discount: r.discount,
          ),
        )
        .toList();
    final now = DateTime.now().toIso8601String().substring(0, 10);
    BusinessStore.instance.addQuotation(
      Quotation(
        id: BusinessStore.instance.nextQuotationId(),
        businessId: business?.id ?? '',
        name: _nameCtrl.text.trim().isEmpty
            ? '$client · 报价单'
            : _nameCtrl.text.trim(),
        client: client,
        template: _template?.name ?? '',
        status: '草稿',
        version: 1,
        created: now,
        updated: now,
        pricingNote: _pricingNote,
        products: products,
        totalAmount: _total,
        versions: [
          QuotationVersion(
            version: 1,
            updated: now,
            totalAmount: _total,
            note: '初版报价',
          ),
        ],
      ),
    );
    showAppToast(context, '✅ 报价单已保存（v1 草稿）');
    Navigator.of(context).pop();
  }

  void _export() {
    final client = _clientCtrl.text.trim().isEmpty
        ? '（未填客户）'
        : _clientCtrl.text.trim();
    final name = _nameCtrl.text.trim().isEmpty ? '$client · 报价单' : _nameCtrl.text.trim();
    final products = _rows
        .where((r) => r.nameCtrl.text.trim().isNotEmpty)
        .map(
          (r) => QuotationProduct(
            name: r.nameCtrl.text.trim(),
            unitPrice: r.price,
            quantity: r.qty,
            discount: r.discount,
          ),
        )
        .toList();
    final now = DateTime.now().toIso8601String().substring(0, 10);
    showExportDialog(
      context,
      quotation: Quotation(
        id: '草稿预览',
        businessId: _business?.id ?? '',
        name: name,
        client: client,
        template: _template?.name ?? '',
        status: '草稿',
        version: 1,
        created: now,
        updated: now,
        pricingNote: '',
        products: products,
        totalAmount: _total,
        versions: const [],
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
            Text(
              widget.business == null ? '新建报价' : '从业务发起报价',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 所属业务：外部传入直接展示；工作台新建时必选下拉
        if (widget.business != null) ...[
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
                    '所属业务：${widget.business!.name} · 人天单价 ${widget.business!.pricingRule.unitPrice.toStringAsFixed(2)} 万元 · 毛利底线 ${(widget.business!.pricingRule.minGrossMargin * 100).toStringAsFixed(0)}%',
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
        ] else ...[
          _buildBusinessPicker(),
          const SizedBox(height: 16),
        ],
        // 模板选择（未挂业务前可选；挂上业务后以业务规则为准）
        if (widget.business == null && _businessId == null && !_ruleBlocked) ...[
          _sectionTitle('方案模板'),
          const SizedBox(height: 8),
          _buildTemplatePicker(),
          const SizedBox(height: 16),
        ],
        // 业务规则没写清 → 拦截
        if (_ruleBlocked) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.block_outlined,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '该业务定义不明确，不能发起报价',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '缺少：${_business!.missingRuleFields().join('、')}。'
                  '写清报价公式与毛利底线，才算业务明确——请先回业务定义补全。',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          // 难度 / 量级选择（工时公式参数）
          if (_business != null &&
              (_business!.pricingRule.difficultyLevels.isNotEmpty ||
                  _business!.pricingRule.scaleLevels.isNotEmpty)) ...[
            _buildFactorSelector(),
            const SizedBox(height: 16),
          ],
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
      ],
    );
  }

  // ===== 所属业务选择（订单不能脱离业务） =====
  Widget _buildBusinessPicker() {
    final businesses = BusinessStore.instance.data.businesses;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _businessId == null
              ? const Color(0xFFFDE68A)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_center_outlined,
                size: 16,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              const Text(
                '所属业务（必选，订单是业务的实例）',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (businesses.isEmpty)
            const Text(
              '暂无业务可挂——请先到「业务」新建并写清报价规则',
              style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _businessId,
              isDense: true,
              hint: const Text('选择要挂在哪个业务下'),
              decoration: _inputDecoration(''),
              items: [
                for (final b in businesses)
                  DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      '${b.name}（${b.status} · 单价 ${b.pricingRule.unitPrice.toStringAsFixed(2)} 万）',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id == null || id == _businessId) return;
                setState(() => _businessId = id);
                final b = businesses.firstWhere((e) => e.id == id);
                // 挂上业务即代入其报价规则与流程参数
                _template = null;
                _initFromBusinessRule(b);
              },
            ),
        ],
      ),
    );
  }

  // ===== 难度/量级档位选择 =====
  Widget _buildFactorSelector() {
    final rule = _business!.pricingRule;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rule.difficultyLevels.isNotEmpty)
            _factorChips('难度', rule.difficultyLevels, _difficulty, (f) {
              setState(() => _difficulty = f);
              _applyFactors();
            }),
          if (rule.scaleLevels.isNotEmpty) ...[
            if (rule.difficultyLevels.isNotEmpty) const SizedBox(height: 8),
            _factorChips('量级', rule.scaleLevels, _scale, (f) {
              setState(() => _scale = f);
              _applyFactors();
            }),
          ],
          const SizedBox(height: 6),
          Text(
            '工时公式：阶段基线 × 难度系数 × 量级系数，切换后自动重算人天',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _factorChips(
    String label,
    List<FactorLevel> levels,
    FactorLevel? selected,
    ValueChanged<FactorLevel> onTap,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              for (final f in levels)
                ChoiceChip(
                  label: Text('${f.name} ×${f.factor}'),
                  selected: selected == f,
                  onSelected: (_) => onTap(f),
                ),
            ],
          ),
        ),
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
          child: Material(
            type: MaterialType.transparency,
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

  double get price => _num(priceCtrl);
  double get qty => _num(qtyCtrl);
  double get discount => _num(discountCtrl);

  double get subtotal => price * qty * discount;
}
