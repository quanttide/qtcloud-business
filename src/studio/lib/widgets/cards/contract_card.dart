import 'package:flutter/material.dart';

import '../../models/contract.dart';
import '../common/status_badge.dart';

/// 合同卡片：名称 + 状态徽章 + 客户/模板/所属业务 + 金额 + 履约进度
class ContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback onTap;

  /// 所属业务名（可选）：订单挂靠哪个业务，交接时可追溯
  final String? businessName;

  const ContractCard({
    super.key,
    required this.contract,
    required this.onTap,
    this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = contract.fulfillments
        .where((f) => f.status == 'done')
        .length;
    final total = contract.fulfillments.length;
    final progress = total == 0 ? 0.0 : doneCount / total;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            contract.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          StatusBadge(status: contract.status),
                        ],
                      ),
                    ),
                    Text(
                      '${contract.amount.toStringAsFixed(1)} 万元',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${businessName == null ? '' : '业务：$businessName · '}'
                  '${contract.client} · ${contract.template}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: const Color(0xFF4F46E5),
                          backgroundColor: const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$doneCount/$total 履约',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
