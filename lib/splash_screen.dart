import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const SuppleWiseApp());
}

class SuppleWiseApp extends StatelessWidget {
  const SuppleWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuppleWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Color Tokens ─────────────────────────────────────────────────────────────
const kPrimary               = Color(0xFF006948);
const kSurface               = Color(0xFFF8F9FF);
const kOnSurfaceVariant      = Color(0xFF3D4A42);
const kSurfaceContainerHigh  = Color(0xFFDCE9FF);

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Float animation (translateY 0 → -10px, 6 s)
  late final AnimationController _floatCtrl;
  late final Animation<double>    _floatAnim;

  // Pulse ring (scale 0.8 → 1.5, opacity 0 → 0.1 → 0, 4 s)
  late final AnimationController _pulseCtrl;
  late final Animation<double>    _pulseScale;
  late final Animation<double>    _pulseOpacity;

  // Background glow pulse
  late final AnimationController _bgPulseCtrl;
  late final Animation<double>    _bgOpacity;

  // Progress bar
  late final AnimationController _progressCtrl;
  late final Animation<double>    _progressAnim;

  // Parallax (simulates mouse-move via drag)
  Offset _parallax = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Float
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Pulse ring
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseScale = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.10), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: 0.0), weight: 50),
    ]).animate(_pulseCtrl);

    // Background glow
    _bgPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bgOpacity = Tween<double>(begin: 0.03, end: 0.08).animate(
      CurvedAnimation(parent: _bgPulseCtrl, curve: Curves.easeInOut),
    );

    // Progress (random increments totalling 100%, ~3.5 s)
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _progressAnim = _buildProgress();
    _progressCtrl.forward();
  }

  Animation<double> _buildProgress() {
    final rng = Random();
    final items = <TweenSequenceItem<double>>[];
    double total = 0;
    double time  = 0;
    const double stepMs = 300 / 3500; // ~0.0857

    while (total < 100) {
      final inc    = rng.nextDouble() * 15 + 2;
      final newVal = min(total + inc, 100.0);
      final weight = min(stepMs * 100, 100 - time * 100).clamp(0.01, 100.0);
      items.add(TweenSequenceItem(
        tween: Tween<double>(begin: total / 100, end: newVal / 100),
        weight: weight,
      ));
      total = newVal;
      time  = min(time + stepMs, 1.0);
      if (total >= 100) break;
    }
    if (items.isEmpty) {
      items.add(TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 100,
      ));
    }

    return TweenSequence<double>(items).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _bgPulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final sz = MediaQuery.of(context).size;
    const amt = 20.0;
    setState(() {
      _parallax = Offset(
        (d.localPosition.dx / sz.width  - 0.5) * amt,
        (d.localPosition.dy / sz.height - 0.5) * amt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: Scaffold(
        backgroundColor: kSurface,
        body: Stack(
          children: [
            // ── Background radial glow ──────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgOpacity,
                builder: (_, __) => Center(
                  child: CustomPaint(
                    size: const Size(400, 400),
                    painter: _GlowPainter(opacity: _bgOpacity.value),
                  ),
                ),
              ),
            ),

            // ── Centre branding cluster ─────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _floatAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(
                    _parallax.dx,
                    _floatAnim.value + _parallax.dy,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo + pulse ring
                      _LogoWithRing(
                        pulseScale:   _pulseScale,
                        pulseOpacity: _pulseOpacity,
                        logoSize:     isWide ? 128.0 : 96.0,
                        iconSize:     isWide ? 64.0  : 48.0,
                      ),
                      const SizedBox(height: 24),

                      // "SuppleWise"
                      Text(
                        'SuppleWise',
                        style: TextStyle(
                          fontFamily:  'Inter',
                          fontSize:    isWide ? 24 : 22,
                          fontWeight:  FontWeight.w800,
                          color:       kPrimary,
                          letterSpacing: -0.24,
                          height:      32 / 24,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Tagline
                      Text(
                        'DECISION SUPPORT INTELLIGENCE',
                        style: TextStyle(
                          fontFamily:   'Inter',
                          fontSize:     12,
                          fontWeight:   FontWeight.w600,
                          color:        kOnSurfaceVariant.withOpacity(0.60),
                          letterSpacing: 2.4, // ~0.2em
                          height:       16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Progress bar + label ────────────────────────────────────
            Positioned(
              bottom: 64,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        width:  64,
                        height: 4,
                        child: AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (_, __) => Stack(
                            children: [
                              Container(color: kSurfaceContainerHigh),
                              FractionallySizedBox(
                                widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                                child: Container(color: kPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing Analytics...',
                    style: TextStyle(
                      fontFamily:  'Inter',
                      fontSize:    14,
                      fontWeight:  FontWeight.w400,
                      color:       kOnSurfaceVariant.withOpacity(0.40),
                      height:      20 / 14,
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom bar ──────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Watermark logo mark
                    Opacity(
                      opacity: 0.10,
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color:        kPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size:  28,
                        ),
                      ),
                    ),

                    // Version string
                    Text(
                      'v.1.0.4 - STABLE',
                      style: TextStyle(
                        fontFamily:   'Inter',
                        fontSize:     12,
                        fontWeight:   FontWeight.w600,
                        color:        kOnSurfaceVariant.withOpacity(0.20),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logo + Pulse Ring ─────────────────────────────────────────────────────────
class _LogoWithRing extends StatelessWidget {
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;
  final double logoSize;
  final double iconSize;

  const _LogoWithRing({
    required this.pulseScale,
    required this.pulseOpacity,
    required this.logoSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  logoSize * 2,
      height: logoSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          AnimatedBuilder(
            animation: Listenable.merge([pulseScale, pulseOpacity]),
            builder: (_, __) => Transform.scale(
              scale: pulseScale.value,
              child: Container(
                width:  logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withOpacity(pulseOpacity.value),
                ),
              ),
            ),
          ),

          // Logo card
          Container(
            width:  logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color:        kPrimary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:       const Color(0xFF006948).withOpacity(0.20),
                  blurRadius:  40,
                  offset:      const Offset(0, 20),
                ),
              ],
            ),
            child: Icon(
              Icons.analytics,
              color: Colors.white,
              size:  iconSize,
              // Filled variant mimics FILL:1 in Material Symbols
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background Glow Painter ───────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  final double opacity;
  const _GlowPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint  = Paint()
      ..shader = RadialGradient(
        colors: [
          kPrimary.withOpacity(opacity),
          kPrimary.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.opacity != opacity;
}