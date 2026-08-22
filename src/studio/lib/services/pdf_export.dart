import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/quotation.dart';

export 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart';
import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart';

pw.Font? _font;

Future<void> _ensureFont() async {
  if (_font != null) return;
  // TODO: SimHei 版权受限，公开发布前换成 OFL 字体（如 Noto Sans SC）
  final data = await rootBundle.load('assets/fonts/simhei.ttf');
  _font = pw.Font.ttf(data);
}

/// 报价日期 + 有效期（30 天）
String validUntil() {
  final until = DateTime.now().add(const Duration(days: 30));
  return '${until.year}-${until.month.toString().padLeft(2, '0')}-${until.day.toString().padLeft(2, '0')}';
}

String today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// 金额（万元）转人民币大写
String moneyUpper(double wanAmount) {
  const d = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖'];
  const u = ['', '拾', '佰', '仟'];
  const p10 = [1, 10, 100, 1000];

  String four(int n) {
    final s = StringBuffer();
    var zeroPending = false;
    var started = false;
    for (var i = 3; i >= 0; i--) {
      final digit = (n ~/ p10[i]) % 10;
      if (digit == 0) {
        if (started) zeroPending = true;
      } else {
        if (zeroPending) s.write(d[0]);
        zeroPending = false;
        started = true;
        s.write(d[digit]);
        s.write(u[i]);
      }
    }
    return s.toString();
  }

  var fenTotal = (wanAmount * 1000000).round(); // 万元 → 分
  if (fenTotal <= 0) return '零元整';
  final yuan = fenTotal ~/ 100;
  final fen = fenTotal % 100;

  final yi = yuan ~/ 100000000;
  final rest = yuan % 100000000;
  final wan = rest ~/ 10000;
  final ge = rest % 10000;

  final parts = <String>[];
  if (yi > 0) {
    parts..add(four(yi))..add('亿');
    if (wan > 0 && wan < 1000) parts.add('零');
  }
  if (wan > 0) parts..add(four(wan))..add('万');
  if ((yi > 0 || wan > 0) && ge > 0 && ge < 1000) parts.add('零');
  if (ge > 0 || parts.isEmpty) parts.add(four(ge));
  var result = '${parts.join()}元';

  if (fen == 0) {
    result += '整';
  } else {
    final jiao = fen ~/ 10;
    if (yuan > 0 && jiao == 0) result += '零';
    if (jiao > 0) result += '${d[jiao]}角';
    if (fen % 10 > 0) result += '${d[fen % 10]}分';
  }
  return result;
}

/// 生成报价单 PDF（US1：可直接发客户的版式）
Future<Uint8List> buildQuotationPdf(Quotation quotation) async {
  await _ensureFont();
  final font = _font!;

  const indigo = PdfColor.fromInt(0xFF4F46E5);
  const slate = PdfColor.fromInt(0xFF64748B);
  const ink = PdfColor.fromInt(0xFF1E293B);
  const light = PdfColor.fromInt(0xFFF1F5F9);
  const line = PdfColor.fromInt(0xFFE2E8F0);

  pw.TextStyle ts({
    double size = 10,
    bool bold = false,
    PdfColor? color,
  }) => pw.TextStyle(
    fontSize: size,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: color ?? ink,
  );

  pw.Widget cell(
    String text, {
    bool bold = false,
    PdfColor? color,
    double size = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(text, style: ts(size: size, bold: bold, color: color)),
    );
  }

  final doc = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: font));

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 36),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 抬头
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('量潮', style: ts(size: 26, bold: true, color: indigo)),
                  pw.SizedBox(height: 2),
                  pw.Text('QUANTTIDE', style: ts(size: 9, color: slate)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('报价单', style: ts(size: 22, bold: true)),
                  pw.SizedBox(height: 2),
                  pw.Text('QUOTATION', style: ts(size: 9, color: slate)),
                ],
              ),
            ],
          ),
          pw.Divider(color: indigo, thickness: 1.5),
          pw.SizedBox(height: 12),

          // 客户与基本信息
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    cell('客户名称：${quotation.client}'),
                    cell(
                      '方案模板：${quotation.template.isEmpty ? '—' : quotation.template}',
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    cell('报价编号：${quotation.id}'),
                    cell('报价日期：${today()}　有效期至：${validUntil()}'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // 产品明细表
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: line, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: light),
            headerStyle: ts(bold: true),
            cellStyle: ts(),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            headers: ['产品与服务', '单价（万元）', '数量', '折扣', '小计（万元）'],
            data: [
              for (final p in quotation.products)
                [
                  p.name,
                  p.unitPrice.toStringAsFixed(2),
                  '${p.quantity.toStringAsFixed(0)} 人天',
                  p.discount < 1.0
                      ? '${(p.discount * 10).toStringAsFixed(1)} 折'
                      : '—',
                  p.subtotal.toStringAsFixed(2),
                ],
            ],
          ),
          pw.SizedBox(height: 8),

          // 合计行
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const pw.BoxDecoration(color: light),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '合计（大写）：${moneyUpper(quotation.totalAmount)}',
                  style: ts(bold: true),
                ),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('合计金额：', style: ts()),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      '￥ ${quotation.totalAmount.toStringAsFixed(2)} 万元',
                      style: ts(size: 13, bold: true, color: indigo),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (quotation.pricingNote.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('定价说明', style: ts(size: 11, bold: true)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: line, width: 0.5),
              ),
              child: pw.Text(quotation.pricingNote, style: ts(color: slate)),
            ),
          ],

          pw.Spacer(),

          // 联系人栏
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: line, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('商务经理：＿＿＿＿＿＿＿', style: ts()),
                pw.Text('联系电话：＿＿＿＿＿＿＿', style: ts()),
                pw.Text('客户确认签字：＿＿＿＿＿＿＿', style: ts()),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              '本报价单自报价之日起 30 天内有效 ｜ 量潮 QUANTTIDE · quanttide.com',
              style: ts(size: 8, color: slate),
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

/// 导出并触发浏览器下载（Web）
Future<String> exportQuotationPdf(Quotation quotation) async {
  final bytes = await buildQuotationPdf(quotation);
  final filename = '报价单-${quotation.name}-v${quotation.version}.pdf';
  downloadPdf(bytes, filename);
  return filename;
}
