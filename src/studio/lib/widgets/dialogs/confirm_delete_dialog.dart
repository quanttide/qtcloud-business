import 'package:flutter/material.dart';

/// 删除确认弹窗：返回 true 表示用户确认删除
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  return result ?? false;
}
