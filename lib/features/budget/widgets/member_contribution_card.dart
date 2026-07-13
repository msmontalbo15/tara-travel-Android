import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/member_model.dart';

class MemberContributionCard extends StatelessWidget {
  final List<MemberModel> members;
  final List<ExpenseModel> expenses;

  const MemberContributionCard({
    super.key,
    required this.members,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isLast = index == members.length - 1;
          final contributed = expenses
              .where((e) => e.status == ExpenseStatus.approved && e.paidById == member.id)
              .fold<double>(0, (sum, e) => sum + e.amount);
          final totalApproved = expenses
              .where((e) => e.status == ExpenseStatus.approved)
              .fold<double>(0, (sum, e) => sum + e.amount);
          final sharePct = totalApproved == 0 ? 0.0 : (contributed / totalApproved);
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: member.color, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          member.initials,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepEarth,
                            ),
                          ),
                          Text(
                            member.roles.map((r) => r.name).join(' · '),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${contributed.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Share bar
                        Container(
                          width: 80,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: sharePct.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: member.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, color: Color(0xFFE5E5EA), indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}
