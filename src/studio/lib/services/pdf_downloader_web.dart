import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// 浏览器端触发文件下载
void downloadPdf(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  // 稍后回收 blob URL，避免下载尚未开始就被回收
  Timer(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
