import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/widgets/inputs/map_pin_picker_modal.dart';

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

  // Infinite Carousel controller & state
  late PageController _pageController;
  double _currentPage = 5000.0;
  static const int _virtualItemCount = 10000;

  // Common Philippine transportation modes (removed 'other')
  static const _modes = [
    TransportMode.car,
    TransportMode.motorcycle,
    TransportMode.commute,
    TransportMode.jeepney,
    TransportMode.tricycle,
    TransportMode.bus,
    TransportMode.vanHire,
    TransportMode.ferry,
    TransportMode.plane,
    TransportMode.bike,
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

    int initialIndex = _modes.indexOf(_selected);
    if (initialIndex < 0) initialIndex = 0;

    // Start in the middle of virtual scroll range to allow infinite left/right swiping
    final initialVirtualIndex = (_virtualItemCount ~/ 2) - ((_virtualItemCount ~/ 2) % _modes.length) + initialIndex;
    _currentPage = initialVirtualIndex.toDouble();
    _pageController = PageController(
      initialPage: initialVirtualIndex,
      viewportFraction: 0.52,
    );

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = _pageController.page ?? _currentPage;
        });
      }
    });

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  Future<void> _pickDepartureOnMap() async {
    final result = await MapPinPickerModal.show(
      context,
      initialAddress: _departureCtrl.text.trim(),
    );

    if (result != null) {
      setState(() {
        _departureCtrl.text = result.displayName;
      });
    }
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'How are you getting there?',
                          style: TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepEarth),
                        ),
                        Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.muted),
                            SizedBox(width: 4),
                            Text('Swipe', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Infinite Loop Animated Carousel Card
                    _buildInfiniteCarousel(),

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

  Widget _buildInfiniteCarousel() {
    return SizedBox(
      height: 145,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _virtualItemCount,
        onPageChanged: (index) {
          final m = _modes[index % _modes.length];
          if (_selected != m) {
            _onSelectMode(m);
          }
        },
        itemBuilder: (context, index) {
          final m = _modes[index % _modes.length];
          final isSelected = _selected == m;

          double pageDelta = (index - _currentPage).abs();
          double scale = (1.0 - (pageDelta * 0.15)).clamp(0.85, 1.0);
          double opacity = (1.0 - (pageDelta * 0.35)).clamp(0.6, 1.0);

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                  _onSelectMode(m);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.chipBackground : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.dividerLight,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                            )
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        m.emoji,
                        style: TextStyle(fontSize: isSelected ? 36 : 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: isSelected ? 13 : 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.deepEarth,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
          _buildDepartureField('Departure Point (MapLibre)', 'Tap map pin or type departure point...', _departureCtrl),
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

  Widget _buildDepartureField(String label, String hint, TextEditingController ctrl) {
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
            suffixIcon: IconButton(
              icon: const Icon(Icons.map_rounded, color: AppColors.primary, size: 22),
              tooltip: 'Select on MapLibre Map',
              onPressed: _pickDepartureOnMap,
            ),
          ),
          onTap: () {
            if (ctrl.text.trim().isEmpty) {
              _pickDepartureOnMap();
            }
          },
        ),
      ],
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
