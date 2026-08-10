import 'package:flutter/material.dart';

/// 响应式断点容器：< 640 移动端，≥ 640 桌面
class Responsive extends StatelessWidget {
  static const double mobileBreakpoint = 640;

  final Widget mobile;
  final Widget desktop;

  const Responsive({super.key, required this.mobile, required this.desktop});

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < mobileBreakpoint ? mobile : desktop,
    );
  }
}

/// 页面左右留白：移动端 16，桌面 28
EdgeInsets pageHPadding(BuildContext context) =>
    EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 28);
