import 'package:flutter/material.dart';

/// 全局侧边栏：量 logo + 导航图标 + help，页面共用
class Sidebar extends StatelessWidget {
  /// 是否高亮仪表盘图标（当前上下文）
  final bool active;

  const Sidebar({super.key, this.active = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '量',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 16),
          _SidebarIcon(Icons.space_dashboard_outlined, active: active),
          const Spacer(),
          const _SidebarIcon(Icons.help_outline),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _SidebarIcon(this.icon, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0E7FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: active ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
      ),
    );
  }
}
