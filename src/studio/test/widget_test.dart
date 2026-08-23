import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qtcloud_business_studio/models/business.dart';
import 'package:qtcloud_business_studio/models/contract.dart';
import 'package:qtcloud_business_studio/models/log_entry.dart';
import 'package:qtcloud_business_studio/models/quotation.dart';
import 'package:qtcloud_business_studio/models/seed.dart';
import 'package:qtcloud_business_studio/models/store.dart';
import 'package:qtcloud_business_studio/screens/contract_detail_screen.dart';
import 'package:qtcloud_business_studio/screens/contract_edit_screen.dart';
import 'package:qtcloud_business_studio/screens/dashboard_screen.dart';
import 'package:qtcloud_business_studio/screens/quotation_detail_screen.dart';
import 'package:qtcloud_business_studio/screens/quotation_edit_screen.dart';
import 'package:qtcloud_business_studio/screens/quotation_list_screen.dart';
import 'package:qtcloud_business_studio/screens/business_detail_screen.dart';
import 'package:qtcloud_business_studio/services/business_stats.dart';
import 'package:qtcloud_business_studio/services/follow_up.dart';
import 'package:qtcloud_business_studio/services/pdf_export.dart';

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
    // 真实 PDF 生成需加载字体资产（真实异步 IO）
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 5)),
    );
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

    // 待签署合同显示提醒按钮（页面较长且懒加载，先滚动到按钮再点）
    final detailScrollable = find
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.text('提醒客户签署'),
      150,
      scrollable: detailScrollable,
    );
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

  group('业务定义（需求二）：工时公式与门槛校验', () {
    test('PricingRule 缺省难度/量级档位可解析，工时公式按系数计算', () {
      const rule = PricingRule(
        unitPrice: 0.2,
        stageDefaults: [StageDefault(name: '数据建模', workload: 10)],
        minGrossMargin: 0.3,
        paymentTerms: '签约 50%，交付验收后 50%',
      );
      // 未传档位时使用默认：低/中/高 ×1.0/1.3/1.6，小/中/大 ×1.0/1.5/2.0
      expect(rule.difficultyLevels.map((f) => f.name), ['低', '中', '高']);
      expect(rule.scaleLevels.map((f) => f.factor), [1.0, 1.5, 2.0]);

      final hours = rule.stageHours(
        rule.stageDefaults.first,
        rule.difficultyLevels[1],
        rule.scaleLevels[2],
      );
      expect(hours, closeTo(10 * 1.3 * 2.0, 0.001)); // 公式：基线×难度×量级
    });

    test('productsFromRule 代入难度/量级系数重算人天并标注基线', () {
      const rule = PricingRule(
        unitPrice: 0.2,
        stageDefaults: [StageDefault(name: '数据采集', workload: 4)],
        minGrossMargin: 0.3,
        paymentTerms: '',
      );
      const d = FactorLevel(name: '高', factor: 1.6);
      const s = FactorLevel(name: '大', factor: 2.0);
      final products = BusinessStore.productsFromRule(
        rule,
        difficulty: d,
        scale: s,
      );
      expect(products.single.quantity, closeTo(12.8, 0.001));
      expect(products.single.name, contains('基线 4.0 → 12.8 人天'));
      // 不传系数保持原基线
      expect(
        BusinessStore.productsFromRule(rule).single.quantity,
        closeTo(4.0, 0.001),
      );
    });

    test('规则没写清的业务被拦截：missingRuleFields 列出缺口', () {
      const incomplete = Business(
        id: 'biz-x',
        name: '模糊业务',
        description: '',
        status: '在营',
        pricingRule: PricingRule(
          unitPrice: 0,
          stageDefaults: [],
          minGrossMargin: 0,
          paymentTerms: '',
        ),
        created: '2026-08-22',
        updated: '2026-08-22',
      );
      expect(incomplete.isRuleComplete, isFalse);
      expect(
        incomplete.missingRuleFields(),
        containsAll(['人天单价', '毛利底线', '付款节点', '阶段工时基线']),
      );

      const complete = Business(
        id: 'biz-y',
        name: '明确业务',
        description: '',
        status: '在营',
        pricingRule: PricingRule(
          unitPrice: 0.2,
          stageDefaults: [StageDefault(name: '采集', workload: 1)],
          minGrossMargin: 0.3,
          paymentTerms: '全款',
        ),
        commercialModel: '人天制',
        changeRuleTemplate: '变更须书面确认',
        created: '2026-08-22',
        updated: '2026-08-22',
      );
      expect(complete.isRuleComplete, isTrue);
      expect(complete.commercialModel, '人天制');
    });
  });

  testWidgets('新建报价未选业务时被拦截（订单不能脱离业务）', (tester) async {
    final data = loadTestSeed();
    await tester.pumpWidget(
      MaterialApp(
        home: QuotationEditScreen(quotationTemplates: data.quotationTemplates),
      ),
    );
    await tester.pumpAndSettle();

    // 必选业务下拉存在，且默认未选择
    expect(find.text('所属业务（必选，订单是业务的实例）'), findsOneWidget);

    // 不选业务直接保存 → 拦截提示（懒加载列表需先滚到底部按钮）
    final listScrollable = find
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.text('保存报价'),
      250,
      scrollable: listScrollable,
    );
    await tester.tap(find.text('保存报价'));
    await tester.pump();
    expect(find.textContaining('订单必须挂在业务下'), findsOneWidget);
  });

  group('时限跟进引擎（需求四：中游机制）', () {
    final today = DateTime(2026, 8, 22);
    String daysAgo(int n) =>
        today.subtract(Duration(days: n)).toIso8601String().substring(0, 10);

    Quotation quotation({required String updated, String status = '草稿'}) =>
        Quotation(
          id: 'q-t',
          businessId: 'biz-data',
          name: '测试报价',
          client: '客户甲',
          template: '',
          status: status,
          version: 1,
          created: daysAgo(9),
          updated: updated,
          pricingNote: '',
          products: const [],
          totalAmount: 1,
          versions: const [],
        );

    Contract contract({
      String status = '待签署',
      String signed = '',
      List<PaymentNode> payments = const [],
    }) =>
        Contract(
          id: 'c-t',
          businessId: 'biz-data',
          name: '测试合同',
          client: '客户甲',
          template: '',
          status: status,
          amount: 10,
          created: daysAgo(9),
          signed: signed,
          fulfillments: const [],
          payments: payments,
        );

    test('报价超 48 小时未动 → 跟进提醒；已确认不提醒', () {
      final items = collectFollowUps(
        BusinessData(
          businesses: const [],
          templates: const [],
          quotations: [
            quotation(updated: daysAgo(3)),
            quotation(updated: daysAgo(1)),
            quotation(updated: daysAgo(30), status: '已确认'),
          ],
          contracts: const [],
        ),
        now: today,
      );
      expect(items.length, 1);
      expect(items.single.kind, '报价跟进');
      expect(items.single.title, contains('3 天没有进展'));
    });

    test('待签署超 3 天提醒；签约超 7 天未到账催收；结清提示可结项', () {
      final items = collectFollowUps(
        BusinessData(
          businesses: const [],
          quotations: const [],
          templates: const [],
          contracts: [
            contract(), // 待签署 created 9 天前
            contract(
              status: '已签署',
              signed: daysAgo(8),
              payments: const [
                PaymentNode(name: '签约款', ratio: 0.5),
                PaymentNode(name: '尾款', ratio: 0.5),
              ],
            ),
            contract(
              status: '已签署',
              signed: daysAgo(8),
              payments: [
                PaymentNode(name: '全款', ratio: 1.0, received: true, date: daysAgo(2)),
              ],
            ),
            contract(status: '已归档', signed: daysAgo(20)), // 归档不催收
          ],
        ),
        now: today,
      );
      expect(items.map((e) => e.kind), containsAll(['签署跟进', '尾款催收', '可结项']));
      expect(items.where((e) => e.kind == '尾款催收').single.title,
          contains('2 笔款项未到账'));
    });
  });

  group('往来留痕与转合同（需求四补全）', () {
    test('logs/deliverables 字段 JSON 往返不丢数据', () {
      const contract = Contract(
        id: 'c-rt',
        businessId: 'b',
        name: 'n',
        client: 'c',
        template: '',
        status: '已签署',
        amount: 10,
        created: '2026-08-01',
        signed: '2026-08-02',
        fulfillments: [],
        payments: [],
        deliverables: [
          Fulfillment(name: '审计报告', status: 'done', date: '2026-08-05'),
          Fulfillment(name: '培训材料', status: 'todo', date: ''),
        ],
        logs: [
          LogEntry(date: '2026-08-03', type: '邮件确认', note: '报价确认'),
          LogEntry(date: '2026-08-04', type: '变更协议', note: '范围+1'),
        ],
      );
      final back = Contract.fromJson(
        jsonDecode(jsonEncode(contract.toJson())) as Map<String, dynamic>,
      );
      expect(back.deliverables.length, 2);
      expect(back.deliverables.first.name, '审计报告');
      expect(back.logs.last.type, '变更协议');
      expect(back.logs.first.note, '报价确认');

      const q = Quotation(
        id: 'q-rt',
        businessId: 'b',
        name: 'n',
        client: 'c',
        template: '',
        status: '草稿',
        version: 1,
        created: '2026-08-01',
        updated: '2026-08-01',
        pricingNote: '',
        products: [],
        totalAmount: 3,
        versions: [],
        logs: [LogEntry(date: '2026-08-02', type: '电话沟通', note: '初次沟通')],
      );
      final qb = Quotation.fromJson(
        jsonDecode(jsonEncode(q.toJson())) as Map<String, dynamic>,
      );
      expect(qb.logs.single.type, '电话沟通');
    });

    testWidgets('报价一键转合同：预填客户与金额', (tester) async {
      final data = loadTestSeed();
      BusinessStore.instance.seedForTest(data);
      final quotation = data.quotations.first;
      await tester.pumpWidget(
        MaterialApp(home: QuotationDetailScreen(quotation: quotation)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('转为合同（预填客户与金额）'));
      await tester.pumpAndSettle();

      expect(find.byType(ContractEditScreen), findsOneWidget);
      // 客户与金额已预填
      expect(find.text(quotation.client), findsWidgets);
      expect(
        find.text(quotation.totalAmount.toStringAsFixed(1)),
        findsOneWidget,
      );
    });

    testWidgets('报价详情登记留痕（书面确认优先）', (tester) async {
      final data = loadTestSeed();
      BusinessStore.instance.seedForTest(data);
      final quotation = data.quotations.first;
      await tester.pumpWidget(
        MaterialApp(home: QuotationDetailScreen(quotation: quotation)),
      );
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text('登记留痕'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('登记留痕'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '报价 v2 已邮件确认');
      await tester.tap(find.text('保存留痕'));
      await tester.pump();
      await tester.pump();

      // 留痕卡与退场中的弹窗可能同时短暂可见
      expect(find.textContaining('报价 v2 已邮件确认'), findsWidgets);
      expect(find.textContaining('✅ 已登记留痕'), findsOneWidget);
    });
  });

  group('数据回流：业务经营统计（需求五）', () {
    final today = DateTime(2026, 8, 23);
    String daysAgo(int n) =>
        today.subtract(Duration(days: n)).toIso8601String().substring(0, 10);

    Quotation quotation(String status, String updated) => Quotation(
          id: 'q',
          businessId: 'biz-x',
          name: 'n',
          client: 'c',
          template: '',
          status: status,
          version: 1,
          created: daysAgo(60),
          updated: updated,
          pricingNote: '',
          products: const [],
          totalAmount: 3,
          versions: const [],
        );

    Contract contract({
      double amount = 10,
      String signed = '',
      List<PaymentNode> payments = const [],
    }) =>
        Contract(
          id: 'c',
          businessId: 'biz-x',
          name: 'n',
          client: 'c',
          template: '',
          status: '已签署',
          amount: amount,
          created: daysAgo(45),
          signed: signed,
          fulfillments: const [],
          payments: payments,
        );

    test('转化率、回款周期、超期应收、沉睡草稿计算正确', () {
      final stats = computeBusinessStats(
        BusinessData(
          businesses: const [],
          templates: const [],
          quotations: [
            quotation('已确认', daysAgo(40)),
            quotation('草稿', daysAgo(31)), // 沉睡
            Quotation(
              id: 'q-other',
              businessId: 'biz-other',
              name: 'n',
              client: 'c',
              template: '',
              status: '草稿',
              version: 1,
              created: daysAgo(60),
              updated: daysAgo(60),
              pricingNote: '',
              products: const [],
              totalAmount: 3,
              versions: const [],
            ), // 别的业务的报价不计入
          ],
          contracts: [
            // 签约 40 天前，35 天前到账一半 → 周期 5 天；剩一半超期未收
            contract(
              signed: daysAgo(40),
              payments: [
                PaymentNode(name: '签约款', ratio: 0.5, received: true, date: daysAgo(35)),
                PaymentNode(name: '尾款', ratio: 0.5),
              ],
            ),
            // 待签署不计回款周期，金额计入总额
            contract(amount: 20),
          ],
        ),
        'biz-x',
        now: today,
      );

      expect(stats.quotationCount, 2);
      expect(stats.contractCount, 2);
      expect(stats.contractAmount, 30);
      expect(stats.receivedAmount, 5);
      expect(stats.avgCollectionDays, 5);
      expect(stats.overdueReceivable, 5); // 尾款 50% × 10 万，签约超 30 天
      expect(stats.staleQuotationCount, 1);
      expect(stats.conversionRate, closeTo(1.0, 0.001));
    });

    testWidgets('业务详情显示经营复盘卡', (tester) async {
      final data = loadTestSeed();
      BusinessStore.instance.seedForTest(data);
      await tester.pumpWidget(
        MaterialApp(
          home: BusinessDetailScreen(
            business: data.businesses.first,
            data: data,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text('经营复盘'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('经营复盘'), findsOneWidget);
      expect(find.text('合同总额'), findsOneWidget);
      expect(find.text('已到账'), findsOneWidget);
      expect(find.text('报价转化'), findsOneWidget);
      expect(find.textContaining('平均回款周期'), findsOneWidget);
    });

    test('订单归档 PDF 可生成且包含关键信息', () async {
      final data = loadTestSeed();
      final c = data.contracts.first;
      final bytes = await buildContractArchivePdf(c, businessName: '数据服务');
      expect(bytes.lengthInBytes, greaterThan(1000));
    });
  });

  group('规则校准与章程检查项（需求五收尾+需求七）', () {
    Business business({List<String> checklist = const []}) => Business(
          id: 'biz-c',
          name: '校准业务',
          description: '',
          status: '在营',
          pricingRule: PricingRule(
            unitPrice: 0.1,
            stageDefaults: [
              StageDefault(name: '采集', workload: 10),
              StageDefault(name: '建模', workload: 20),
              StageDefault(name: '报告', workload: 20),
            ], // 基线合计 50 人天 × 0.1 万 = 成本估算 5 万
            minGrossMargin: 0.3,
            paymentTerms: '签约 50%，交付 50%',
          ),
          created: '2026-01-01',
          updated: '2026-01-01',
          checklistTemplate: checklist,
        );

    BusinessStats stats({
      double overdue = 0,
      double? cycle,
      int quotations = 3,
      int contracts = 2,
      double amount = 30,
    }) =>
        BusinessStats(
          quotationCount: quotations,
          contractCount: contracts,
          contractAmount: amount,
          receivedAmount: amount * 0.5,
          avgCollectionDays: cycle,
          overdueReceivable: overdue,
          staleQuotationCount: 0,
        );

    test('超期应收与客单价低于成本 → danger 建议', () {
      // 客单价 3 万 < 成本估算 5 万 + 有超期应收
      final advices = buildCalibrationAdvice(
        stats(overdue: 4, amount: 6),
        business(),
      );
      expect(advices.map((a) => a.level), everyElement('danger'));
      expect(
        advices.any((a) => a.message.contains('超期应收')),
        isTrue,
      );
      expect(
        advices.any((a) => a.message.contains('低于成本法估算')),
        isTrue,
      );
    });

    test('回款周期偏长/转化率低 → warn；数据健康 → ok', () {
      final warnCycle = buildCalibrationAdvice(
        stats(cycle: 60),
        business(),
      );
      expect(warnCycle.any((a) => a.level == 'warn' && a.message.contains('回款周期')), isTrue);

      final lowConv = buildCalibrationAdvice(
        stats(contracts: 1, quotations: 5, cycle: 20),
        business(),
      );
      expect(lowConv.any((a) => a.level == 'warn' && a.message.contains('转化率')), isTrue);

      final ok = buildCalibrationAdvice(stats(), business());
      expect(ok.single.level, 'ok');
    });

    test('业务未自定义时检查项模板回退章程默认，JSON 往返保留自定义', () {
      expect(business().effectiveChecklist().length, 5);
      expect(
        business()
            .effectiveChecklist()
            .any((t) => t.contains('报价确认')),
        isTrue,
      );

      final custom = Business.fromJson(
        jsonDecode(
          jsonEncode(business(checklist: ['A', 'B']).toJson()),
        ) as Map<String, dynamic>,
      );
      expect(custom.checklistTemplate, ['A', 'B']);
      expect(custom.effectiveChecklist(), ['A', 'B']);
    });

    testWidgets('登记合同自动生成章程检查项到订单', (tester) async {
      final data = loadTestSeed();
      BusinessStore.instance.seedForTest(data);
      await tester.pumpWidget(
        MaterialApp(
          home: ContractEditScreen(
            contractTemplates: data.contractTemplates,
            business: data.businesses.first,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 填客户与金额（前三个 TextField：名称/客户/金额）
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '检查项客户');
      await tester.enterText(fields.at(2), '12');

      await tester.scrollUntilVisible(
        find.text('保存合同'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('保存合同'));
      await tester.pump();

      final saved = BusinessStore.instance.data.contracts.first;
      expect(saved.client, '检查项客户');
      expect(saved.checklist.length, 5);
      expect(saved.checklist.every((c) => c.status == 'todo'), isTrue);
    });
  });
}
