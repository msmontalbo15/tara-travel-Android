import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/app_numeric_field.dart';

class AddStopForm extends StatefulWidget {
  final List<MemberModel> members;
  final void Function(ItineraryStop stop) onAdd;

  const AddStopForm({super.key, required this.members, required this.onAdd});

  @override
  State<AddStopForm> createState() => _AddStopFormState();
}

class _AddStopFormState extends State<AddStopForm> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  StopType _selectedType = StopType.activity;
  TransportMode _selectedTransportMode = TransportMode.car;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _assignedMemberId;
  String? _titleError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Please enter a stop title');
      return;
    }
    final stop = ItineraryStop(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      type: _selectedType,
      startTime: _startTime,
      endTime: _endTime,
      estimatedCost: double.tryParse(_costCtrl.text),
      assignedMemberId: _assignedMemberId,
      transportMode: _selectedType == StopType.transport ? _selectedTransportMode : null,
    );
    widget.onAdd(stop);
    _titleCtrl.clear();
    _notesCtrl.clear();
    _costCtrl.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
      _assignedMemberId = null;
      _selectedTransportMode = TransportMode.car;
      _titleError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Stop', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
          const SizedBox(height: 12),

          // Stop type chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: StopType.values.map((t) {
                final active = _selectedType == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? t.color : t.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(t.icon, size: 14, color: active ? Colors.white : t.color),
                        const SizedBox(width: 4),
                        Text(t.label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : t.color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Transport mode picker (only when Transport type selected)
          if (_selectedType == StopType.transport) ...[
            const Text('Transport Mode', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 8),
            _buildTransportModePicker(),
            const SizedBox(height: 12),
          ],

          // Title
          AppTextField(
            label: 'Stop title',
            controller: _titleCtrl,
            hint: 'e.g. Eiffel Tower visit',
            errorText: _titleError,
            prefixIcon: Icons.place_rounded,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            semanticsLabel: 'Itinerary stop title',
          ),
          const SizedBox(height: 10),

          // Time row
          Row(
            children: [
              Expanded(child: _timePicker('Start time', _startTime, () => _pickTime(true))),
              const SizedBox(width: 10),
              Expanded(child: _timePicker('End time', _endTime, () => _pickTime(false))),
            ],
          ),
          const SizedBox(height: 10),

          // Cost
          AppNumericField(
            label: 'Estimated cost',
            controller: _costCtrl,
            semanticsLabel: 'Estimated cost of stop',
          ),
          const SizedBox(height: 10),

          // Notes
          AppTextField(
            label: 'Notes (optional)',
            controller: _notesCtrl,
            hint: 'Any additional details...',
            prefixIcon: Icons.notes_rounded,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            semanticsLabel: 'Stop notes',
          ),
          const SizedBox(height: 12),

          // Assigned member
          if (widget.members.isNotEmpty) ...[
            const Text('Assign to', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.members.map((m) {
                  final active = _assignedMemberId == m.id;
                  return GestureDetector(
                    onTap: () => setState(() => _assignedMemberId = active ? null : m.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? m.color : m.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(m.name.split(' ').first, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : m.color)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Stop', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _field() kept for backward compatibility — used only by _buildTransportModePicker.
  // New inputs use AppTextField/AppNumericField directly.

  static const _transportModes = TransportMode.values;

  Widget _buildTransportModePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _transportModes.map((m) {
        final active = _selectedTransportMode == m;
        return GestureDetector(
          onTap: () => setState(() => _selectedTransportMode = m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.dividerLight,
                width: active ? 1.5 : 1,
              ),
              boxShadow: active
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  m.label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.deepEarth,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    String display = time != null
        ? '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}'
        : label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(display, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: time != null ? AppColors.deepEarth : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
