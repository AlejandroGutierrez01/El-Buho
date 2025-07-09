import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'turismo_page.dart';
import 'services/auth_service.dart';
import 'login_page.dart';

void main() {
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
      home: const InitializationWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitializationWrapper extends StatefulWidget {
  const InitializationWrapper({super.key});

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Supabase.initialize(
        url: 'https://dnzyanqetjiaqonvbxlt.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuenlhbnFldGppYXFvbnZieGx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NTkyNDksImV4cCI6MjA2NDAzNTI0OX0.qC--HY4ccGNQ1rw0RFl61-6iSeuubGjGiT_gdsEx0X0');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error inicializando Supabase: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando aplicación...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error de conexión'),
              Text('Usando modo offline'),
            ],
          ),
        ),
      );
    }

    return const AuthWrapper();
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