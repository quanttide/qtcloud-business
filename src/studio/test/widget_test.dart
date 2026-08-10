import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_business_studio/screens/dashboard_screen.dart';

void main() {
  testWidgets('仪表盘从 seed JSON 异步加载并渲染报价与合同', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    // 初始加载态
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 真实异步 IO：等待 rootBundle 加载 seed JSON
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    // 统计卡片
    expect(find.text('报价总数'), findsOneWidget);
    expect(find.text('待签署'), findsWidgets); // 统计卡片 + 合同状态徽章

    // 报价与合同区块
    expect(find.text('报价（2）'), findsOneWidget);
    expect(find.text('合同（2）'), findsOneWidget);

    // 报价条目（名称 + 版本）
    expect(find.text('议事决议数据需求点  v3'), findsOneWidget);
    expect(find.text('已确认'), findsWidgets);

    // 合同条目
    expect(find.text('议事决议数据服务合同'), findsOneWidget);
    expect(find.text('已签署'), findsWidgets);
  });
}
