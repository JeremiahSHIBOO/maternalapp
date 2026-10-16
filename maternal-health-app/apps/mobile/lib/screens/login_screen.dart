import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoggingIn = false;
  bool _isSigningUp = false;
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoggingIn = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Remove the welcome/login routes so Back cannot return to the
      // unauthenticated flow after sign-in.
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/role-selection',
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSigningUp = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _emailController.text.trim().split('@').first},
      );
      // Sign up success - may need email verification
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Account created! Please check email for verification.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        // Browser OAuth must return to the current web origin. The app URI
        // scheme is reserved for native deep-link callbacks.
        redirectTo: kIsWeb
            ? Uri.base.origin
            : 'com.matrucare.app://login-callback',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign In Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: LayoutBuilder(builder: (context, viewport) {
        final compact = viewport.maxWidth < 760;
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 14 : 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 24 : 32),
                  border: Border.all(color: const Color(0xFFECE4E5)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1470445E),
                        blurRadius: 40,
                        offset: Offset(0, 18))
                  ],
                ),
                child: LayoutBuilder(builder: (context, card) {
                  final narrow = card.maxWidth < 760;
                  if (narrow) {
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      const _LoginArtwork(height: 190),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
                          child: _buildForm(context)),
                    ]);
                  }
                  return IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(58, 54, 58, 54),
                                  child: _buildForm(context))),
                          const Expanded(child: _LoginArtwork(height: 620)),
                        ]),
                  );
                }),
              ),
            ),
          ),
        );
      })),
    );
  }

  Widget _buildForm(BuildContext context) => Form(
        key: _formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFFF3E8ED),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.spa_outlined,
                    color: Color(0xFF70445E), size: 22)),
            const SizedBox(width: 10),
            Text('MatruCare',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 20)),
          ]),
          const SizedBox(height: 38),
          Text(_isSignUpMode ? 'Create your account' : 'Welcome back',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            _isSignUpMode
                ? 'A more supported pregnancy starts here.'
                : 'Sign in to continue your care journey.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
            obscureText: true,
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your password';
              if (value.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoggingIn || _isSigningUp
                  ? null
                  : (_isSignUpMode ? _signUp : _signIn),
              child: _isLoggingIn || _isSigningUp
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                      const SizedBox(width: 10),
                      Text(_isSignUpMode ? 'Creating account…' : 'Signing in…'),
                    ])
                  : Text(_isSignUpMode ? 'Create account' : 'Sign in'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: (_isLoggingIn || _isSigningUp)
                ? null
                : () => setState(() => _isSignUpMode = !_isSignUpMode),
            child: Text(_isSignUpMode
                ? 'Already registered?  Sign in'
                : 'New to MatruCare?  Create an account'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child:
                    Text('OR', style: Theme.of(context).textTheme.labelSmall)),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 25),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
          ),
        ]),
      );
}

class _LoginArtwork extends StatelessWidget {
  final double height;
  const _LoginArtwork({required this.height});

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
            ])),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
              top: 25,
              right: 32,
              child: Icon(Icons.auto_awesome,
                  color: const Color(0xFFB08A9D).withOpacity(0.7))),
          Positioned(
              left: 28,
              bottom: 32,
              child: Icon(Icons.auto_awesome,
                  size: 16, color: const Color(0xFFB08A9D).withOpacity(0.7))),
          const CustomPaint(
              size: Size(390, 420), painter: _LoginMotherBabyPainter()),
          Positioned(
              bottom: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.84),
                    borderRadius: BorderRadius.circular(30)),
                child: Text('Care for you, through every change',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF70445E),
                        fontWeight: FontWeight.w600)),
              )),
        ]),
      );
}

class _LoginMotherBabyPainter extends CustomPainter {
  const _LoginMotherBabyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 - 12);
    canvas.drawCircle(
        const Offset(0, 0), 145, Paint()..color = const Color(0x33FFFFFF));
    canvas.drawCircle(
        const Offset(0, 0), 124, Paint()..color = const Color(0x22D8B7C5));
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
    final babyPaint = Paint()
      ..shader = const RadialGradient(
              center: Alignment(-0.4, -0.5),
              colors: [Color(0xFFFFE8D9), Color(0xFFF4C1AC), Color(0xFFD98985)])
          .createShader(Rect.fromLTWH(-16, 5, 112, 112));
    final baby = Path()
      ..moveTo(16, 14)
      ..cubicTo(62, -1, 97, 28, 85, 75)
      ..cubicTo(80, 106, 48, 119, 18, 98)
      ..cubicTo(-5, 82, -8, 40, 16, 14)
      ..close();
    canvas.drawShadow(baby, const Color(0x3370445E), 8, false);
    canvas.drawPath(baby, babyPaint);
    canvas.drawCircle(const Offset(41, 18), 35, babyPaint);
    final face = Paint()..color = const Color(0xFF70445E);
    canvas.drawCircle(const Offset(31, 17), 2.1, face);
    canvas.drawCircle(const Offset(52, 17), 2.1, face);
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoginMotherBabyPainter oldDelegate) => false;
}
