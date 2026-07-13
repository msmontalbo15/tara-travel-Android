import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/inputs/app_numeric_field.dart';
import '../models/new_trip_model.dart';
import '../widgets/step_indicator.dart';

class BudgetStep extends StatefulWidget {
  final NewTripModel trip;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BudgetStep({
    super.key,
    required this.trip,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends State<BudgetStep> {
  late TextEditingController _budgetCtrl;
  String? _budgetError;

  @override
  void initState() {
    super.initState();
    final initial = widget.trip.totalBudget?.toStringAsFixed(2) ?? '';
    _budgetCtrl = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }

  void _onContinue() {
    final val = double.tryParse(_budgetCtrl.text) ?? 0;
    if (val <= 0) {
      setState(() => _budgetError = 'Please enter a budget greater than ₱0');
      return;
    }
    widget.trip.totalBudget = val;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'New trip',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Step indicator ──────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: StepIndicator(
                currentStep: 2,
                totalSteps: 3,
                label: 'Budget setup',
              ),
            ),
            const SizedBox(height: 28),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total trip budget — using AppNumericField
                    AppNumericField(
                      label: 'Total trip budget',
                      controller: _budgetCtrl,
                      hint: '0.00',
                      errorText: _budgetError,
                      decimal: false,
                      semanticsLabel: 'Total budget input',
                      onChanged: (v) {
                        if (_budgetError != null) {
                          setState(() => _budgetError = null);
                        }
                        final val = double.tryParse(v) ?? 0;
                        widget.trip.totalBudget = val;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Currency picker
                    const Text(
                      'Currency',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Currency',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: const Text('Philippine Peso (₱)'),
                                  trailing: const Icon(Icons.check_rounded, color: Color(0xFFD85A30)),
                                  onTap: () {
                                    setState(() => widget.trip.currency = 'Philippine Peso (₱)');
                                    Navigator.pop(ctx);
                                  },
                                ),
                                ListTile(
                                  title: const Text('US Dollar (\$)'),
                                  onTap: () {
                                    setState(() => widget.trip.currency = 'US Dollar (\$)');
                                    Navigator.pop(ctx);
                                  },
                                ),
                                ListTile(
                                  title: const Text('Euro (€)'),
                                  onTap: () {
                                    setState(() => widget.trip.currency = 'Euro (€)');
                                    Navigator.pop(ctx);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border:
                              Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.trip.currency,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Icon(Icons.check_rounded,
                                color: Color(0xFFD85A30), size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Split equally toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Split equally among travelers',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Switch(
                          value: widget.trip.splitEqually,
                          onChanged: (v) =>
                              setState(() => widget.trip.splitEqually = v),
                          activeThumbColor: const Color(0xFFD85A30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Budget breakdown
                    const Text(
                      'Budget breakdown (optional)',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.trip.budgetBreakdown.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(cat.color),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            Text(
                              '₱${_formatAmount(cat.amount)}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.trip.budgetBreakdown.add(
                            BudgetCategory(name: 'Transportation', amount: 0, color: 0xFF3B82F6),
                          );
                        });
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              color: Color(0xFFD85A30), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Add category',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: Color(0xFFD85A30),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── CTA ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD85A30),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Continue — Review & create',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
