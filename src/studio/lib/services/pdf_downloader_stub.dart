import 'dart:typed_data';

/// 非 Web 平台的空实现（Studio 实际只跑在 Web 上，此处仅保证可编译/测试）
void downloadPdf(Uint8List bytes, String filename) {}
