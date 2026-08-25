import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/member_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/app_numeric_field.dart';
import '../../../core/widgets/inputs/app_dropdown.dart';
import '../../../core/widgets/inputs/app_date_picker.dart';

class AddExpenseForm extends StatefulWidget {
  final List<MemberModel> members;
  final void Function(ExpenseModel)? onExpenseAdded;
  final String? initialDescription;
  final double? initialAmount;
  final ExpenseCategory? initialCategory;
  final DateTime? initialDate;
  final String? initialPayerId;

  const AddExpenseForm({
    super.key,
    required this.members,
    this.onExpenseAdded,
    this.initialDescription,
    this.initialAmount,
    this.initialCategory,
    this.initialDate,
    this.initialPayerId,
  });

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  late ExpenseCategory _category;
  String          _payerId  = '';
  late DateTime   _date;
  final Set<String> _splitWithMemberIds = {};

  String? _descError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _amountCtrl = TextEditingController(
      text: widget.initialAmount != null && widget.initialAmount! > 0
          ? widget.initialAmount!.toStringAsFixed(0)
          : '',
    );
    _category = widget.initialCategory ?? ExpenseCategory.food;
    _date = widget.initialDate ?? DateTime.now();

    if (widget.initialPayerId != null &&
        widget.members.any((m) => m.id == widget.initialPayerId)) {
      _payerId = widget.initialPayerId!;
    } else if (widget.members.isNotEmpty) {
      _payerId = widget.members.first.id;
    }
    _splitWithMemberIds.addAll(widget.members.map((m) => m.id));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String? _payerError;

  bool _validate() {
    bool ok = true;
    setState(() {
      _descError   = _descCtrl.text.trim().isEmpty ? 'Please enter a description' : null;
      _amountError = (double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0) <= 0
          ? 'Please enter a valid amount'
          : null;
      _payerError  = _payerId.isEmpty ? 'Please select who paid' : null;
    });
    if (_descError != null || _amountError != null || _payerError != null) ok = false;
    return ok;
  }

  void _submit() {
    if (!_validate()) return;

    final expense = ExpenseModel(
      id:          const Uuid().v4(),
      description: _descCtrl.text.trim(),
      amount:      double.parse(_amountCtrl.text.trim().replaceAll(',', '')),
      category:    _category,
      paidById:    _payerId,
      date:        _date,
    );

    widget.onExpenseAdded?.call(expense);
    // Reset form
    _descCtrl.clear();
    _amountCtrl.clear();
    setState(() {
      _category    = ExpenseCategory.food;
      _date        = DateTime.now();
      _descError   = null;
      _amountError = null;
      _payerError  = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount (hero input) ────────────────────────────────
            AppNumericField(
              label: 'Amount',
              controller: _amountCtrl,
              hint: '0.00',
              errorText: _amountError,
              semanticsLabel: 'Expense amount',
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
            ),
            const SizedBox(height: 14),

            // ── Description ────────────────────────────────────────
            AppTextField(
              label: 'Description',
              controller: _descCtrl,
              hint: 'e.g. Dinner at the beach',
              errorText: _descError,
              prefixIcon: Icons.receipt_long_rounded,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_descError != null) setState(() => _descError = null);
              },
              semanticsLabel: 'Expense description',
            ),
            const SizedBox(height: 14),

            // ── Category ───────────────────────────────────────────
            AppDropdown<ExpenseCategory>(
              label: 'Category',
              value: _category,
              prefixIcon: Icons.category_rounded,
              onChanged: (v) => setState(() => _category = v!),
              items: const [
                DropdownMenuItem(
                  value: ExpenseCategory.hotel,
                  child: Row(children: [
                    Text('🏨  '), Text('Accommodation'),
                  ]),
                ),
                DropdownMenuItem(
                  value: ExpenseCategory.food,
                  child: Row(children: [
                    Text('🍽  '), Text('Food'),
                  ]),
                ),
                DropdownMenuItem(
                  value: ExpenseCategory.transport,
                  child: Row(children: [
                    Text('🚐  '), Text('Transport'),
                  ]),
                ),
                DropdownMenuItem(
                  value: ExpenseCategory.activities,
                  child: Row(children: [
                    Text('🏝  '), Text('Activities'),
                  ]),
                ),
                DropdownMenuItem(
                  value: ExpenseCategory.custom,
                  child: Row(children: [
                    Text('📦  '), Text('Other'),
                  ]),
                ),
              ],
              semanticsLabel: 'Expense category',
            ),
            const SizedBox(height: 14),

            // ── Paid by ────────────────────────────────────────────
            if (widget.members.isNotEmpty) ...[
              AppDropdown<String>(
                label: 'Paid by',
                value: _payerId.isNotEmpty ? _payerId : null,
                prefixIcon: Icons.person_rounded,
                errorText: _payerError,
                onChanged: (v) => setState(() {
                  _payerId = v!;
                  _payerError = null;
                }),
                items: widget.members.map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name),
                )).toList(),
                semanticsLabel: 'Who paid',
              ),
              const SizedBox(height: 14),
            ],

            // ── Split with (Multi-member) ──────────────────────────
            if (widget.members.length > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Split With',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepEarth,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_splitWithMemberIds.length == widget.members.length) {
                          _splitWithMemberIds.clear();
                        } else {
                          _splitWithMemberIds.addAll(widget.members.map((m) => m.id));
                        }
                      });
                    },
                    child: Text(
                      _splitWithMemberIds.length == widget.members.length ? 'Clear All' : 'All Members',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.members.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final m = widget.members[index];
                    final active = _splitWithMemberIds.contains(m.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (active) {
                            _splitWithMemberIds.remove(m.id);
                          } else {
                            _splitWithMemberIds.add(m.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? m.color : m.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active ? m.color : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (active) ...[
                              const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              m.name.split(' ').first,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : m.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_splitWithMemberIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final parsed = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
                    final perPerson = parsed > 0 && _splitWithMemberIds.isNotEmpty
                        ? parsed / _splitWithMemberIds.length
                        : 0.0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calculate_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            perPerson > 0
                                ? '₱${perPerson.toStringAsFixed(2)} / person (${_splitWithMemberIds.length} travelers)'
                                : 'Split equally among ${_splitWithMemberIds.length} travelers',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 14),
            ],

            // ── Date ───────────────────────────────────────────────
            AppDatePicker(
              label: 'Date',
              selectedDate: _date,
              lastDate: DateTime.now().add(const Duration(days: 1)),
              onDateSelected: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 18),

            // ── Submit ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add Expense',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
