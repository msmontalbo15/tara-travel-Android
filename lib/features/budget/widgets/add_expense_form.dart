import 'package:flutter/material.dart';
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

  const AddExpenseForm({
    super.key,
    required this.members,
    this.onExpenseAdded,
  });

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  String          _payerId  = '';
  DateTime        _date     = DateTime.now();

  String? _descError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      _payerId = widget.members.first.id;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _descError   = _descCtrl.text.trim().isEmpty ? 'Please enter a description' : null;
      _amountError = (double.tryParse(_amountCtrl.text) ?? 0) <= 0
          ? 'Please enter a valid amount'
          : null;
    });
    if (_descError != null || _amountError != null) ok = false;
    return ok;
  }

  void _submit() {
    if (!_validate()) return;

    final expense = ExpenseModel(
      id:          DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descCtrl.text.trim(),
      amount:      double.parse(_amountCtrl.text),
      category:    _category,
      paidById:    _payerId,
      date:        _date,
    );

    widget.onExpenseAdded?.call(expense);
    // Reset form
    _descCtrl.clear();
    _amountCtrl.clear();
    setState(() {
      _category   = ExpenseCategory.food;
      _date       = DateTime.now();
      _descError  = null;
      _amountError = null;
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
                onChanged: (v) => setState(() => _payerId = v!),
                items: widget.members.map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name),
                )).toList(),
                semanticsLabel: 'Who paid',
              ),
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
