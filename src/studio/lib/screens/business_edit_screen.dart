import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/store.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/toast.dart';

/// 新建业务（业务经营）：定义报价规则与模板，订单是业务的实例
class BusinessEditScreen extends StatefulWidget {
  const BusinessEditScreen({super.key});

  @override
  State<BusinessEditScreen> createState() => _BusinessEditScreenState();
}

class _BusinessEditScreenState extends State<BusinessEditScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController(text: '0.1');
  final _marginCtrl = TextEditingController(text: '30');
  final _paymentCtrl = TextEditingController();
  final _changeRuleCtrl = TextEditingController(
    text: '范围 / 工期 / 费用任一变更，须书面评估影响并经双方邮件确认后补签协议，口头约定无效。',
  );

  String _status = BusinessStatus.active;
  String _commercialModel = CommercialModels.presets.first;
  late final List<_StageRow> _stages;
  late List<FactorLevel> _difficulties;
  late List<FactorLevel> _scales;

  @override
  void initState() {
    super.initState();
    _stages = [
      _StageRow(name: '数据采集', workload: 0.5),
      _StageRow(name: '数据建模', workload: 1.0),
      _StageRow(name: '报告输出', workload: 1.0),
    ];
    _difficulties = PricingRule.defaultDifficultyLevels.toList();
    _scales = PricingRule.defaultScaleLevels.toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _unitPriceCtrl.dispose();
    _marginCtrl.dispose();
    _paymentCtrl.dispose();
    _changeRuleCtrl.dispose();
    for (final s in _stages) {
      s.dispose();
    }
    super.dispose();
  }

  double get _costEstimate {
    var sum = 0.0;
    for (final s in _stages) {
      sum += s.workload * (double.tryParse(_unitPriceCtrl.text.trim()) ?? 0);
    }
    return sum;
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showAppToast(context, '请填写业务名称');
      return;
    }
    final unitPrice = double.tryParse(_unitPriceCtrl.text.trim()) ?? 0.1;
    final marginPct = double.tryParse(_marginCtrl.text.trim()) ?? 30;
    final stages = _stages
        .where((s) => s.nameCtrl.text.trim().isNotEmpty)
        .map(
          (s) => StageDefault(
            name: s.nameCtrl.text.trim(),
            workload: s.workload,
          ),
        )
        .toList();
    final business = Business(
      id: BusinessStore.instance.nextBusinessId(),
      name: name,
      description: _descCtrl.text.trim(),
      status: _status,
      pricingRule: PricingRule(
        unitPrice: unitPrice,
        stageDefaults: stages,
        minGrossMargin: marginPct / 100,
        paymentTerms: _paymentCtrl.text.trim(),
        difficultyLevels: _difficulties,
        scaleLevels: _scales,
      ),
      commercialModel: _commercialModel,
      changeRuleTemplate: _changeRuleCtrl.text.trim(),
      created: DateTime.now().toIso8601String().substring(0, 10),
      updated: DateTime.now().toIso8601String().substring(0, 10),
    );
    BusinessStore.instance.addBusiness(business);
    showAppToast(context, '✅ 业务已创建：$name');
    Navigator.of(context).pop();
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
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 16 : 28,
        compact ? 16 : 28,
        24,
      ),
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
            const Text(
              '新建业务',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '业务是类：报价规则、毛利底线与付款节点定义在此，订单是业务的实例',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 16),
        _sectionTitle('基本信息'),
        const SizedBox(height: 8),
        _card([
          TextField(
            controller: _nameCtrl,
            decoration: _inputDecoration('业务名称（必填）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: _inputDecoration('业务描述（选填）'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final s in [
                BusinessStatus.active,
                BusinessStatus.watching,
                BusinessStatus.retired,
              ])
                ChoiceChip(
                  label: Text(s),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('商业模型'),
        const SizedBox(height: 8),
        _card([
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in CommercialModels.presets)
                ChoiceChip(
                  label: Text(m),
                  selected: _commercialModel == m,
                  onSelected: (_) => setState(() => _commercialModel = m),
                ),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('报价规则'),
        const SizedBox(height: 8),
        _card([
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _unitPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration('人天单价（万元）'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _marginCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration('毛利底线（%）'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paymentCtrl,
            decoration: _inputDecoration('付款节点模板（如：签约 50%，交付验收后 50%）'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '成本法估算：${_costEstimate.toStringAsFixed(2)} 万元',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('阶段工时基线（人天）'),
        const SizedBox(height: 8),
        _card([
          for (var i = 0; i < _stages.length; i++) _buildStageRow(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _stages.add(_StageRow.empty())),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加阶段'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('难度 / 量级档位（工时公式：基线 × 难度系数 × 量级系数）'),
        const SizedBox(height: 8),
        _card([
          _factorEditor('难度', _difficulties, (i, level) {
            setState(() => _difficulties[i] = level);
          }, () => setState(() => _difficulties.add(const FactorLevel(name: '', factor: 1.0)))),
          const SizedBox(height: 12),
          _factorEditor('量级', _scales, (i, level) {
            setState(() => _scales[i] = level);
          }, () => setState(() => _scales.add(const FactorLevel(name: '', factor: 1.0)))),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('变更规则模板'),
        const SizedBox(height: 8),
        _card([
          TextField(
            controller: _changeRuleCtrl,
            maxLines: 3,
            decoration: _inputDecoration('范围/工期/费用变更如何评估与确认'),
          ),
        ]),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
          ),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('创建业务'),
        ),
      ],
    );
  }

  Widget _buildStageRow(int index) {
    final s = _stages[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: s.nameCtrl,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('阶段名称'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: s.workloadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('人天'),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _stages.removeAt(index)),
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

  Widget _factorEditor(
    String label,
    List<FactorLevel> levels,
    void Function(int, FactorLevel) onChanged,
    VoidCallback onAdd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < levels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: ValueKey('$label-name-$i-${levels[i].name}'),
                    initialValue: levels[i].name,
                    decoration: _inputDecoration('档位名（如：高）'),
                    onChanged: (v) => onChanged(i, FactorLevel(name: v.trim(), factor: levels[i].factor)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$label-factor-$i-${levels[i].factor}'),
                    initialValue: levels[i].factor.toString(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration('系数'),
                    onChanged: (v) => onChanged(
                      i,
                      FactorLevel(
                        name: levels[i].name,
                        factor: double.tryParse(v.trim()) ?? 1.0,
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _card(List<Widget> children) {
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

/// 阶段工时编辑行状态
class _StageRow {
  _StageRow({required String name, required double workload})
    : nameCtrl = TextEditingController(text: name),
      workloadCtrl = TextEditingController(text: workload.toStringAsFixed(1));

  _StageRow.empty()
    : nameCtrl = TextEditingController(),
      workloadCtrl = TextEditingController(text: '1.0');

  final TextEditingController nameCtrl;
  final TextEditingController workloadCtrl;

  double get workload => double.tryParse(workloadCtrl.text.trim()) ?? 0;

  void dispose() {
    nameCtrl.dispose();
    workloadCtrl.dispose();
  }
}
