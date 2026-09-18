import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Opening animation for Sri Vetri Vinayaga Auto Finance.
///
/// Sequence (3.4s total):
///   1. Deep navy ground
///   2. Soft golden ambient bloom
///   3. Fine gold particles drift upward
///   4. Logo fades and settles into place
///   5. A single restrained light sweep crosses the mark
///   6. Company name, then tagline
///   7. Fade through to the app
///
/// The splash is deliberately fixed-palette navy regardless of the selected
/// theme — like a bank's launch screen, it is brand furniture, not chrome.
///
/// Accessibility: when the platform requests reduced motion, the whole
/// sequence collapses to a 600ms fade with no particles or sweep.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF06182D);
  static const _navyDeep = Color(0xFF03101F);
  static const _gold = Color(0xFFD4AF37);
  static const _text = Color(0xFFF2F6FC);
  static const _subtext = Color(0xFF93A7C4);

  static const _fullDuration = Duration(milliseconds: 3400);
  static const _reducedDuration = Duration(milliseconds: 600);

  late final AnimationController _c =
      AnimationController(vsync: this, duration: _fullDuration);

  late final List<_Particle> _particles = _buildParticles();
  bool _navigated = false;
  bool _reducedMotion = false;

  // Full-motion timeline
  late final Animation<double> _bloom = _curve(0.00, 0.35, Curves.easeOutCubic);
  late final Animation<double> _particleFade =
      _curve(0.08, 0.45, Curves.easeOut);
  late final Animation<double> _logoOpacity =
      _curve(0.12, 0.42, Curves.easeOut);
  late final Animation<double> _logoScale =
      Tween<double>(begin: 0.88, end: 1.0).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.12, 0.52, curve: Curves.easeOutCubic),
    ),
  );
  late final Animation<double> _sweep = _curve(0.40, 0.68, Curves.easeInOut);
  late final Animation<double> _nameOpacity =
      _curve(0.50, 0.70, Curves.easeOut);
  late final Animation<double> _nameRise =
      Tween<double>(begin: 14, end: 0).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.50, 0.70, curve: Curves.easeOutCubic),
    ),
  );
  late final Animation<double> _taglineOpacity =
      _curve(0.64, 0.82, Curves.easeOut);
  late final Animation<double> _exitFade = _curve(0.88, 1.00, Curves.easeIn);

  Animation<double> _curve(double begin, double end, Curve curve) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _c, curve: Interval(begin, end, curve: curve)),
    );
  }

  List<_Particle> _buildParticles() {
    // Restrained on purpose — a handful of motes, not a snowstorm.
    final rng = math.Random(7);
    return List.generate(
      14,
      (_) => _Particle(
        dx: rng.nextDouble(),
        dy: rng.nextDouble(),
        radius: 0.7 + rng.nextDouble() * 1.4,
        drift: 0.25 + rng.nextDouble() * 0.5,
        phase: rng.nextDouble(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _go();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reducedMotion) {
      _reducedMotion = reduce;
      _c.duration = reduce ? _reducedDuration : _fullDuration;
    }
    if (!_c.isAnimating && _c.value == 0) _c.forward();
  }

  /// Hands off to the router. Auth state is read exactly as before — this
  /// screen makes no authentication decisions of its own.
  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final user = Supabase.instance.client.auth.currentSession?.user;
    context.go(user == null ? '/login' : '/');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSize = math.min(size.width * 0.52, 240.0);

    return Scaffold(
      backgroundColor: _navy,
      body: Semantics(
        label: 'Sri Vetri Vinayaga Auto Finance. Loading.',
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // Reduced motion: a plain crossfade of the final composition.
            if (_reducedMotion) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [_navy, _navyDeep],
                  ),
                ),
                child: Opacity(
                  opacity: Curves.easeOut.transform(_c.value),
                  child: _composition(logoSize, sweepValue: null),
                ),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1 + 2 — navy ground and ambient gold bloom
                DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.15),
                      radius: 1.1,
                      colors: [_navy, _navyDeep],
                    ),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: 0.6 + (_bloom.value * 0.55),
                    child: Container(
                      width: size.width * 0.9,
                      height: size.width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _gold.withValues(alpha: 0.16 * _bloom.value),
                            _gold.withValues(alpha: 0.05 * _bloom.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3 — fine gold particles
                if (_particleFade.value > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ParticlePainter(
                          particles: _particles,
                          progress: _c.value,
                          opacity: _particleFade.value * 0.55,
                          color: _gold,
                        ),
                      ),
                    ),
                  ),

                // 4–8 — logo, sweep, wordmark, tagline
                _composition(logoSize, sweepValue: _sweep.value),

                // 9 — exit fade
                if (_exitFade.value > 0.001)
                  IgnorePointer(
                    child: Opacity(
                      opacity: _exitFade.value,
                      child: const ColoredBox(
                        color: _navy,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _composition(double logoSize, {required double? sweepValue}) {
    final reduced = _reducedMotion;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo — never recoloured, rotated or distorted.
          Opacity(
            opacity: reduced ? 1 : _logoOpacity.value,
            child: Transform.scale(
              scale: reduced ? 1 : _logoScale.value,
              child: SizedBox(
                width: logoSize,
                height: logoSize,
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) {
                    // A single restrained gold sweep across the mark.
                    if (sweepValue == null || sweepValue <= 0) {
                      return const LinearGradient(
                        colors: [Colors.transparent, Colors.transparent],
                      ).createShader(rect);
                    }
                    final x = (sweepValue * 2.2) - 0.6;
                    return LinearGradient(
                      begin: Alignment(x - 0.45, -1),
                      end: Alignment(x + 0.45, 1),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ).createShader(rect);
                  },
                  child: Image.asset(
                    'assets/images/logo_with_name.png',
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.account_balance_rounded,
                      size: 96,
                      color: _gold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          // Company name
          Opacity(
            opacity: reduced ? 1 : _nameOpacity.value,
            child: Transform.translate(
              offset: Offset(0, reduced ? 0 : _nameRise.value),
              child: const Column(
                children: [
                  Text(
                    'SRI VETRI VINAYAGA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'AUTO FINANCE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Hairline rule
          Opacity(
            opacity: reduced ? 1 : _taglineOpacity.value,
            child: Container(
              width: 54,
              height: 1,
              color: _gold.withValues(alpha: 0.45),
            ),
          ),

          const SizedBox(height: 18),

          // Tagline
          Opacity(
            opacity: reduced ? 1 : _taglineOpacity.value,
            child: const Text(
              'YOUR DREAMS  •  OUR SUPPORT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _subtext,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double dx, dy, radius, drift, phase;
  const _Particle({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.drift,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double opacity;
  final Color color;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Slow upward drift with a gentle lateral sway.
      final t = (progress + p.phase) % 1.0;
      final y = (p.dy - (t * p.drift)) % 1.0;
      final x = p.dx + math.sin((t + p.phase) * math.pi * 2) * 0.015;

      // Fade in and out at the vertical extremes so nothing pops.
      final edgeFade = math.sin(y * math.pi).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: opacity * edgeFade);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.opacity != opacity;
}
