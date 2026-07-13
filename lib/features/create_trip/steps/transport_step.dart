import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';

class TransportStep extends StatefulWidget {
  final TransportDetail? initial;
  final void Function(TransportDetail detail) onNext;
  final VoidCallback onBack;

  const TransportStep({super.key, this.initial, required this.onNext, required this.onBack});

  @override
  State<TransportStep> createState() => _TransportStepState();
}

class _TransportStepState extends State<TransportStep> with SingleTickerProviderStateMixin {
  TransportMode _selected = TransportMode.car;
  int _vehicleCount = 1;
  final _departureCtrl = TextEditingController();
  final _flightCtrl = TextEditingController();
  final _pierCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _splitGas = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _modes = [
    TransportMode.car,
    TransportMode.motorcycle,
    TransportMode.bus,
    TransportMode.plane,
    TransportMode.ferry,
    TransportMode.jeepney,
    TransportMode.vanHire,
    TransportMode.bike,
    TransportMode.other,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _selected = widget.initial!.mode;
      _vehicleCount = widget.initial!.vehicleCount ?? 1;
      _departureCtrl.text = widget.initial!.departurePoint ?? '';
      _flightCtrl.text = widget.initial!.flightNumber ?? '';
      _pierCtrl.text = widget.initial!.pierName ?? '';
      _durationCtrl.text = widget.initial!.estimatedDuration;
      _splitGas = widget.initial!.splitGas;
    }
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _departureCtrl.dispose();
    _flightCtrl.dispose();
    _pierCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _onSelectMode(TransportMode m) {
    setState(() => _selected = m);
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  void _submit() {
    widget.onNext(TransportDetail(
      mode: _selected,
      vehicleCount: _vehicleCount,
      departurePoint: _departureCtrl.text.trim().isEmpty ? null : _departureCtrl.text.trim(),
      flightNumber: _flightCtrl.text.trim().isEmpty ? null : _flightCtrl.text.trim(),
      pierName: _pierCtrl.text.trim().isEmpty ? null : _pierCtrl.text.trim(),
      estimatedDuration: _durationCtrl.text.trim(),
      splitGas: _splitGas,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0A04), AppColors.deepEarth],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Step 2 of 4', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white54)),
                          Text('Transport Mode', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                    // Progress bar
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How are you getting there?', style: TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
                    const SizedBox(height: 16),

                    // 3×3 Transport Grid
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: _modes.map((m) => _TransportModeCard(
                        mode: m,
                        selected: _selected == m,
                        onTap: () => _onSelectMode(m),
                      )).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Dynamic sub-fields
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildSubFields(),
                    ),

                    const SizedBox(height: 32),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Continue to Budget →', style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_selected.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(_selected.label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Departure Point', 'e.g. EDSA Cubao → Caticlan Port', _departureCtrl),
          if (_selected == TransportMode.car || _selected == TransportMode.vanHire || _selected == TransportMode.motorcycle) ...[
            const SizedBox(height: 12),
            _buildVehicleCountStepper(),
          ],
          if (_selected == TransportMode.car) ...[
            const SizedBox(height: 12),
            _buildGasSplitToggle(),
          ],
          if (_selected == TransportMode.plane) ...[
            const SizedBox(height: 12),
            _buildTextField('Flight Number', 'e.g. PR5814', _flightCtrl),
          ],
          if (_selected == TransportMode.ferry) ...[
            const SizedBox(height: 12),
            _buildTextField('Pier / Port Name', 'e.g. Caticlan Jetty Port', _pierCtrl),
          ],
          const SizedBox(height: 12),
          _buildTextField('Estimated Travel Time', 'e.g. ~8h 30min', _durationCtrl),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: AppColors.deepEarth),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCountStepper() {
    return Row(
      children: [
        const Expanded(
          child: Text('Number of vehicles', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
        ),
        Row(
          children: [
            _stepperBtn(Icons.remove_rounded, () { if (_vehicleCount > 1) setState(() => _vehicleCount--); }),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Text('$_vehicleCount', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepEarth)),
            ),
            _stepperBtn(Icons.add_rounded, () => setState(() => _vehicleCount++)),
          ],
        ),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  Widget _buildGasSplitToggle() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Split gas cost', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepEarth)),
              Text('Auto-add fuel line to budget', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
        Switch.adaptive(
          value: _splitGas,
          onChanged: (v) => setState(() => _splitGas = v),
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

class _TransportModeCard extends StatelessWidget {
  final TransportMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _TransportModeCard({required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.dividerLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mode.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              mode.label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.deepEarth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
