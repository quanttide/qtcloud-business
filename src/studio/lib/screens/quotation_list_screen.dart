import 'package:flutter/material.dart';

import '../models/quotation.dart';
import '../models/store.dart';
import '../widgets/cards/quotation_card.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/sidebar.dart';
import 'quotation_detail_screen.dart';

/// 报价历史列表：支持按客户搜索（US2）
/// quotations 传 null 时从会话存储加载（含新建报价）
class QuotationListScreen extends StatefulWidget {
  final List<Quotation>? quotations;

  const QuotationListScreen({super.key, this.quotations});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  String _query = '';
  List<Quotation>? _loaded;

  List<Quotation> get _items => widget.quotations ?? _loaded ?? const [];

  @override
  void initState() {
    super.initState();
    if (widget.quotations == null) {
      BusinessStore.instance.load().then((_) {
        if (!mounted) return;
        setState(() => _loaded = BusinessStore.instance.data.quotations);
      });
    }
  }

  List<Quotation> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _items.toList();
    return _items.where((item) => item.client.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Responsive(
          mobile: _buildBody(context, compact: true),
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Sidebar(route: '/quotations'),
              Expanded(child: _buildBody(context, compact: false)),
            ],
          ),        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool compact}) {
    return Padding(
      padding: pageHPadding(context).add(const EdgeInsets.only(top: 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '报价历史',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              // 按客户搜索
              SizedBox(
                width: compact ? 200 : 280,
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: '按客户搜索',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '共 ${_filtered.length} 份报价',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      '暂无匹配的报价',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final quotation = _filtered[index];
                      return QuotationCard(
                        quotation: quotation,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                QuotationDetailScreen(quotation: quotation),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
