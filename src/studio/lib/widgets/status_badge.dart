import 'package:flutter/material.dart';

/// 三态语义色（todo 浅灰 / active 品牌靛蓝 / done 绿色）
class ItemStatusStyle {
  const ItemStatusStyle._();

  static const Color todo = Color(0xFF9CA3AF);
  static const Color active = Color(0xFF4F46E5);
  static const Color done = Color(0xFF16A34A);

  static Color colorOf(String status) {
    switch (status) {
      case 'done':
        return done;
      case 'active':
        return active;
      default:
        return todo;
    }
  }
}

/// 状态徽章（进行中/已完成/待启动 等文本状态）
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = ItemStatusStyle.colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
