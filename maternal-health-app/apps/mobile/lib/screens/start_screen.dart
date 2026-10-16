import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_config.dart';
import 'login_screen.dart';
import '../services/profile_service.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return Scaffold(
        body: Center(
          child: _WelcomeShell(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const _BrandHeader(compact: true),
              const SizedBox(height: 24),
              Text('Connect your account',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                  'Add your Supabase project URL and public key to the .env file, then restart the app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
        ),
      );
    }

    final user = Supabase.instance.client.auth.currentSession?.user;

    if (user != null) {
      return const _SessionHome();
    }

    // Show the welcome screen to unauthenticated users.
    return Scaffold(
      body: _WelcomeShell(
        child: _WelcomeContent(
          onGetStarted: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ),
    );
  }
}

class _SessionHome extends StatefulWidget {
  const _SessionHome();
  @override
  State<_SessionHome> createState() => _SessionHomeState();
}

class _SessionHomeState extends State<_SessionHome> {
  String? _error;
  @override
  void initState() {
    super.initState();
    _openHome();
  }

  Future<void> _openHome() async {
    setState(() => _error = null);
    try {
      final route = await ProfileService.homeRoute();
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'We couldn’t load your account. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(
                      onPressed: _openHome, child: const Text('Try again'))
                ],
              ),
      ));
}

class _WelcomeShell extends StatelessWidget {
  final Widget child;
  const _WelcomeShell({required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: LayoutBuilder(builder: (context, viewport) {
          final compact = viewport.maxWidth < 760;
          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(compact ? 26 : 34),
                    border: Border.all(color: const Color(0xFFECE4E5)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x1470445E),
                          blurRadius: 42,
                          offset: Offset(0, 20))
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(builder: (context, cardConstraints) {
                    final narrow = cardConstraints.maxWidth < 760;
                    if (narrow) {
                      return Column(mainAxisSize: MainAxisSize.min, children: [
                        const _BrandHeader(compact: true),
                        const _WelcomeArtwork(height: 220),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(28, 30, 28, 32),
                            child: child),
                      ]);
                    }
                    return IntrinsicHeight(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(64, 54, 52, 54),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _BrandHeader(),
                                      const SizedBox(height: 72),
                                      child,
                                      const Spacer(),
                                      const SizedBox(height: 36),
                                      Text('PREGNANCY  ·  BIRTH  ·  POSTPARTUM',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color:
                                                      const Color(0xFF8B6B7D),
                                                  letterSpacing: 1.3)),
                                    ]),
                              ),
                            ),
                            const Expanded(child: _WelcomeArtwork(height: 620)),
                          ]),
                    );
                  }),
                ),
              ),
            ),
          );
        }),
      );
}

class _WelcomeContent extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _WelcomeContent({required this.onGetStarted});

  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('A LITTLE MORE SUPPORT FOR EVERY STEP',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8B6B7D), letterSpacing: 1.1)),
            const SizedBox(height: 14),
            Text('Your journey,\nsupported.',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 42, height: 1.08)),
            const SizedBox(height: 16),
            Text(
                'Gentle tools for pregnancy and postpartum, with space to care for yourself along the way.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: const Color(0xFF6E626B))),
            const SizedBox(height: 26),
            const _WelcomeBenefit(
                icon: Icons.favorite_border,
                label: 'Check in with your wellbeing'),
            const SizedBox(height: 13),
            const _WelcomeBenefit(
                icon: Icons.spa_outlined,
                label: 'Follow your pregnancy week by week'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGetStarted,
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                iconAlignment: IconAlignment.end,
                label: const Text('Get started'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 58),
                    alignment: Alignment.center),
              ),
            ),
            const SizedBox(height: 12),
            Center(
                child: Text('A private space for your care journey',
                    style: Theme.of(context).textTheme.bodySmall)),
          ]);
}

class _BrandHeader extends StatelessWidget {
  final bool compact;
  const _BrandHeader({this.compact = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            compact ? 24 : 0, compact ? 22 : 0, compact ? 24 : 0, 0),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFF3E8ED),
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.spa_outlined,
                color: Color(0xFF70445E), size: 23),
          ),
          const SizedBox(width: 11),
          Text('MatruCare',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20, letterSpacing: -0.4)),
        ]),
      );
}

class _WelcomeBenefit extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WelcomeBenefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFFF7F0F2),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF70445E), size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontSize: 14))),
      ]);
}

class _WelcomeArtwork extends StatelessWidget {
  final double height;
  const _WelcomeArtwork({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8EDEF),
                Color(0xFFF2E8E9),
                Color(0xFFE8EFEB)
              ]),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
              top: 30,
              right: 36,
              child: Icon(Icons.auto_awesome,
                  size: 19, color: const Color(0xFFB08A9D).withOpacity(0.75))),
          Positioned(
              left: 34,
              bottom: 38,
              child: Icon(Icons.auto_awesome,
                  size: 14, color: const Color(0xFFB08A9D).withOpacity(0.7))),
          Positioned(
              left: 70,
              top: 68,
              child: Icon(Icons.circle,
                  size: 9, color: const Color(0xFFE1B3A8).withOpacity(0.7))),
          const CustomPaint(
              size: Size(390, 420), painter: _MotherBabyPainter()),
          Positioned(
            left: 28,
            right: 28,
            bottom: 22,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white)),
                child: Text('Here for every version of you',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF70445E),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      );
}

class _MotherBabyPainter extends CustomPainter {
  const _MotherBabyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 - 12);

    canvas.drawCircle(
        const Offset(0, 3), 146, Paint()..color = const Color(0x33FFFFFF));
    canvas.drawCircle(
        const Offset(0, 3), 125, Paint()..color = const Color(0x22D8B7C5));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 133), width: 190, height: 24),
        Paint()..color = const Color(0x2270445E));

    final hair = Paint()
      ..shader = const RadialGradient(
              center: Alignment(-0.5, -0.6),
              colors: [Color(0xFF8D6279), Color(0xFF5F4058), Color(0xFF493447)])
          .createShader(
              Rect.fromCircle(center: const Offset(-22, -50), radius: 105));
    canvas.drawCircle(const Offset(-22, -50), 78, hair);

    final skin = Paint()
      ..shader = const RadialGradient(
              center: Alignment(-0.5, -0.6),
              colors: [Color(0xFFFFE5D4), Color(0xFFF5C5B0), Color(0xFFE7A58F)])
          .createShader(
              Rect.fromCircle(center: const Offset(-20, -55), radius: 65));
    canvas.drawCircle(const Offset(-20, -55), 60, skin);

    final hairFront = Path()
      ..moveTo(-78, -68)
      ..cubicTo(-65, -130, 8, -139, 37, -91)
      ..cubicTo(8, -105, -3, -84, -34, -88)
      ..cubicTo(-50, -80, -60, -68, -78, -68)
      ..close();
    canvas.drawPath(hairFront, Paint()..color = const Color(0xFF64465D));

    final robe = Path()
      ..moveTo(-86, 135)
      ..cubicTo(-91, 61, -72, 5, -27, -2)
      ..cubicTo(23, -11, 77, 44, 89, 135)
      ..close();
    final robePaint = Paint()
      ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9B6D86), Color(0xFF70445E), Color(0xFF573A50)])
          .createShader(Rect.fromLTWH(-95, -5, 190, 145));
    canvas.drawShadow(robe, const Color(0x3370445E), 12, false);
    canvas.drawPath(robe, robePaint);

    final babyBody = Paint()
      ..shader = const RadialGradient(
              center: Alignment(-0.4, -0.5),
              colors: [Color(0xFFFFE8D9), Color(0xFFF4C1AC), Color(0xFFD98985)])
          .createShader(Rect.fromLTWH(-16, 5, 112, 112));
    final babyShape = Path()
      ..moveTo(16, 14)
      ..cubicTo(62, -1, 97, 28, 85, 75)
      ..cubicTo(80, 106, 48, 119, 18, 98)
      ..cubicTo(-5, 82, -8, 40, 16, 14)
      ..close();
    canvas.drawShadow(babyShape, const Color(0x3370445E), 8, false);
    canvas.drawPath(babyShape, babyBody);
    canvas.drawCircle(const Offset(41, 18), 35, babyBody);
    canvas.drawCircle(
        const Offset(29, 5), 9, Paint()..color = const Color(0x55FFFFFF));

    final babyFace = Paint()..color = const Color(0xFF70445E);
    canvas.drawCircle(const Offset(31, 17), 2.1, babyFace);
    canvas.drawCircle(const Offset(52, 17), 2.1, babyFace);
    final smile = Path()
      ..moveTo(35, 27)
      ..quadraticBezierTo(42, 34, 49, 27);
    canvas.drawPath(
        smile,
        Paint()
          ..color = const Color(0xFFB46D70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        const Offset(25, 28), 4, Paint()..color = const Color(0x66E88E8C));
    canvas.drawCircle(
        const Offset(57, 28), 4, Paint()..color = const Color(0x66E88E8C));

    final embrace = Path()
      ..moveTo(-58, 49)
      ..cubicTo(-15, 91, 29, 100, 76, 72);
    canvas.drawPath(
        embrace,
        Paint()
          ..color = const Color(0xFFF3BFAE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 19
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        const Offset(77, 72), 10, Paint()..color = const Color(0xFFFFD4C0));

    final leaf = Paint()..color = const Color(0xFF789080);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-105, 36), width: 24, height: 11),
        leaf..style = PaintingStyle.fill);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-113, 22), width: 20, height: 9),
        Paint()..color = const Color(0xFF91A496));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MotherBabyPainter oldDelegate) => false;
}
