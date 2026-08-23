/// 往来留痕条目（书面确认优先：邮件确认 > 电话 > 会议；变更须有书面协议）
class LogEntry {
  const LogEntry({
    required this.date,
    required this.type,
    required this.note,
    this.by = '',
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? '邮件确认',
      note: json['note'] as String? ?? '',
      by: json['by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'type': type,
    'note': note,
    if (by.isNotEmpty) 'by': by,
  };

  /// 留痕日期 yyyy-MM-dd
  final String date;

  /// 类型：邮件确认 / 电话沟通 / 会议纪要 / 变更协议
  final String type;

  /// 内容说明（做了什么、结论是什么）
  final String note;

  /// 操作人署名（需求六最小闭环）
  final String by;
}
