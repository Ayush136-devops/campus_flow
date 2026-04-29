import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'campus_home.dart';
import 'login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gwjgsyntshauqtfbprnt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3amdzeW50c2hhdXF0ZmJwcm50Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5Nzg4MjEsImV4cCI6MjA5MTU1NDgyMX0.7fabaDAGAFPN0pRn42ZxcbsCWvGq_Cr2HzXt9Ec-lBg',
  );

  runApp(const CampusFlowApp());
}

final supabase = Supabase.instance.client;

class CampusFlowApp extends StatelessWidget {
  const CampusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Flow',
      theme: ThemeData(
        useMaterial3: true,
        // Updated Primary Color to Deep Blue
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
      ),
      home: supabase.auth.currentUser == null
          ? const LoginView()
          : const CampusHome(),
    );
  }
}