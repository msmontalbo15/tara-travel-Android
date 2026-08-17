import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onGetStarted;
  const SplashScreen({
    super.key,
    required this.onGetStarted,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isNavigating = false;
  bool _hasActiveSession = false;

  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoRotation;
  late final Animation<double> _ripplePulse;
  late final Animation<double> _textOpacity;
  late final Animation<double> _letterSpacing;
  late final Animation<Offset> _buttonsSlide;

  static const _textGradient = LinearGradient(
    colors: [
      AppColors.primary,
      AppColors.primaryLight,
    ],
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _ripplePulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _letterSpacing = Tween<double>(begin: 1.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _buttonsSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.forward();

    final session = Supabase.instance.client.auth.currentSession;
    _hasActiveSession = session != null;
  }

  void _onProfileChanged(ProfileState? _, ProfileState profile) {
    if (_isNavigating || !profile.isLoaded) return;
    if (_hasActiveSession || profile.hasCompletedOnboarding) {
      _navigateTo('/home');
    }
  }

  Future<void> _navigateTo(String route) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    if (_ctrl.isAnimating) {
      final remaining = _ctrl.duration! * (1.0 - _ctrl.value);
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _handleGetStarted() {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    widget.onGetStarted();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileProvider, _onProfileChanged);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ctrl,
                          child: Image.asset(
                            'assets/logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          builder: (context, logoChild) => Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(140, 140),
                                painter: _LogoRipplePainter(
                                  pulseProgress: _ripplePulse.value,
                                  opacity: _logoOpacity.value,
                                ),
                              ),
                              Transform.rotate(
                                angle: _logoRotation.value,
                                child: logoChild,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _textOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Tara',
                                style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 52,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.0,
                                  letterSpacing: -1,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _letterSpacing,
                                builder: (context, _) => ShaderMask(
                                  shaderCallback: (bounds) =>
                                      _textGradient.createShader(bounds),
                                  child: Text(
                                    'TRAVEL',
                                    style: TextStyle(
                                      fontFamily: 'Playfair Display',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                      letterSpacing: _letterSpacing.value,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Your journey, your way',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.45),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: SlideTransition(
                    position: _buttonsSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!profile.isLoaded ||
                              (_hasActiveSession && !_isNavigating)) ...[
                            const _ShimmerContainer(
                                width: double.infinity, height: 54),
                          ] else if (!_hasActiveSession) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                    _isNavigating ? null : _handleGetStarted,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Get started',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoRipplePainter extends CustomPainter {
  final double pulseProgress;
  final double opacity;

  static final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  _LogoRipplePainter({
    required this.pulseProgress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pulseProgress <= 0 || pulseProgress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final alpha = (1.0 - pulseProgress).clamp(0.0, 1.0) * 0.45 * opacity;

    _paint.color = AppColors.amber.withValues(alpha: alpha);
    canvas.drawCircle(center, radius * (0.7 + pulseProgress * 0.5), _paint);
  }

  @override
  bool shouldRepaint(covariant _LogoRipplePainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.opacity != opacity;
  }
}

class _ShimmerContainer extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerContainer({required this.width, required this.height});

  @override
  State<_ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<_ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, _) {
        final v = _shimmerCtrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
              stops: [
                (v - 0.3).clamp(0.0, 1.0),
                v.clamp(0.0, 1.0),
                (v + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
