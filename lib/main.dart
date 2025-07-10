import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'turismo_page.dart';
import 'services/auth_service.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '',
    anonKey: ''
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sitios Turísticos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      print('Error configurando listener: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final bool isAuthenticated = AuthService.isAuthenticated;

      if (isAuthenticated) {
        return const TurismoPage();
      } else {
        return const LoginPage();
      }
    } catch (e) {
      return const LoginPage();
    }
  }
}
