import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import 'business.dart';
import 'contract.dart';
import 'quotation.dart';
import 'seed.dart';

/// 商务数据存储（v0.1 多人共享）：
/// 数据源为共享服务端（ApiClient），本机 localStorage 仅作离线缓存。
/// 服务端不可用时降级为本地缓存/seed 只读模式；有未同步改动时阻止刷新覆盖。
class BusinessStore {
  BusinessStore._();

  static final BusinessStore instance = BusinessStore._();

  static const String _prefsKey = 'biz_store_v1';
  static const String _prefsUnsyncedKey = 'biz_store_v1_unsynced';

  BusinessData? _data;
  bool loadFailed = false;

  /// 存在只落在本机、未同步到服务端的改动
  bool hasUnsyncedChanges = false;

  BusinessData get data =>
      _data ??
      BusinessData(businesses: [], quotations: [], contracts: [], templates: []);

  Future<BusinessData> load() async {
    if (_data != null) return _data!;
    // 1) 服务端为唯一数据源（多人共享）
    final remote = await ApiClient.instance.getState();
    if (remote != null) {
      _data = BusinessData.fromJson(remote);
      loadFailed = false;
      hasUnsyncedChanges = false;
      await _cacheLocal();
      return _data!;
    }
    // 2) 离线降级：本地有缓存用缓存（可继续查看），否则回退 seed
    String? raw;
    bool unsynced = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_prefsKey);
      unsynced = prefs.getBool(_prefsUnsyncedKey) ?? false;
    } catch (_) {}
    try {
      if (raw != null) {
        _data = BusinessData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        hasUnsyncedChanges = unsynced; // 与服务端状态以持久化标记为准
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

  /// 手动刷新：从服务端拉取最新数据覆盖本地。
  /// 有未同步的本机改动时拒绝覆盖（避免丢数据），返回 false。
  Future<bool> refresh() async {
    if (hasUnsyncedChanges) return false;
    final remote = await ApiClient.instance.getState();
    if (remote == null) return false;
    _data = BusinessData.fromJson(remote);
    loadFailed = false;
    await _cacheLocal();
    return true;
  }

  /// 同步结果写入本地缓存（失败不影响主流程）
  Future<void> _cacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(data.toJson()));
      await prefs.setBool(_prefsUnsyncedKey, hasUnsyncedChanges);
    } catch (_) {}
  }

  /// 新建业务（业务经营：定义业务）
  Future<void> addBusiness(Business business) async {
    data.businesses.add(business);
    final ok = await ApiClient.instance.saveEntity(
      'businesses',
      business.id,
      business.toJson(),
      create: true,
    );
    if (!ok) hasUnsyncedChanges = true;
    await _cacheLocal();
  }

  /// 新建报价（订单承接）：挂到所属业务名下
  Future<void> addQuotation(Quotation quotation) async {
    data.quotations.insert(0, quotation);
    final ok = await ApiClient.instance.saveEntity(
      'quotations',
      quotation.id,
      quotation.toJson(),
      create: true,
    );
    if (!ok) hasUnsyncedChanges = true;
    await _cacheLocal();
  }

  /// 登记合同：挂到所属业务名下
  Future<void> addContract(Contract contract) async {
    data.contracts.insert(0, contract);
    final ok = await ApiClient.instance.saveEntity(
      'contracts',
      contract.id,
      contract.toJson(),
      create: true,
    );
    if (!ok) hasUnsyncedChanges = true;
    await _cacheLocal();
  }

  /// 更新合同（付款到账打勾等）
  Future<void> updateContract(Contract contract) async {
    final i = data.contracts.indexWhere((c) => c.id == contract.id);
    if (i != -1) data.contracts[i] = contract;
    final ok = await ApiClient.instance.saveEntity(
      'contracts',
      contract.id,
      contract.toJson(),
    );
    if (!ok) hasUnsyncedChanges = true;
    await _cacheLocal();
  }

  Future<void> deleteBusiness(String id) async {
    data.businesses.removeWhere((b) => b.id == id);
    data.quotations.removeWhere((q) => q.businessId == id);
    data.contracts.removeWhere((c) => c.businessId == id);
    final ok = await ApiClient.instance.deleteEntity('businesses', id);
    if (!ok) hasUnsyncedChanges = true;
    await _cacheLocal();
  }

  Future<void> deleteQuotation(String id) async {
    data.quotations.removeWhere((q) => q.id == id);
    final ok = await ApiClient.instance.deleteEntity('quotations', id);
    if (!ok) hasUnsyncedChanges = true;
    await _cacheLocal();
  }

  Future<void> deleteContract(String id) async {
    data.contracts.removeWhere((c) => c.id == id);
    final ok = await ApiClient.instance.deleteEntity('contracts', id);
    if (!ok) hasUnsyncedChanges = true;
    await _cacheLocal();
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

  /// 按业务报价规则生成产品明细
  /// 工时公式：阶段基线工时 × 难度系数 × 量级系数；单价 = 人天单价
  static List<QuotationProduct> productsFromRule(
    PricingRule rule, {
    FactorLevel? difficulty,
    FactorLevel? scale,
  }) {
    final d = difficulty;
    final s = scale;
    return rule.stageDefaults.map((stage) {
      final hours = (d == null && s == null)
          ? stage.workload
          : rule.stageHours(stage, d ?? const FactorLevel(name: '', factor: 1.0),
              s ?? const FactorLevel(name: '', factor: 1.0));
      return QuotationProduct(
        name: hours == stage.workload
            ? '${stage.name}（${hours.toStringAsFixed(1)} 人天）'
            : '${stage.name}（基线 ${stage.workload.toStringAsFixed(1)} → ${hours.toStringAsFixed(1)} 人天）',
        unitPrice: rule.unitPrice,
        quantity: hours,
        discount: 1.0,
      );
    }).toList();
  }
}
