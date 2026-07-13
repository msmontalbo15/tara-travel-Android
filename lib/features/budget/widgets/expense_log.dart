import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/member_model.dart';
import 'package:intl/intl.dart';

class ExpenseLog extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final List<MemberModel> members;

  const ExpenseLog({
    super.key,
    required this.expenses,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips could go here
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expenses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final payer = members.where((m) => m.id == expense.paidById).firstOrNull;
            
            return _buildExpenseRow(
              expense,
              payer ??
                  const MemberModel(
                    id: 'unknown',
                    name: 'Unknown member',
                    initials: 'U',
                    color: AppColors.primary,
                  ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpenseRow(ExpenseModel expense, MemberModel payer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: _getCategoryColor(expense.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: payer.color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          payer.initials,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('MMM d').format(expense.date)} · ${expense.status.name.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: _getStatusColor(expense.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₱${expense.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.hotel: return Colors.blue;
      case ExpenseCategory.food: return Colors.amber;
      case ExpenseCategory.activities: return Colors.green;
      case ExpenseCategory.transport: return AppColors.primary;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.hotel: return Icons.hotel_rounded;
      case ExpenseCategory.food: return Icons.restaurant_rounded;
      case ExpenseCategory.activities: return Icons.local_activity_rounded;
      case ExpenseCategory.transport: return Icons.directions_bus_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.approved: return Colors.green;
      case ExpenseStatus.pending: return Colors.orange;
      case ExpenseStatus.rejected: return Colors.red;
    }
  }
}
