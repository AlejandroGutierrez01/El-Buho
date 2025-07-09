import 'package:flutter/material.dart';
import './services/auth_service.dart';
import 'turismo_page.dart';

class LoginPage extends StatefulWidget {
  final String? mensajeInicial;
  const LoginPage({super.key, this.mensajeInicial});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  final primaryColor = const Color(0xFF43A047);
  final secondaryColor = const Color(0xFF64B5F6);
  final accentColor = const Color(0xFFFFD600);

  @override
  void initState() {
    super.initState();
    if (widget.mensajeInicial != null && widget.mensajeInicial!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(widget.mensajeInicial!)));
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success = false;
    String message = '';

    try {
      if (_isLogin) {
        success = await AuthService.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        message = success ? 'Login exitoso' : 'Error en las credenciales';
      } else {
        success = await AuthService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nombreController.text.trim(),
          'publicador',
        );
        message = success ? 'Registro exitoso' : 'Error en el registro';
      }

      if (success && mounted) {
        if (_isLogin) {
          await AuthService.refreshCurrentUser();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const TurismoPage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Registro exitoso. Revisa tu email antes de iniciar sesión.')));
          setState(() => _isLogin = true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAsGuest() async {
    setState(() => _isLoading = true);
    try {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const TurismoPage()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Imagen fondo difuminada
          SizedBox.expand(
            child: Image.network(
              "https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1350&q=80 ",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.35),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // Contenido
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'El Búho',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      shadows: const [
                        Shadow(color: Colors.black45, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLogin ? 'Iniciar Sesión' : 'Crear cuenta',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isLogin)
                            _customInput(
                              controller: _nombreController,
                              label: 'Nombre completo',
                              icon: Icons.person,
                              validator: (v) =>
                                  v!.isEmpty ? 'Ingrese su nombre' : null,
                            ),
                          const SizedBox(height: 16),
                          _customInput(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            validator: (v) {
                              if (v!.isEmpty) return 'Ingrese su email';
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _customInput(
                            controller: _passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock,
                            isPassword: true,
                            validator: (v) {
                              if (v!.isEmpty) return 'Ingrese su contraseña';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      _isLogin
                                          ? 'Iniciar Sesión'
                                          : 'Registrarse',
                                      style: const TextStyle(fontSize: 17, color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() => _isLogin = !_isLogin);
                                  },
                            child: Text(
                              _isLogin
                                  ? '¿No tienes cuenta? Regístrate'
                                  : '¿Ya tienes cuenta? Inicia sesión',
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginAsGuest,
                            icon: Icon(Icons.explore, color: primaryColor),
                            label: Text(
                              'Ingresar como visitante  ',
                              style: TextStyle(color: primaryColor),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _customInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
