import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'business.dart';
import 'contract.dart';
import 'quotation.dart';
import 'seed.dart';

/// 商务数据存储：首次加载 seed，之后所有新增/修改记录在本地（localStorage）
/// 刷新、重开浏览器数据不丢；服务端就绪后，持久层换成接口调用
class BusinessStore {
  BusinessStore._();

  static final BusinessStore instance = BusinessStore._();

  static const String _prefsKey = 'biz_store_v1';

  BusinessData? _data;
  bool loadFailed = false;

  BusinessData get data =>
      _data ??
      BusinessData(businesses: [], quotations: [], contracts: [], templates: []);

  Future<BusinessData> load() async {
    if (_data != null) return _data!;
    // 本地有存档则优先用（用户录入的数据）；读不到（含测试环境无平台通道）则回退 seed
    String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_prefsKey);
    } catch (_) {}
    try {
      if (raw != null) {
        _data = BusinessData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } else {
        _data = await loadSeedBusiness();
      }
      loadFailed = false;
    } catch (_) {
      loadFailed = true;
      _data = BusinessData(
        businesses: [],
        quotations: [],
        contracts: [],
        templates: [],
      );
    }
    return _data!;
  }

  /// 持久化到 localStorage（失败不影响主流程）
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(data.toJson()));
    } catch (_) {}
  }

  /// 新建业务（业务经营：定义业务）
  Future<void> addBusiness(Business business) async {
    data.businesses.add(business);
    await _persist();
  }

  /// 新建报价（订单承接）：挂到所属业务名下
  Future<void> addQuotation(Quotation quotation) async {
    data.quotations.insert(0, quotation);
    await _persist();
  }

  /// 登记合同：挂到所属业务名下
  Future<void> addContract(Contract contract) async {
    data.contracts.insert(0, contract);
    await _persist();
  }

  /// 更新合同（付款到账打勾等）
  Future<void> updateContract(Contract contract) async {
    final i = data.contracts.indexWhere((c) => c.id == contract.id);
    if (i != -1) data.contracts[i] = contract;
    await _persist();
  }

  String nextBusinessId() =>
      'biz-${DateTime.now().millisecondsSinceEpoch}';

  String nextQuotationId() {
    final n = data.quotations.length + 1;
    return 'q-2026-${n.toString().padLeft(3, '0')}-new';
  }

  String nextContractId() {
    final n = data.contracts.length + 1;
    return 'c-2026-${n.toString().padLeft(3, '0')}-new';
  }

  /// 从业务的付款节点模板解析节点（"签约 50%，交付验收后 50%" → 两个节点）
  /// 解析不出比例时该节点比例记 0，可手动改；模板为空则给单个全款节点
  static List<PaymentNode> paymentNodesFromTerms(String terms) {
    final nodes = <PaymentNode>[];
    for (final seg in terms.split(RegExp(r'[，,;；]'))) {
      final s = seg.trim();
      if (s.isEmpty) continue;
      final m = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(s);
      final ratio = m == null ? 0.0 : (double.parse(m.group(1)!) / 100);
      final name = m == null ? s : s.replaceFirst(m.group(0)!, '').trim();
      nodes.add(PaymentNode(name: name.isEmpty ? s : name, ratio: ratio));
    }
    if (nodes.isEmpty) nodes.add(const PaymentNode(name: '全款', ratio: 1.0));
    return nodes;
  }

  /// 按业务报价规则生成产品明细（成本法：阶段工时 × 人天单价）
  static List<QuotationProduct> productsFromRule(PricingRule rule) {
    return rule.stageDefaults
        .map(
          (s) => QuotationProduct(
            name: '${s.name}（${s.workload.toStringAsFixed(1)} 人天）',
            unitPrice: rule.unitPrice,
            quantity: s.workload,
            discount: 1.0,
          ),
        )
        .toList();
  }
}
