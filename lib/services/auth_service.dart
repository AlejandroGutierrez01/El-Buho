import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  
  static User? get currentUser => _supabase.auth.currentUser;
  
  static bool get isAuthenticated => currentUser != null;
  
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isAuthenticated) return null;
    
    try {
      print('Debug - Buscando perfil para ID: ${currentUser!.id}');
      
      final response = await _supabase
          .from('turismo_perfiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      
      print('Debug - Perfil encontrado: $response');
      return response;
    } catch (e) {
      print('Error obteniendo perfil: $e');
      
      // Intentar buscar todos los perfiles para debug
      try {
        final allProfiles = await _supabase
            .from('turismo_perfiles')
            .select();
        print('Debug - Todos los perfiles en la tabla: $allProfiles');
      } catch (debugError) {
        print('Debug - Error al consultar todos los perfiles: $debugError');
      }
      
      return null;
    }
  }
  
  // Verificar si el usuario tiene rol de publicador
  static Future<bool> isPublisher() async {
    final profile = await getUserProfile();
    return profile?['rol'] == 'publicador';
  }
  
  // Verificar si el usuario es visitante
  static Future<bool> isVisitor() async {
    // Si no está autenticado, es visitante
    if (!isAuthenticated) return true;

    final profile = await getUserProfile();
    return profile?['rol'] == 'visitante' || profile == null;
  }
  
  // Login con email/password
  static Future<bool> loginWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }
  
  // Registro con trigger automático
  static Future<bool> signUp(String email, String password, String nombre, String rol) async {
  try {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Crear perfil manualmente (opcional, solo si quieres crearlo antes de confirmar)
      final profileData = {
        'id': response.user!.id,
        'email': email,
        'nombre': nombre,
        'rol': rol,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('turismo_perfiles')
          .insert(profileData);

      print('Usuario registrado correctamente: $email');
      return true;
    }

    return false;
  } catch (e) {
    print('Error en registro: $e');
    return false;
  }
}

  
  // Crear perfil manualmente si no existe
  static Future<bool> createUserProfile(String nombre, String rol) async {
    if (!isAuthenticated) return false;
    
    try {
      final profileData = {
        'id': currentUser!.id,
        'email': currentUser!.email!,
        'nombre': nombre,
        'rol': rol,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      print('Debug - Creando perfil: $profileData');
      
      await _supabase
          .from('turismo_perfiles')
          .insert(profileData);
      
      print('Debug - Perfil creado exitosamente');
      return true;
    } catch (e) {
      print('Error creando perfil: $e');
      return false;
    }
  }
static Future<void> refreshCurrentUser() async {
  try {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _supabase.auth.refreshSession();
    }

    final user = _supabase.auth.currentUser;
    if (user != null) {
      print('Debug - Usuario refrescado: ${user.email}');
    } else {
      print('Debug - No se pudo refrescar usuario');
    }

    final perfil = await getUserProfile();
    print('Debug - Perfil refrescado: $perfil');
  } catch (e) {
    print('Error refrescando usuario: $e');
  }
}

  // Logout
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
