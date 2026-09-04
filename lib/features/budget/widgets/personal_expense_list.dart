import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/personal_allowance_model.dart';
import '../../../core/providers/personal_allowance_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/feedback/app_feedback.dart';

/// Private personal expense list with swipe-to-delete, grouped by date,
/// category icons, and payment mode badges.
class PersonalExpenseList extends ConsumerWidget {
  final String tripId;
  final List<PersonalExpenseItem> expenses;

  const PersonalExpenseList({
    super.key,
    required this.tripId,
    required this.expenses,
  });

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.hotel:
        return Icons.hotel_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.activities:
        return Icons.attractions_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.custom:
        return Icons.shopping_bag_rounded;
    }
  }

  Color _getCategoryAccent(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.hotel:
        return const Color(0xFF8B5CF6);
      case ExpenseCategory.food:
        return AppColors.primary;
      case ExpenseCategory.activities:
        return const Color(0xFFEF9F27);
      case ExpenseCategory.transport:
        return const Color(0xFF3B82F6);
      case ExpenseCategory.custom:
        return const Color(0xFFF0997B);
    }
  }

  String _categoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.hotel:
        return 'Stay';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.activities:
        return 'Activity';
      case ExpenseCategory.transport:
        return 'Ride';
      case ExpenseCategory.custom:
        return 'Other';
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PersonalExpenseItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Expense?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
            children: [
              const TextSpan(text: 'Remove '),
              TextSpan(
                text: '"${item.description}"',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepEarth),
              ),
              TextSpan(
                text: ' (₱${CurrencyUtils.formatAmount(item.amount)}) from your personal expenses?',
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep',
              style: TextStyle( color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(personalAllowanceControllerProvider)
                    .deletePersonalExpense(
                      tripId: tripId,
                      expenseId: item.id,
                    );
                if (context.mounted) {
                  AppFeedback.showSuccess(context, 'Personal expense deleted');
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.showError(context, 'Failed to delete: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 15),
            label: const Text(
              'Delete',
              style: TextStyle( fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.sand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Personal Expenses Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Log your souvenirs, snacks, or solo Grab rides\nusing the form below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Group expenses by date for visual grouping
    final sortedExpenses = List<PersonalExpenseItem>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (int i = 0; i < sortedExpenses.length; i++) ...[
              _buildExpenseRow(context, ref, sortedExpenses[i]),
              if (i < sortedExpenses.length - 1)
                const Divider(height: 1, indent: 58, endIndent: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseRow(
      BuildContext context, WidgetRef ref, PersonalExpenseItem item) {
    final isCash = item.paymentMode == PaymentMode.cash;
    final accent = _getCategoryAccent(item.category);
    final dateStr = DateFormat('MMM d, h:mm a').format(item.date);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _confirmDelete(context, ref, item);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded,
                size: 18, color: Color(0xFFEF4444)),
            SizedBox(width: 4),
            Text(
              'Delete',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () => _confirmDelete(context, ref, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),

                // Description + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepEarth,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Category label
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _categoryLabel(item.category),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Payment mode badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCash
                                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                  : const Color(0xFF3B82F6).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCash
                                      ? Icons.payments_outlined
                                      : Icons.credit_card_rounded,
                                  size: 9,
                                  color: isCash
                                      ? const Color(0xFF047857)
                                      : const Color(0xFF1D4ED8),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isCash ? 'Cash' : 'Digital',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isCash
                                        ? const Color(0xFF047857)
                                        : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9CA3AF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '₱${CurrencyUtils.formatAmount(item.amount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
