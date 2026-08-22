import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'business.dart';
import 'contract.dart';
import 'quotation.dart';
import 'seed.dart';

/// 鍟嗗姟鏁版嵁瀛樺偍锛氶娆″姞杞?seed锛屼箣鍚庢墍鏈夋柊澧?淇敼璁板綍鍦ㄦ湰鍦帮紙localStorage锛?/// 鍒锋柊銆侀噸寮€娴忚鍣ㄦ暟鎹笉涓紱鏈嶅姟绔氨缁悗锛屾寔涔呭眰鎹㈡垚鎺ュ彛璋冪敤
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
    // 鏈湴鏈夊瓨妗ｅ垯浼樺厛鐢紙鐢ㄦ埛褰曞叆鐨勬暟鎹級锛涜涓嶅埌锛堝惈娴嬭瘯鐜鏃犲钩鍙伴€氶亾锛夊垯鍥為€€ seed
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

  /// 鎸佷箙鍖栧埌 localStorage锛堝け璐ヤ笉褰卞搷涓绘祦绋嬶級
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(data.toJson()));
    } catch (_) {}
  }

  /// 鏂板缓涓氬姟锛堜笟鍔＄粡钀ワ細瀹氫箟涓氬姟锛?  Future<void> addBusiness(Business business) async {
    data.businesses.add(business);
    await _persist();
  }

  /// 鏂板缓鎶ヤ环锛堣鍗曟壙鎺ワ級锛氭寕鍒版墍灞炰笟鍔″悕涓?  Future<void> addQuotation(Quotation quotation) async {
    data.quotations.insert(0, quotation);
    await _persist();
  }

  /// 鐧昏鍚堝悓锛氭寕鍒版墍灞炰笟鍔″悕涓?  Future<void> addContract(Contract contract) async {
    data.contracts.insert(0, contract);
    await _persist();
  }

  /// 鏇存柊鍚堝悓锛堜粯娆惧埌璐︽墦鍕剧瓑锛?  Future<void> updateContract(Contract contract) async {
    final i = data.contracts.indexWhere((c) => c.id == contract.id);
    if (i != -1) data.contracts[i] = contract;
    await _persist();
  }


  Future<void> deleteBusiness(String id) async {
    data.businesses.removeWhere((b) => b.id == id);
    data.quotations.removeWhere((q) => q.businessId == id);
    data.contracts.removeWhere((c) => c.businessId == id);
    await _persist();
  }

  Future<void> deleteQuotation(String id) async {
    data.quotations.removeWhere((q) => q.id == id);
    await _persist();
  }

  Future<void> deleteContract(String id) async {
    data.contracts.removeWhere((c) => c.id == id);
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

  /// 浠庝笟鍔＄殑浠樻鑺傜偣妯℃澘瑙ｆ瀽鑺傜偣锛?绛剧害 50%锛屼氦浠橀獙鏀跺悗 50%" 鈫?涓や釜鑺傜偣锛?  /// 瑙ｆ瀽涓嶅嚭姣斾緥鏃惰鑺傜偣姣斾緥璁?0锛屽彲鎵嬪姩鏀癸紱妯℃澘涓虹┖鍒欑粰鍗曚釜鍏ㄦ鑺傜偣
  static List<PaymentNode> paymentNodesFromTerms(String terms) {
    final nodes = <PaymentNode>[];
    for (final seg in terms.split(RegExp(r'[锛?;锛沒'))) {
      final s = seg.trim();
      if (s.isEmpty) continue;
      final m = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(s);
      final ratio = m == null ? 0.0 : (double.parse(m.group(1)!) / 100);
      final name = m == null ? s : s.replaceFirst(m.group(0)!, '').trim();
      nodes.add(PaymentNode(name: name.isEmpty ? s : name, ratio: ratio));
    }
    if (nodes.isEmpty) nodes.add(const PaymentNode(name: '鍏ㄦ', ratio: 1.0));
    return nodes;
  }

  /// 鎸変笟鍔℃姤浠疯鍒欑敓鎴愪骇鍝佹槑缁嗭紙鎴愭湰娉曪細闃舵宸ユ椂 脳 浜哄ぉ鍗曚环锛?  static List<QuotationProduct> productsFromRule(PricingRule rule) {
    return rule.stageDefaults
        .map(
          (s) => QuotationProduct(
            name: '${s.name}锛?{s.workload.toStringAsFixed(1)} 浜哄ぉ锛?,
            unitPrice: rule.unitPrice,
            quantity: s.workload,
            discount: 1.0,
          ),
        )
        .toList();
  }
}
