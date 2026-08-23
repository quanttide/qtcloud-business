/// 操作留痕：一条历史记录（服务端记录，操作人来自请求头署名）
class HistoryEntry {
  const HistoryEntry({
    required this.time,
    required this.action,
    required this.entity,
    required this.name,
    this.detail = '',
    this.by = '',
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    time: json['time'] as String? ?? '',
    action: json['action'] as String? ?? '',
    entity: json['entity'] as String? ?? '',
    name: json['name'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
    by: json['by'] as String? ?? '',
  );

  final String time;
  final String action; // 新建 / 修改 / 删除
  final String entity; // 业务 / 报价 / 合同
  final String name;
  final String detail;

  /// 操作人（需求六最小闭环）
  final String by;

  Map<String, dynamic> toJson() => {
    'time': time,
    'action': action,
    'entity': entity,
    'name': name,
    if (detail.isNotEmpty) 'detail': detail,
    if (by.isNotEmpty) 'by': by,
  };
}
