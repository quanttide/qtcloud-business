import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_business_studio/models/contract.dart';
import 'package:qtcloud_business_studio/models/seed.dart';
import 'package:qtcloud_business_studio/screens/contract_detail_screen.dart';
import 'package:qtcloud_business_studio/screens/dashboard_screen.dart';
import 'package:qtcloud_business_studio/screens/quotation_detail_screen.dart';
import 'package:qtcloud_business_studio/screens/quotation_list_screen.dart';

/// 从仓库 seed JSON 同步构造测试用 BusinessData。
///
/// widget 测试运行在包根目录（src/studio/），可直接读文件系统；
/// 不走 rootBundle 以避免测试环境下的异步 IO future 悬挂。
BusinessData loadTestSeed() {
  final raw = File('assets/data/seed_business.json').readAsStringSync();
  return BusinessData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

void main() {
  testWidgets('仪表盘加载 seed 并渲染报价与合同', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    // 初始加载态
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 真实异步 IO：等待 rootBundle 加载 seed JSON
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('商务工作台'), findsOneWidget);

    // 统计卡片
    expect(find.text('报价总数'), findsOneWidget);
    expect(find.text('待签署'), findsWidgets); // 统计卡片 + 合同状态徽章
    expect(find.text('已签署'), findsWidgets);

    // 业务区块（业务是类，订单是实例）
    expect(find.text('业务（3）'), findsOneWidget);
    expect(find.text('数据服务（在营）'), findsOneWidget);

    // 报价与合同区块在业务卡片下方，逐段滚动断言
    final listScrollable = find
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.text('议事决议数据需求点'),
      250,
      scrollable: listScrollable,
    );
    expect(find.text('报价（2）'), findsOneWidget);
    expect(find.text('议事决议数据需求点'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('议事决议数据服务合同'),
      250,
      scrollable: listScrollable,
    );
    expect(find.text('合同（2）'), findsOneWidget);
    expect(find.text('议事决议数据服务合同'), findsOneWidget);
  });

  testWidgets('报价详情：产品明细、版本历史与导出（US1/US2）', (tester) async {
    final data = loadTestSeed();
    final quotation = data.quotations.first; // q-2026-001 v3 已确认
    await tester.pumpWidget(
      MaterialApp(home: QuotationDetailScreen(quotation: quotation)),
    );
    await tester.pumpAndSettle();

    // 版本历史：当前版本 v3 + 历史版本
    expect(find.text('版本历史'), findsOneWidget);
    expect(find.text('当前'), findsOneWidget);
    expect(find.text('v1'), findsOneWidget);
    expect(find.text('初版报价'), findsOneWidget);

    // 导出 PDF → 弹窗 → 下载提示
    await tester.tap(find.text('导出'));
    await tester.pumpAndSettle();
    expect(find.text('导出报价单'), findsOneWidget);
    expect(find.textContaining('.pdf'), findsOneWidget);

    await tester.tap(find.text('下载'));
    await tester.pumpAndSettle();
    expect(find.textContaining('📥 下载'), findsOneWidget);
  });

  testWidgets('报价历史：按客户搜索（US2）', (tester) async {
    final data = loadTestSeed();
    await tester.pumpWidget(
      MaterialApp(home: QuotationListScreen(quotations: data.quotations)),
    );
    await tester.pumpAndSettle();

    expect(find.text('共 2 份报价'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '示例客户');
    await tester.pump();

    expect(find.text('共 1 份报价'), findsOneWidget);
    expect(find.text('数据治理基线服务（示例）'), findsOneWidget);
    expect(find.text('议事决议数据需求点'), findsNothing);
  });

  testWidgets('合同详情：签署进度与签署提醒（US4）', (tester) async {
    final data = loadTestSeed();
    final contract = data.contracts.last; // c-2026-002 待签署
    await tester.pumpWidget(
      MaterialApp(home: ContractDetailScreen(contract: contract)),
    );
    await tester.pumpAndSettle();

    // 签署进度步骤（发送签署 done / 客户签署 active / 合同归档 todo）
    expect(find.text('签署进度'), findsOneWidget);
    expect(find.text('发送签署'), findsOneWidget);
    expect(find.text('客户签署'), findsOneWidget);
    expect(find.text('合同归档'), findsOneWidget);

    // 待签署合同显示提醒按钮（页面较长，先滚动到按钮再点）
    await tester.ensureVisible(find.text('提醒客户签署'));
    await tester.pumpAndSettle();
    expect(find.text('提醒客户签署'), findsOneWidget);
    await tester.tap(find.text('提醒客户签署'));
    await tester.pump();
    expect(find.textContaining('🔔 已发送签署提醒'), findsOneWidget);
  });

  testWidgets('合同详情：付款到账打勾记录日期', (tester) async {
    const contract = Contract(
      id: 'c-test',
      businessId: 'biz-data',
      name: '测试合同',
      client: '测试客户',
      template: '',
      status: '已签署',
      amount: 10,
      created: '2026-08-21',
      signed: '2026-08-21',
      fulfillments: [],
      payments: [
        PaymentNode(name: '签约款', ratio: 0.5),
        PaymentNode(name: '尾款', ratio: 0.5),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: ContractDetailScreen(contract: contract)),
    );
    await tester.pumpAndSettle();

    // 初始：0 笔到账
    expect(find.text('已到账 0.00 万元 / 共 10.0 万元'), findsOneWidget);
    expect(find.text('签约款'), findsOneWidget);
    expect(find.text('未到账'), findsWidgets);

    // 勾选第一笔：到账金额更新、日期自动记录
    await tester.tap(find.text('签约款'));
    await tester.pumpAndSettle();
    expect(find.text('已到账 5.00 万元 / 共 10.0 万元'), findsOneWidget);
    expect(find.text('1/2 笔'), findsOneWidget);
    expect(find.textContaining('2026-'), findsWidgets);
  });
}
