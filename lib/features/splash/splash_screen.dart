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
  /// True when the app launches with an active Supabase session.
  /// In this case we skip showing the "Get started" button and wait
  /// for the profile to finish loading, then navigate straight to /home.
  bool _hasActiveSession = false;
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _buttonsSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic)),
    );

    _ctrl.forward();

    // Detect whether the user already has an active Supabase session.
    // If yes, show a loading indicator on splash and auto-navigate to /home
    // once the profile finishes loading from Supabase.
    final session = Supabase.instance.client.auth.currentSession;
    _hasActiveSession = session != null;
  }

  /// Called by the Riverpod listener whenever profileProvider emits a new state.
  void _onProfileChanged(ProfileState? _, ProfileState profile) {
    if (_isNavigating || !profile.isLoaded) return;
    if (profile.hasCompletedOnboarding) {
      _navigateTo('/home', skipDelay: _hasActiveSession);
    } else if (_hasActiveSession) {
      // Session exists but onboarding not complete — go to onboarding.
      _isNavigating = true;
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  Future<void> _navigateTo(String route, {bool skipDelay = false}) async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    if (skipDelay) {
      // Returning user — navigate as soon as animation completes or immediately.
      await Future.delayed(const Duration(milliseconds: 300));
    } else {
      // Wait for the splash animation to finish before navigating
      final remaining =
          _ctrl.duration! - (_ctrl.duration! * _ctrl.value);
      if (remaining > Duration.zero) {
        await Future.delayed(remaining + const Duration(milliseconds: 300));
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
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
    // Use ref.listen for reliable state-change callbacks — avoids the
    // addPostFrameCallback race that the old approach had.
    ref.listen<ProfileState>(profileProvider, _onProfileChanged);

    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(flex: 3),

                // ── Logo + Branding ──────────────────────────────
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 28),

                        FadeTransition(
                          opacity: _textOpacity,
                          child: const Text(
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
                        ),

                        FadeTransition(
                          opacity: _textOpacity,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'TRAVEL',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                letterSpacing: 5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        FadeTransition(
                          opacity: _textOpacity,
                          child: Text(
                            'Your journey, your way',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Buttons / Loading ────────────────────────────
                SlideTransition(
                  position: _buttonsSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        if (!profile.isLoaded || (_hasActiveSession && !_isNavigating)) ...[
                          // Show shimmer while loading, or when returning user
                          // session is detected (waiting for profile + auto-nav).
                          const _ShimmerContainer(
                              width: double.infinity, height: 54),
                        ] else if (!_hasActiveSession) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isNavigating ? null : _handleGetStarted,
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

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _ShimmerContainer extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerContainer({required this.width, required this.height});

  @override
  State<_ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<_ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

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
      builder: (context, child) {
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
