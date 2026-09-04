import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/utils/currency_utils.dart';

/// Transactional expense log with status filters (All, Pending, Approved, Rejected),
/// role-aware approval/rejection actions, receipt modal previews, and settlement debt nudges.
class ExpenseLog extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final List<MemberModel> members;
  final String? currentUserId;
  final bool canApprove;
  final void Function(ExpenseModel expense, ExpenseStatus status, {String? rejectionNote})? onStatusUpdate;
  final void Function(ExpenseModel expense)? onDelete;

  const ExpenseLog({
    super.key,
    required this.expenses,
    required this.members,
    this.currentUserId,
    this.canApprove = true,
    this.onStatusUpdate,
    this.onDelete,
  });

  @override
  State<ExpenseLog> createState() => _ExpenseLogState();
}

class _ExpenseLogState extends State<ExpenseLog> {
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: Approved, 3: Rejected

  List<ExpenseModel> get _filteredExpenses {
    switch (_selectedFilter) {
      case 1:
        return widget.expenses.where((e) => e.status == ExpenseStatus.pending).toList();
      case 2:
        return widget.expenses.where((e) => e.status == ExpenseStatus.approved).toList();
      case 3:
        return widget.expenses.where((e) => e.status == ExpenseStatus.rejected).toList();
      default:
        return widget.expenses;
    }
  }

  void _showReceiptModal(BuildContext context, ExpenseModel expense) {
    if (expense.receiptPhotoUrl == null || expense.receiptPhotoUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      expense.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: expense.receiptPhotoUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₱${CurrencyUtils.formatAmount(expense.amount)} · ${DateFormat('MMMM d, yyyy').format(expense.date)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _promptReject(BuildContext context, ExpenseModel expense) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Expense',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.deepEarth,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejecting "₱${CurrencyUtils.formatAmount(expense.amount)} for ${expense.description}". This will not count towards the trip budget.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: 'Optional reason (e.g. personal expense)',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onStatusUpdate?.call(
                expense,
                ExpenseStatus.rejected,
                rejectionNote: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.expenses.where((e) => e.status == ExpenseStatus.pending).length;
    final filtered = _filteredExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Debt / Unsettled Nudge Banner ────────────────────────────
        if (pendingCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pendingCount pending expense${pendingCount == 1 ? '' : 's'} awaiting approval before affecting the budget.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Status Filter Tabs ─────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(0, 'All (${widget.expenses.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(1, 'Pending ($pendingCount)'),
              const SizedBox(width: 8),
              _buildFilterChip(2, 'Approved (${widget.expenses.where((e) => e.status == ExpenseStatus.approved).length})'),
              const SizedBox(width: 8),
              _buildFilterChip(3, 'Rejected (${widget.expenses.where((e) => e.status == ExpenseStatus.rejected).length})'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Expense Rows ───────────────────────────────────────────
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.dividerLight),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  _selectedFilter == 0 ? 'No expenses logged yet.' : 'No expenses in this filter.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warmMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final expense = filtered[index];
              final payer = widget.members.where((m) => m.id == expense.paidById).firstOrNull ??
                  const MemberModel(
                    id: 'unknown',
                    name: 'Traveler',
                    initials: 'TR',
                    color: AppColors.primary,
                  );
              return _buildExpenseCard(context, expense, payer);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final active = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.deepEarth : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.deepEarth : const Color(0xFFE5E7EB),
          ),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, ExpenseModel expense, MemberModel payer) {
    final hasReceipt = expense.receiptPhotoUrl != null && expense.receiptPhotoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expense.isPending
              ? AppColors.amber.withValues(alpha: 0.3)
              : (expense.isRejected ? Colors.red.withValues(alpha: 0.2) : AppColors.dividerLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: expense.categoryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  expense.categoryIcon,
                  color: expense.categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Payer Initials Dot
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: payer.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              payer.initials,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          payer.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${DateFormat('MMM d').format(expense.date)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (hasReceipt) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _showReceiptModal(context, expense),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.attachment_rounded, size: 10, color: AppColors.primary),
                                  Text(
                                    ' Receipt',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Amount & Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${CurrencyUtils.formatAmount(expense.amount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepEarth,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildStatusBadge(expense.status),
                ],
              ),
            ],
          ),

          // Approval Action Bar (for Pending expenses)
          if (expense.isPending && widget.canApprove) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFF3F4F6), height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _promptReject(context, expense),
                  icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Reject',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => widget.onStatusUpdate?.call(expense, ExpenseStatus.approved),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text(
                    'Approve',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],

          // Rejection note display if present
          if (expense.isRejected && expense.rejectionNote != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ${expense.rejectionNote}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ExpenseStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case ExpenseStatus.approved:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        text = 'APPROVED';
        break;
      case ExpenseStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        text = 'PENDING';
        break;
      case ExpenseStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        text = 'REJECTED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
