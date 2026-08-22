import 'package:flutter/material.dart';

import '../models/contract.dart';
import '../models/store.dart';
import '../widgets/cards/contract_card.dart';
import '../widgets/common/responsive.dart';
import '../widgets/common/sidebar.dart';
import 'contract_detail_screen.dart';

/// 合同列表：按状态筛选（待签署/已签署/已归档，US4）
/// contracts 传 null 时从会话存储加载
class ContractListScreen extends StatefulWidget {
  final List<Contract>? contracts;

  const ContractListScreen({super.key, this.contracts});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  String _filter = '全部';
  List<Contract>? _loaded;

  static const _filters = ['全部', '待签署', '已签署', '已归档'];

  List<Contract> get _items => widget.contracts ?? _loaded ?? const [];

  @override
  void initState() {
    super.initState();
    if (widget.contracts == null) {
      BusinessStore.instance.load().then((_) {
        if (!mounted) return;
        setState(() => _loaded = BusinessStore.instance.data.contracts);
      });
    }
  }

  List<Contract> get _filtered {
    if (_filter == '全部') return _items.toList();
    return _items.where((c) => c.status == _filter).toList();
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
              const Sidebar(route: '/contracts'),
              Expanded(child: _buildBody(context, compact: false)),
            ],
          ),
        ),
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
                '合同管理',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              // 状态筛选
              _buildFilterGroup(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '共 ${_filtered.length} 份合同',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      '暂无匹配的合同',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final contract = _filtered[index];
                      return ContractCard(
                        contract: contract,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContractDetailScreen(contract: contract),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ===== 筛选按钮组 =====
  Widget _buildFilterGroup() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _filters.map((label) {
          final isActive = _filter == label;
          return InkWell(
            onTap: () => setState(() => _filter = label),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
