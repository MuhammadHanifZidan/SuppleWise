import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const SuppleWiseApp());
}

// ─── Color Tokens ─────────────────────────────────────────────────────────────
const kPrimary                = Color(0xFF006948);
const kOnPrimary              = Color(0xFFFFFFFF);
const kPrimaryContainer       = Color(0xFF00855D);
const kOnPrimaryContainer     = Color(0xFFF5FFF7);
const kSurface                = Color(0xFFF8F9FF);
const kSurfaceContainerLowest = Color(0xFFFFFFFF);
const kSurfaceContainer       = Color(0xFFE5EEFF);
const kSurfaceContainerHigh   = Color(0xFFDCE9FF);
const kOnSurface              = Color(0xFF0B1C30);
const kOnSurfaceVariant       = Color(0xFF3D4A42);
const kOutlineVariant         = Color(0xFFBCCAC0);
const kTertiary               = Color(0xFF0058BE);
const kTertiaryContainer      = Color(0xFF2170E4);
const kSecondaryContainer     = Color(0xFFD5E0F8);
const kOnSecondaryContainer   = Color(0xFF586377);

// ─── App Root ─────────────────────────────────────────────────────────────────
class SuppleWiseApp extends StatelessWidget {
  const SuppleWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuppleWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: kSurface,
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          onPrimary: kOnPrimary,
          surface: kSurface,
          onSurface: kOnSurface,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SPLASH SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double>    _floatAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double>    _pulseScale;
  late final Animation<double>    _pulseOpacity;

  late final AnimationController _bgPulseCtrl;
  late final Animation<double>    _bgOpacity;

  late final AnimationController _progressCtrl;
  late final Animation<double>    _progressAnim;

  Offset _parallax = Offset.zero;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _pulseScale = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.10), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: 0.0),  weight: 50),
    ]).animate(_pulseCtrl);

    _bgPulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _bgOpacity = Tween<double>(begin: 0.03, end: 0.08).animate(
      CurvedAnimation(parent: _bgPulseCtrl, curve: Curves.easeInOut),
    );

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500));
    _progressAnim = _buildProgress();
    _progressCtrl.forward().then((_) {
      // Navigate to dashboard after progress completes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) => const DashboardScreen(),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(
                opacity: anim,
                child: child,
              ),
            ),
          );
        }
      });
    });
  }

  Animation<double> _buildProgress() {
    final rng   = Random();
    final items = <TweenSequenceItem<double>>[];
    double total = 0;
    double time  = 0;
    const double stepRatio = 300 / 3500;

    while (total < 100) {
      final inc    = rng.nextDouble() * 15 + 2;
      final newVal = min(total + inc, 100.0);
      final weight = max((stepRatio * 100).clamp(0.01, 100.0), 0.01);
      items.add(TweenSequenceItem(
        tween: Tween<double>(begin: total / 100, end: newVal / 100),
        weight: weight,
      ));
      total = newVal;
      time  = min(time + stepRatio, 1.0);
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
    final isWide = MediaQuery.of(context).size.width > 600;
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: Scaffold(
        backgroundColor: kSurface,
        body: Stack(
          children: [
            // Background glow
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

            // Branding cluster
            Center(
              child: AnimatedBuilder(
                animation: _floatAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(_parallax.dx, _floatAnim.value + _parallax.dy),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LogoWithRing(
                        pulseScale: _pulseScale,
                        pulseOpacity: _pulseOpacity,
                        logoSize: isWide ? 128.0 : 96.0,
                        iconSize: isWide ? 64.0  : 48.0,
                      ),
                      const SizedBox(height: 24),
                      Text('SuppleWise', style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isWide ? 24 : 22,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                        letterSpacing: -0.24,
                        height: 32 / 24,
                      )),
                      const SizedBox(height: 4),
                      Text('DECISION SUPPORT INTELLIGENCE', style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kOnSurfaceVariant.withOpacity(0.60),
                        letterSpacing: 2.4,
                        height: 16 / 12,
                      )),
                    ],
                  ),
                ),
              ),
            ),

            // Progress
            Positioned(
              bottom: 64, left: 0, right: 0,
              child: Column(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        width: 64, height: 4,
                        child: AnimatedBuilder(
                          animation: _progressAnim,
                          builder: (_, __) => Stack(children: [
                            Container(color: kSurfaceContainerHigh),
                            FractionallySizedBox(
                              widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                              child: Container(color: kPrimary),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Initializing Analytics...', style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: kOnSurfaceVariant.withOpacity(0.40),
                  )),
                ],
              ),
            ),

            // Bottom bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Opacity(
                      opacity: 0.10,
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics, color: Colors.white, size: 28),
                      ),
                    ),
                    Text('v.1.0.4 - STABLE', style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kOnSurfaceVariant.withOpacity(0.20),
                      letterSpacing: 0.6,
                    )),
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

// ──────────── Splash Helpers ────────────────────────────────────────────────
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
      width: logoSize * 2, height: logoSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([pulseScale, pulseOpacity]),
            builder: (_, __) => Transform.scale(
              scale: pulseScale.value,
              child: Container(
                width: logoSize, height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withOpacity(pulseOpacity.value),
                ),
              ),
            ),
          ),
          Container(
            width: logoSize, height: logoSize,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.20),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Icon(Icons.analytics, color: Colors.white, size: iconSize),
          ),
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double opacity;
  const _GlowPainter({required this.opacity});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint  = Paint()
      ..shader = RadialGradient(
        colors: [kPrimary.withOpacity(opacity), kPrimary.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }
  @override
  bool shouldRepaint(_GlowPainter old) => old.opacity != opacity;
}

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Entry animation
  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _entryFades;
  late final List<Animation<Offset>>  _entrySlides;

  static const int _sectionCount = 5; // header, button, grid, featured, bottom

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _entryFades  = List.generate(_sectionCount, (i) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(i * 0.12, (i * 0.12 + 0.4).clamp(0, 1), curve: Curves.easeOut),
      )),
    );
    _entrySlides = List.generate(_sectionCount, (i) =>
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(i * 0.12, (i * 0.12 + 0.4).clamp(0, 1), curve: Curves.easeOut),
        ),
      ),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(
      opacity: _entryFades[index],
      child: SlideTransition(position: _entrySlides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: kSurface,
      // ── Top App Bar ──────────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: kSurface,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: kSecondaryContainer,
                        child: Icon(Icons.person, color: kOnSecondaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('SuppleWise', style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                        letterSpacing: -0.22,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: mq.padding.bottom + 80, // space for bottom nav
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0 — Welcome
              _buildAnimated(0, _WelcomeSection()),
              const SizedBox(height: 24),

              // 1 — CTA Button
              _buildAnimated(1, _AddSupplierButton()),
              const SizedBox(height: 24),

              // 2 — Summary Grid
              _buildAnimated(2, _SummaryGrid()),
              const SizedBox(height: 24),

              // 3 — Featured Supplier
              _buildAnimated(3, _FeaturedSupplierSection()),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Welcome Section ──────────────────────────────────────────────────────────
class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Halo, Alex 👋', style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: kOnSurface,
          height: 36 / 28,
        )),
        const SizedBox(height: 4),
        Text('Pantau performa supplier Anda hari ini.', style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: kOnSurfaceVariant,
          height: 20 / 14,
        )),
      ],
    );
  }
}

// ─── Add Supplier Button ──────────────────────────────────────────────────────
class _AddSupplierButton extends StatefulWidget {
  @override
  State<_AddSupplierButton> createState() => _AddSupplierButtonState();
}
class _AddSupplierButtonState extends State<_AddSupplierButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: kOnPrimary, size: 22),
              SizedBox(width: 8),
              Text('Tambah Supplier', style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kOnPrimary,
                height: 28 / 20,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Summary Grid (2 cards) ───────────────────────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(
          icon: Icons.inventory_2_outlined,
          iconColor: kPrimary,
          iconBg: kPrimary.withOpacity(0.10),
          label: 'Total Supplier',
          value: '12',
        )),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(
          icon: Icons.rule_outlined,
          iconColor: kTertiary,
          iconBg: kTertiaryContainer.withOpacity(0.10),
          label: 'Kriteria Aktif',
          value: '5',
        )),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   label;
  final String   value;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant.withOpacity(0.30), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(label.toUpperCase(), style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kOnSurfaceVariant,
            letterSpacing: 0.6,
            height: 16 / 12,
          )),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: kOnSurface,
            letterSpacing: -0.24,
            height: 32 / 24,
          )),
        ],
      ),
    );
  }
}

// ─── Featured Supplier Section ────────────────────────────────────────────────
class _FeaturedSupplierSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Supplier Terbaik Saat Ini', style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kOnSurface,
              height: 28 / 20,
            )),
            GestureDetector(
              onTap: () {},
              child: const Text('Lihat Semua', style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kPrimary,
                letterSpacing: 0.6,
              )),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Featured card
        _FeaturedCard(),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative blob (top-right)

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rank badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('RANK #1', style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text('Global Logistics Co.', style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.24,
                          height: 32 / 24,
                        )),
                        const SizedBox(height: 4),
                        Text('Konsistensi pengiriman yang luar biasa.', style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.80),
                          height: 20 / 14,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('98.4', style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 36 / 28,
                      )),
                      Text('Decision Score', style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.70),
                        letterSpacing: 0.6,
                      )),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Divider
              Container(height: 1, color: Colors.white.withOpacity(0.10)),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _StatChip(icon: Icons.schedule_outlined, label: '99% On-time'),
                  const SizedBox(width: 16),
                  _StatChip(icon: Icons.verified_outlined, label: 'Verified Quality'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        )),
      ],
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int     currentIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.dashboard_outlined,   activeIcon: Icons.dashboard,       label: 'Dashboard'),
    (icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2,     label: 'Suppliers'),
    (icon: Icons.rule_outlined,        activeIcon: Icons.rule,            label: 'Criteria'),
    (icon: Icons.analytics_outlined,   activeIcon: Icons.analytics,       label: 'Results'),
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16,
        top: 8,
        bottom: mq.padding.bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item    = _items[i];
          final active  = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: active ? kPrimaryContainer.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? item.activeIcon : item.icon,
                    color: active ? kPrimary : kOnSecondaryContainer,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(item.label, style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? kPrimary : kOnSecondaryContainer,
                    letterSpacing: 0.6,
                  )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}