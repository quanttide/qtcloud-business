import 'package:flutter/material.dart';

import '../../models/log_entry.dart';

/// 往来留痕卡（书面确认优先）：登记邮件确认/电话沟通/会议纪要/变更协议
class LogsCard extends StatelessWidget {
  const LogsCard({super.key, required this.logs, required this.onAdd});

  final List<LogEntry> logs;
  final ValueChanged<LogEntry> onAdd;

  static const _types = ['邮件确认', '电话沟通', '会议纪要', '变更协议'];

  Future<void> _add(BuildContext context) async {
    final entry = await showDialog<LogEntry>(
      context: context,
      builder: (context) => const _LogEntryDialog(),
    );
    if (entry != null) onAdd(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logs.isEmpty)
            const Text(
              '暂无留痕记录——重要沟通请补书面确认',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          for (final log in logs.reversed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _typeIcon(log.type),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log.type} · ${log.date}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        if (log.note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            log.note,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _add(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
            ),
            icon: const Icon(Icons.post_add, size: 14),
            label: const Text('登记留痕'),
          ),
        ],
      ),
    );
  }

  static Widget _typeIcon(String type) {
    switch (type) {
      case '邮件确认':
        return const Icon(Icons.mark_email_read_outlined,
            size: 16, color: Color(0xFF4F46E5));
      case '电话沟通':
        return const Icon(Icons.call_outlined,
            size: 16, color: Color(0xFF0EA5E9));
      case '会议纪要':
        return const Icon(Icons.groups_outlined,
            size: 16, color: Color(0xFF64748B));
      default:
        return const Icon(Icons.gavel_outlined,
            size: 16, color: Color(0xFFF59E0B));
    }
  }
}

/// 登记留痕弹窗：选类型 + 填说明（日期自动记当天）
class _LogEntryDialog extends StatefulWidget {
  const _LogEntryDialog();

  @override
  State<_LogEntryDialog> createState() => _LogEntryDialogState();
}

class _LogEntryDialogState extends State<_LogEntryDialog> {
  String _type = '邮件确认';
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写内容说明')),
      );
      return;
    }
    final today = DateTime.now().toIso8601String().substring(0, 10);
    Navigator.of(context).pop(LogEntry(date: today, type: _type, note: note));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '登记往来留痕',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '书面确认优先：报价确认、变更协议务必留邮件',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                for (final t in LogsCard._types)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '内容说明（做了什么、结论是什么）',
                hintStyle:
                    const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                    ),
                    child: const Text('保存留痕'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
