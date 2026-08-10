import 'package:flutter/material.dart';

import '../models/template.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/toast.dart';

/// 新建合同（US3）：选择合同模板 → 填充客户信息 → 预览合同内容
class ContractEditScreen extends StatefulWidget {
  final List<BusinessTemplate> contractTemplates;

  const ContractEditScreen({super.key, required this.contractTemplates});

  @override
  State<ContractEditScreen> createState() => _ContractEditScreenState();
}

class _ContractEditScreenState extends State<ContractEditScreen> {
  final _nameCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();

  BusinessTemplate? _template;

  @override
  void initState() {
    super.initState();
    if (widget.contractTemplates.isNotEmpty) {
      _template = widget.contractTemplates.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final client = _clientCtrl.text.trim();
    if (client.isEmpty) {
      showAppToast(context, '请填写客户名称');
      return;
    }
    showAppToast(context, '✅ 合同已保存（待签署）');
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
            const Text(
              '新建合同',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle('合同模板'),
        const SizedBox(height: 8),
        _buildTemplatePicker(),
        const SizedBox(height: 16),
        _sectionTitle('客户信息'),
        const SizedBox(height: 8),
        _buildInfoCard(),
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
