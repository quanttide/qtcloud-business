import 'package:flutter/material.dart';

import '../models/quotation.dart';
import '../models/store.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/sidebar.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/toast.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/export_dialog.dart';

/// 报价详情：产品明细、定价说明、版本历史（US2）、导出（US1）
class QuotationDetailScreen extends StatelessWidget {
  final Quotation quotation;

  const QuotationDetailScreen({super.key, required this.quotation});

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
        // 产品明细
        _sectionTitle('产品明细'),
        const SizedBox(height: 8),
        _buildProductsCard(),
        const SizedBox(height: 16),
        // 定价说明
        if (quotation.pricingNote.isNotEmpty) ...[
          _sectionTitle('定价说明'),
          const SizedBox(height: 8),
          _buildInfoCard(quotation.pricingNote),
          const SizedBox(height: 16),
        ],
        // 版本历史
        Row(
          children: [
            _sectionTitle('版本历史'),
            if (quotation.versions.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '共 ${quotation.versions.length} 版',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _buildVersionsCard(),
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
                    quotation.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  StatusBadge(status: quotation.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '客户：${quotation.client} ｜ 模板：${quotation.template}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 2),
              Text(
                '创建于 ${quotation.created} ｜ 更新于 ${quotation.updated}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 导出报价单 PDF（US1）
        InkWell(
          onTap: () => showExportDialog(context, quotation: quotation),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: compact
                ? const EdgeInsets.all(8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: compact
                ? const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 14,
                    color: Colors.white,
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '导出',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // 复制为新报价（商务工作可复制、可交接）
        Tooltip(
          message: '以此单为底样新建一份草稿报价',
          child: InkWell(
            onTap: () => _duplicateQuotation(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.copy_all_outlined,
                size: 16,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 删除（顶部显眼入口）
        Tooltip(
          message: '删除该报价',
          child: InkWell(
            onTap: () => _deleteQuotation(context),
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

  Future<void> _deleteQuotation(BuildContext context) async {
    final ok = await confirmDelete(
      context,
      title: '删除「${quotation.name}」？',
      content: '删除后不可恢复。',
    );
    if (!ok || !context.mounted) return;
    await BusinessStore.instance.deleteQuotation(quotation.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  /// 复制为新报价：以本单为底样生成一份新草稿（v1），挂同一业务
  Future<void> _duplicateQuotation(BuildContext context) async {
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final copy = Quotation(
      id: BusinessStore.instance.nextQuotationId(),
      businessId: quotation.businessId,
      name: '${quotation.name}（复制）',
      client: quotation.client,
      template: quotation.template,
      status: '草稿',
      version: 1,
      created: now,
      updated: now,
      pricingNote: quotation.pricingNote.isEmpty
          ? ''
          : '${quotation.pricingNote}（复制自 ${quotation.id}）',
      products: quotation.products
          .map(
            (p) => QuotationProduct(
              name: p.name,
              unitPrice: p.unitPrice,
              quantity: p.quantity,
              discount: p.discount,
            ),
          )
          .toList(),
      totalAmount: quotation.totalAmount,
      versions: [
        QuotationVersion(
          version: 1,
          updated: now,
          totalAmount: quotation.totalAmount,
          note: '复制自 ${quotation.name} v${quotation.version}',
        ),
      ],
    );
    await BusinessStore.instance.addQuotation(copy);
    if (context.mounted) {
      showAppToast(context, '✅ 已复制为新草稿：${copy.id}');
    }
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

  // ===== 产品明细表 =====
  Widget _buildProductsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          for (final p in quotation.products)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Text(
                    '${p.unitPrice.toStringAsFixed(1)} × ${p.quantity.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (p.discount < 1.0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${(p.discount * 10).toStringAsFixed(1)} 折',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Text(
                    '${p.subtotal.toStringAsFixed(1)} 万',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 16),
          Row(
            children: [
              const Spacer(),
              const Text(
                '合计',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(
                '${quotation.totalAmount.toStringAsFixed(1)} 万元',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
      ),
    );
  }

  // ===== 版本历史 =====
  Widget _buildVersionsCard() {
    if (quotation.versions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const Text(
          '暂无历史版本',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          for (final v in quotation.versions)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v.version == quotation.version
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v${v.version}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: v.version == quotation.version
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.note.isEmpty ? '（无备注）' : v.note,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '更新于 ${v.updated}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (v.version == quotation.version)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        '当前',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  Text(
                    '${v.totalAmount.toStringAsFixed(1)} 万元',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
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
