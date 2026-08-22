import 'package:flutter/material.dart';

import '../../models/store.dart';
import 'toast.dart';

/// 全局侧边栏：量 logo + 导航图标 + 刷新 + help，页面共用
class Sidebar extends StatelessWidget {
  /// 当前激活的路由（用于高亮导航图标）
  final String route;

  const Sidebar({super.key, this.route = '/'});

  static const _items = [
    (Icons.space_dashboard_outlined, '工作台', '/'),
    (Icons.business_center_outlined, '业务', '/businesses'),
    (Icons.request_quote_outlined, '报价', '/quotations'),
    (Icons.description_outlined, '合同', '/contracts'),
  ];

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
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SidebarIcon(
                item.$1,
                tooltip: item.$2,
                active: route == item.$3,
                onTap: () {
                  if (route == item.$3) return;
                  Navigator.of(context).pushReplacementNamed(item.$3);
                },
              ),
            ),
          ),
          const Spacer(),
          _SidebarIcon(
            Icons.sync,
            tooltip: '刷新共享数据',
            onTap: () => _refreshData(context),
          ),
          const _SidebarIcon(Icons.help_outline),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 从服务端拉取他人变更，成功后重建当前页
  Future<void> _refreshData(BuildContext context) async {
    final navigator = Navigator.of(context);
    final unsynced = BusinessStore.instance.hasUnsyncedChanges;
    final ok = await BusinessStore.instance.refresh();
    if (!context.mounted) return;
    if (ok) {
      showAppToast(context, '已更新为最新共享数据');
      navigator.pushReplacementNamed(route);
    } else if (unsynced) {
      showAppToast(context, '本机有未同步的修改，已保留；恢复网络后重试');
    } else {
      showAppToast(context, '刷新失败：无法连接数据服务');
    }
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final String? tooltip;

  const _SidebarIcon(this.icon, {this.active = false, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
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
    if (tooltip == null) return iconWidget;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: iconWidget,
      ),
    );
  }
}
