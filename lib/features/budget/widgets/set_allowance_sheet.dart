import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../../../core/providers/personal_allowance_provider.dart';

/// Modal bottom sheet to set or adjust a traveler's personal allowance for the trip.
/// Features live preview of budget breakdown, quick presets, and emergency buffer selector.
class SetAllowanceSheet extends ConsumerStatefulWidget {
  final String tripId;
  final double currentAllowance;
  final double currentBufferPercent;
  final double currentCashOnHand;

  const SetAllowanceSheet({
    super.key,
    required this.tripId,
    this.currentAllowance = 0.0,
    this.currentBufferPercent = 0.10,
    this.currentCashOnHand = 0.0,
  });

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    double currentAllowance = 0.0,
    double currentBufferPercent = 0.10,
    double currentCashOnHand = 0.0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetAllowanceSheet(
        tripId: tripId,
        currentAllowance: currentAllowance,
        currentBufferPercent: currentBufferPercent,
        currentCashOnHand: currentCashOnHand,
      ),
    );
  }

  @override
  ConsumerState<SetAllowanceSheet> createState() => _SetAllowanceSheetState();
}

class _SetAllowanceSheetState extends ConsumerState<SetAllowanceSheet> {
  late TextEditingController _allowanceCtrl;
  late TextEditingController _cashCtrl;
  late double _bufferPercent;
  bool _isSaving = false;
  String? _error;

  static const _presets = [3000.0, 5000.0, 10000.0, 15000.0, 25000.0];

  @override
  void initState() {
    super.initState();
    _allowanceCtrl = TextEditingController(
      text: widget.currentAllowance > 0
          ? widget.currentAllowance.toStringAsFixed(0)
          : '',
    );
    _cashCtrl = TextEditingController(
      text: widget.currentCashOnHand > 0
          ? widget.currentCashOnHand.toStringAsFixed(0)
          : '',
    );
    _bufferPercent = widget.currentBufferPercent;

    _allowanceCtrl.addListener(_onInputChanged);
    _cashCtrl.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    // Trigger rebuild for live preview
    setState(() {});
  }

  @override
  void dispose() {
    _allowanceCtrl.removeListener(_onInputChanged);
    _cashCtrl.removeListener(_onInputChanged);
    _allowanceCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  double get _parsedAllowance =>
      double.tryParse(_allowanceCtrl.text.trim().replaceAll(',', '')) ?? 0.0;

  double get _parsedCash =>
      double.tryParse(_cashCtrl.text.trim().replaceAll(',', '')) ?? 0.0;

  Future<void> _save() async {
    final val = _parsedAllowance;
    if (val <= 0) {
      setState(() => _error = 'Please enter an allowance greater than ₱0');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(personalAllowanceControllerProvider)
          .setAllowance(
            tripId: widget.tripId,
            totalAllowance: val,
            emergencyBufferPercent: _bufferPercent,
            cashOnHand: _parsedCash,
          );

      if (mounted) {
        AppFeedback.showSuccess(context, 'Personal allowance saved!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Failed to save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowanceVal = _parsedAllowance;
    final bufferAmount = allowanceVal * _bufferPercent;
    final operationalBudget = allowanceVal - bufferAmount;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, context.keyboardBottomPadding(24)),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wallet_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Personal Allowance',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontHeading,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEarth,
                        ),
                      ),
                      Text(
                        'Your solo pocket money for this trip',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Presets
            const Text(
              'QUICK PRESETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected =
                    _allowanceCtrl.text == preset.toStringAsFixed(0);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _allowanceCtrl.text = preset.toStringAsFixed(0);
                      _error = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.sand,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFF0997B).withValues(alpha: 0.3),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '₱${CurrencyUtils.formatAmount(preset)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.deepEarth,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Allowance input
            const Text(
              'TOTAL PERSONAL ALLOWANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _allowanceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                hintText: '10,000',
                hintStyle: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Physical Cash on Hand (Optional)
            const Text(
              'INITIAL CASH ON HAND (OPTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cashCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.deepEarth,
              ),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                hintText: 'How much physical cash in your wallet?',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD1D5DB),
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Emergency Contingency Buffer Selection
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFDE68A).withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        size: 16, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Reserve',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Locked funds excluded from daily spending',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: DropdownButton<double>(
                      value: _bufferPercent,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                      items: const [
                        DropdownMenuItem(value: 0.0, child: Text('0%')),
                        DropdownMenuItem(value: 0.10, child: Text('10%')),
                        DropdownMenuItem(value: 0.15, child: Text('15%')),
                        DropdownMenuItem(value: 0.20, child: Text('20%')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _bufferPercent = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Live Preview Summary ─────────────────────────────────
            if (allowanceVal > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUDGET BREAKDOWN PREVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _previewRow(
                      'Total Allowance',
                      '₱${CurrencyUtils.formatAmount(allowanceVal)}',
                      const Color(0xFF6B7280),
                    ),
                    if (bufferAmount > 0) ...[
                      const SizedBox(height: 6),
                      _previewRow(
                        'Emergency Reserve (${(_bufferPercent * 100).toInt()}%)',
                        '-₱${CurrencyUtils.formatAmount(bufferAmount)}',
                        const Color(0xFFF59E0B),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _previewRow(
                      'Spendable Budget',
                      '₱${CurrencyUtils.formatAmount(operationalBudget)}',
                      const Color(0xFF10B981),
                      bold: true,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Save Personal Allowance',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
