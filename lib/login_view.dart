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
  bool _isPasswordVisible = false;

  String getRoleFromEmail(String email) {
    RegExp studentRegex = RegExp(r'[a-zA-Z0-9._%+-]+[0-9]{2,}@vit\.edu');
    return studentRegex.hasMatch(email) ? 'student' : 'teacher';
  }

  Future _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter both email and password")));
      return;
    }

    if (!email.endsWith('@vit.edu')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please use your official @vit.edu email")));
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      try {
        final AuthResponse res = await supabase.auth.signUp(email: email, password: password);
        if (res.user != null) {
          final role = getRoleFromEmail(email);
          await supabase.from('profiles').upsert({'id': res.user!.id, 'email': email, 'role': role});
        }
      } catch (signupError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Authentication Error: ${signupError.toString()}")));
      }
    } finally {
      if (supabase.auth.currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CampusHome()));
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(45),
                child: Image.asset(
                  'assets/logo.png',
                  height: 180,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 80),


              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: "Username",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
              ),
              const SizedBox(height: 20),


              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
              ),
              const SizedBox(height: 25),

              // Login Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0), // Matching your UI
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 30),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Teachers will be automatically granted override access.",
                  style: TextStyle(
                      color: Color(0xFF5C6BC0),
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),

              const SizedBox(height: 50),
              const Text("Powered By EduplusCampus", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}