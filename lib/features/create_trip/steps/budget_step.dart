import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/inputs/app_numeric_field.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/buttons/app_back_button.dart';
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
  late TextEditingController _allowanceCtrl;
  String? _budgetError;

  @override
  void initState() {
    super.initState();
    final initial = widget.trip.totalBudget != null && widget.trip.totalBudget! > 0
        ? CurrencyUtils.formatAmount(widget.trip.totalBudget!)
        : '';
    _budgetCtrl = TextEditingController(text: initial);

    final initialAllowance = widget.trip.personalAllowance != null && widget.trip.personalAllowance! > 0
        ? CurrencyUtils.formatAmount(widget.trip.personalAllowance!)
        : '';
    _allowanceCtrl = TextEditingController(text: initialAllowance);
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _allowanceCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    // Always re-parse from the live controller text — do not rely on onChanged
    // having the latest value (e.g. user could clear field after onChanged fired)
    final raw = _budgetCtrl.text.trim().replaceAll(',', '');
    final val = double.tryParse(raw) ?? 0;
    if (val <= 0) {
      setState(() => _budgetError = 'Please enter a budget greater than ₱0');
      return;
    }
    widget.trip.totalBudget = val;

    final rawAllowance = _allowanceCtrl.text.trim().replaceAll(',', '');
    widget.trip.personalAllowance = double.tryParse(rawAllowance);

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
                  AppBackButton(
                    variant: AppBackButtonVariant.brand,
                    onPressed: widget.onBack,
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
                currentStep: 3,
                totalSteps: 4,
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
                        final clean = v.replaceAll(',', '');
                        final val = double.tryParse(clean) ?? 0;
                        widget.trip.totalBudget = val;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Personal pocket money / allowance input (Optional)
                    AppNumericField(
                      label: 'My personal allowance (Optional)',
                      controller: _allowanceCtrl,
                      hint: 'e.g. 10,000 for solo snacks & shopping',
                      decimal: false,
                      semanticsLabel: 'Personal allowance input',
                      onChanged: (v) {
                        final clean = v.replaceAll(',', '');
                        final val = double.tryParse(clean);
                        widget.trip.personalAllowance = val;
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
                            Expanded(
                              child: Text(
                                widget.trip.currency,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.check_rounded,
                                color: Color(0xFFD85A30), size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Split Strategy ──────────────────────────────────
                    const Text(
                      'Split Strategy',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildSplitTile('equal', '⚖️', 'Equal', 'Even split per person'),
                        const SizedBox(width: 8),
                        _buildSplitTile('fixed', '🎯', 'Fixed', 'Custom peso amounts'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSplitTile('percentage', '📊', 'Percent', 'Split by % share'),
                        const SizedBox(width: 8),
                        _buildSplitTile('treat', '🎁', 'Treat', 'Host covers costs'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Live estimated cost per person preview
                    if ((widget.trip.totalBudget ?? 0) > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.sand.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getSplitPreviewText(),
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepEarth,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 20),

                    // ── Category Breakdown Section ────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Category Breakdown',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        if ((widget.trip.totalBudget ?? 0) > 0)
                          GestureDetector(
                            onTap: _autoDistributeBudget,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Auto-fill ratios',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Stacked multi-color progress bar
                    _buildStackedCategoryBar(),
                    const SizedBox(height: 14),

                    // Category items list
                    ...widget.trip.budgetBreakdown.asMap().entries.map((entry) {
                      return _buildCategoryItemCard(entry.key, entry.value);
                    }),
                    const SizedBox(height: 10),

                    // Add Custom Category button
                    GestureDetector(
                      onTap: _showAddCategorySheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Add Category',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildSplitTile(String mode, String icon, String title, String subtitle) {
    final active = widget.trip.splitMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            widget.trip.splitMode = mode;
            widget.trip.splitEqually = (mode == 'equal');
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.sand : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.primary : const Color(0xFFE5E7EB),
              width: active ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.primary : AppColors.deepEarth,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  color: AppColors.warmMuted,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSplitPreviewText() {
    final total = widget.trip.totalBudget ?? 0;
    final count = widget.trip.travelers.length;
    final travelerLabel = count == 1 ? '1 traveler' : '$count travelers';

    switch (widget.trip.splitMode) {
      case 'equal':
        final perPerson = count > 0 ? total / count : total;
        return count > 0
            ? '⚖️ Equal split: ₱${CurrencyUtils.formatAmount(perPerson)} / person ($travelerLabel)'
            : '⚖️ Equal split: ₱${CurrencyUtils.formatAmount(total)} total';
      case 'fixed':
        return '🎯 Fixed mode: Set custom peso amounts per member after creation';
      case 'percentage':
        return '📊 Percent mode: Allocate percentage shares per member after creation';
      case 'treat':
        return '🎁 Treat mode: Host covers the total ₱${CurrencyUtils.formatAmount(total)} budget';
      default:
        return 'Split mode selected';
    }
  }

  void _autoDistributeBudget() {
    final total = widget.trip.totalBudget ?? 0;
    if (total <= 0) return;

    setState(() {
      for (final cat in widget.trip.budgetBreakdown) {
        final name = cat.name.toLowerCase();
        if (name.contains('accommodat') || name.contains('stay')) {
          cat.amount = (total * 0.35).roundToDouble();
        } else if (name.contains('food') || name.contains('din')) {
          cat.amount = (total * 0.30).roundToDouble();
        } else if (name.contains('activit') || name.contains('tour')) {
          cat.amount = (total * 0.20).roundToDouble();
        } else if (name.contains('transp') || name.contains('flight')) {
          cat.amount = (total * 0.15).roundToDouble();
        } else {
          cat.amount = (total * 0.10).roundToDouble();
        }
      }
    });
  }

  Widget _buildStackedCategoryBar() {
    final totalBudget = widget.trip.totalBudget ?? 0;
    final sumAllocated = widget.trip.budgetBreakdown.fold(0.0, (sum, c) => sum + c.amount);
    final pctAllocated = totalBudget > 0 ? (sumAllocated / totalBudget * 100).clamp(0, 999).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Allocated: ₱${CurrencyUtils.formatAmount(sumAllocated)}',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sumAllocated > totalBudget && totalBudget > 0 ? const Color(0xFFEF4444) : AppColors.deepEarth,
              ),
            ),
            if (totalBudget > 0)
              Text(
                '$pctAllocated% of budget',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sumAllocated > totalBudget ? const Color(0xFFEF4444) : AppColors.warmMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            color: const Color(0xFFE5E7EB),
            child: totalBudget > 0 && sumAllocated > 0
                ? Row(
                    children: widget.trip.budgetBreakdown.map((cat) {
                      final flex = (cat.amount / totalBudget * 1000).round();
                      if (flex <= 0) return const SizedBox.shrink();
                      return Expanded(
                        flex: flex,
                        child: Container(color: Color(cat.color)),
                      );
                    }).toList(),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItemCard(int index, BudgetCategory category) {
    final totalBudget = widget.trip.totalBudget ?? 0;
    final pct = totalBudget > 0 ? (category.amount / totalBudget * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Color(category.color).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(category.icon, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepEarth,
                  ),
                ),
                if (totalBudget > 0)
                  Text(
                    '$pct% of total',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: AppColors.warmMuted,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 95,
            height: 36,
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              controller: TextEditingController(
                text: category.amount > 0 ? CurrencyUtils.formatAmount(category.amount) : '',
              )..selection = TextSelection.collapsed(offset: (category.amount > 0 ? CurrencyUtils.formatAmount(category.amount) : '').length),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
              decoration: InputDecoration(
                prefixText: '₱',
                prefixStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.warmMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (val) {
                final clean = val.replaceAll(',', '').trim();
                final parsed = double.tryParse(clean) ?? 0;
                setState(() => category.amount = parsed);
              },
            ),
          ),
          if (widget.trip.budgetBreakdown.length > 1) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.warmMuted),
              onPressed: () {
                setState(() => widget.trip.budgetBreakdown.removeAt(index));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddCategorySheet() {
    final presets = [
      {'name': 'Flights & Transit', 'icon': '✈️', 'color': 0xFF3B82F6},
      {'name': 'Shopping & Souvenirs', 'icon': '🛍️', 'color': 0xFFEC4899},
      {'name': 'Emergency Buffer', 'icon': '🛡️', 'color': 0xFF6366F1},
      {'name': 'Nightlife & Drinks', 'icon': '🍸', 'color': 0xFF8B5CF6},
    ];

    final customCtrl = TextEditingController();
    String selectedEmoji = '📦';
    final emojiOptions = ['📦', '🎟️', '🏄', '📸', '⛵', '🍕', '🎁', '💆', '🛒', '⛽'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Category',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEarth,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.warmMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Custom category form
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CUSTOM CATEGORY',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(selectedEmoji, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: customCtrl,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepEarth,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'e.g. Gear Rental, Souvenirs…',
                                hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.warmMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: emojiOptions.map((e) {
                            final active = selectedEmoji == e;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedEmoji = e),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.sand : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: active ? AppColors.primary : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(e, style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = customCtrl.text.trim();
                            if (name.isEmpty) return;
                            setState(() {
                              widget.trip.budgetBreakdown.add(
                                BudgetCategory(
                                  name: name,
                                  amount: 0,
                                  color: 0xFF8B5CF6,
                                  icon: selectedEmoji,
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Add Custom Category',
                            style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'OR QUICK PRESETS',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ...presets.map((p) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(p['color'] as int).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(p['icon'] as String, style: const TextStyle(fontSize: 16))),
                    ),
                    title: Text(
                      p['name'] as String,
                      style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth),
                    ),
                    trailing: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                    onTap: () {
                      setState(() {
                        widget.trip.budgetBreakdown.add(
                          BudgetCategory(
                            name: p['name'] as String,
                            amount: 0,
                            color: p['color'] as int,
                            icon: p['icon'] as String,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
        },
      ),
    );
  }
}
