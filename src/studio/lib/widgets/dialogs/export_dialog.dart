import 'package:flutter/material.dart';

import '../../models/quotation.dart';
import '../../services/pdf_export.dart';
import '../common/toast.dart';

/// 报价单导出弹窗：点击「下载」真实生成 PDF 并触发浏览器下载
class ExportDialog extends StatefulWidget {
  final Quotation quotation;

  const ExportDialog({super.key, required this.quotation});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _generating = false;

  String get _filename =>
      '报价单-${widget.quotation.name}-v${widget.quotation.version}.pdf';

  Future<void> _download(BuildContext context) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await buildQuotationPdf(widget.quotation);
      downloadPdf(bytes, _filename);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showAppToast(context, '📥 下载完成：$_filename');
    } catch (_) {
      if (!mounted) return;
      setState(() => _generating = false);
      showAppToast(context, 'PDF 生成失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotationName = widget.quotation.name;
    final version = widget.quotation.version;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '导出报价单',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quotationName · v$version',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 14,
                    color: Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filename,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _download(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        _generating ? '生成中…' : '下载',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showExportDialog(
  BuildContext context, {
  required Quotation quotation,
}) {
  return showDialog(
    context: context,
    builder: (context) => ExportDialog(quotation: quotation),
  );
}
