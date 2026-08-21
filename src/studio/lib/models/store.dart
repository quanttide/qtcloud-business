import 'business.dart';
import 'quotation.dart';
import 'seed.dart';

/// 会话内数据存储：一次加载 seed，之后所有新增都记录在内存
/// 服务端就绪后，这里的增删改改为调用接口
class BusinessStore {
  BusinessStore._();

  static final BusinessStore instance = BusinessStore._();

  BusinessData? _data;
  bool loadFailed = false;

  BusinessData get data =>
      _data ??
      BusinessData(businesses: [], quotations: [], contracts: [], templates: []);

  Future<BusinessData> load() async {
    if (_data != null) return _data!;
    try {
      _data = await loadSeedBusiness();
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

  /// 新建业务（业务经营：定义业务）
  void addBusiness(Business business) {
    data.businesses.add(business);
  }

  /// 新建报价（订单承接）：挂到所属业务名下
  void addQuotation(Quotation quotation) {
    data.quotations.insert(0, quotation);
  }

  String nextBusinessId() =>
      'biz-${DateTime.now().millisecondsSinceEpoch}';

  String nextQuotationId() {
    final n = data.quotations.length + 1;
    return 'q-2026-${n.toString().padLeft(3, '0')}-new';
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
