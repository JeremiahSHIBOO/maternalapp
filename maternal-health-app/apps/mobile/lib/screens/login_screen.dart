import 'package:flutter/material.dart';
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
      // Auth success - navigate to role selection
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/role-selection');
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
        const SnackBar(content: Text('Account created! Please check email for verification.')),
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
        redirectTo: 'com.matrucare.app://login-callback',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.pregnant_woman,
                size: 80,
                color: Color(0xFF880E4F),
              ),
              const SizedBox(height: 24),
              const Text(
                'MatruCare',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF880E4F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pregnancy & Postpartum Companion',
                style: TextStyle(fontSize: 16, color: Color(0xFFAD1457)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoggingIn || _isSigningUp
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isSignUpMode ? _signUp : _signIn,
                      child: Text(_isSignUpMode ? 'Create Account' : 'Log In'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_isLoggingIn || _isSigningUp)
                    ? null
                    : () => setState(() => _isSignUpMode = !_isSignUpMode),
                child: Text(_isSignUpMode ? 'Already registered? Log in' : 'Create Account'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.g_mobiledata, color: Colors.red),
                title: const Text('Continue with Google'),
                onTap: _signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
