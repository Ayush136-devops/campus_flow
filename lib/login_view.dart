import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'campus_home.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  /// Logic to identify Student vs Teacher
  /// Students: contain 2+ digits (e.g., khatal24)
  /// Teachers: name.surname@vit.edu
  String getRoleFromEmail(String email) {
    RegExp studentRegex = RegExp(r'[a-zA-Z0-9._%+-]+[0-9]{2,}@vit\.edu');
    return studentRegex.hasMatch(email) ? 'student' : 'teacher';
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Validation Checks
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    if (!email.endsWith('@vit.edu')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please use your official @vit.edu email")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      // 2. Attempt Sign In
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      // 3. Fallback: If Sign In fails, attempt Sign Up (New User)
      try {
        final AuthResponse res = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (res.user != null) {
          // 4. Create Profile with the correct role
          final role = getRoleFromEmail(email);
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'email': email,
            'role': role,
          });
        }
      } catch (signupError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication Error: ${signupError.toString()}")),
        );
      }
    } finally {
      // 5. Navigate to Home if session is active
      if (supabase.auth.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CampusHome()),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Branding Section ---
              Icon(Icons.school_rounded, size: 80, color: Colors.indigo[900]),
              const SizedBox(height: 20),
              Text(
                "CAMPUS FLOW",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.indigo[900],
                ),
              ),
              const Text(
                "VIT Pune Portal",
                style: TextStyle(color: Colors.grey, letterSpacing: 1.2),
              ),
              const SizedBox(height: 50),

              // --- Input Section ---
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "College Email",
                  hintText: "name.surname24@vit.edu",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 35),

              // --- Button Section ---
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[900],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "LOGIN / SIGN UP",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Teachers will be automatically granted override access.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}