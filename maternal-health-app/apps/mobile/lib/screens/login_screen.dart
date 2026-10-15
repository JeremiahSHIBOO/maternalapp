import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'role_selection_screen.dart';

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
        Provider.google,
        redirectTo: 'com.matrucare.app:/callback',
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
              const TextField(
                decoration: InputDecoration(
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
              TextField(
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
              _isLoggingIn
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signIn,
                      child: const Text('Log In'),
                    ),
              const SizedBox(height: 16),
              _isSigningUp
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _signUp,
                      child: const Text('Create Account'),
                    ),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                leading: Icon(Icons.g_emoji, color: Colors.red),
                title: const Text('Continue with Google'),
                onTap: _signInWithGoogle,
              ),
              const SizedBox(height: 24),
              const Text(
                'Or continue as a guest',
                style: TextStyle(fontSize: 12, color: Color(0xFF880E4F)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Skip auth - go to role selection with demo data
                  Navigator.pushReplacementNamed(context, '/role-selection');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFDF9),
                  foregroundColor: Color(0xFF880E4F),
                  side: const Border(color: Color(0xFF880E4F)),
                ),
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}