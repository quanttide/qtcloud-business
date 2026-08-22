/// 操作留痕：一条历史记录（谁在系统里做了什么由服务端记录，v0.1 无用户体系）
class HistoryEntry {
  const HistoryEntry({
    required this.time,
    required this.action,
    required this.entity,
    required this.name,
    this.detail = '',
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    time: json['time'] as String? ?? '',
    action: json['action'] as String? ?? '',
    entity: json['entity'] as String? ?? '',
    name: json['name'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
  );

  final String time;
  final String action; // 新建 / 修改 / 删除
  final String entity; // 业务 / 报价 / 合同
  final String name;
  final String detail;

  Map<String, dynamic> toJson() => {
    'time': time,
    'action': action,
    'entity': entity,
    'name': name,
    if (detail.isNotEmpty) 'detail': detail,
  };
}
