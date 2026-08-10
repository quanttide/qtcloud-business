import 'package:flutter/material.dart';

/// 业务状态徽章（报价/合同状态配色）
///
/// - 绿：已确认 / 已签署 / 已归档
/// - 蓝：已发送 / 待签署
/// - 黄：草稿
/// - 灰：已失效 / 其他
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case '已确认':
      case '已签署':
      case '已归档':
        return const Color(0xFFD1FAE5);
      case '已发送':
      case '待签署':
        return const Color(0xFFDBEAFE);
      case '草稿':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _fg {
    switch (status) {
      case '已确认':
      case '已签署':
      case '已归档':
        return const Color(0xFF065F46);
      case '已发送':
      case '待签署':
        return const Color(0xFF1D4ED8);
      case '草稿':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _fg),
      ),
    );
  }
}
