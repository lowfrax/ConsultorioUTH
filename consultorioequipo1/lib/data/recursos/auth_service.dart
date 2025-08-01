import 'package:cloud_firestore/cloud_firestore.dart';

/// Resultado de la autenticación con validación de rol
class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? roleData;

  AuthResult({
    required this.success,
    this.message,
    this.userData,
    this.roleData,
  });
}

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variable global para mantener el procurador actual
  static Map<String, dynamic>? _procuradorActual;

  /// Obtiene el procurador actual
  static Map<String, dynamic>? get procuradorActual => _procuradorActual;

  /// Establece el procurador actual
  static void setProcuradorActual(Map<String, dynamic> procurador) {
    _procuradorActual = procurador;
  }

  /// Limpia el procurador actual (para logout)
  static void limpiarProcuradorActual() {
    _procuradorActual = null;
  }

  /// Autentica un usuario verificando credenciales y rol de alumno
  static Future<AuthResult> login(String usuario, String password) async {
    try {
      print('🔐 Iniciando proceso de autenticación...');
      print('👤 Usuario: $usuario');

      // 1. Buscar el procurador por usuario y password
      final procuradorQuery = await _firestore
          .collection('Procuradores')
          .where('usuario', isEqualTo: usuario)
          .where('password', isEqualTo: password)
          .where('eliminado', isEqualTo: false)
          .get();

      if (procuradorQuery.docs.isEmpty) {
        print(
          '❌ No se encontró procurador con las credenciales proporcionadas',
        );
        return AuthResult(
          success: false,
          message: 'Usuario o contraseña incorrectos',
        );
      }

      final procuradorDoc = procuradorQuery.docs.first;
      final userData = {
        ...procuradorDoc.data(),
        'id': procuradorDoc.id, // 👈 Add this line
      };

      print('✅ Usuario encontrado:');
      print('   - ID: ${procuradorDoc.id}');
      print('   - Nombre: ${userData['nombre']}');
      print('   - Email: ${userData['email']}');
      print('   - Usuario: ${userData['usuario']}');
      print('   - ID Rol: ${userData['id_rol']}');

      // 2. Verificar que tenga un rol asignado
      if (userData['id_rol'] == null) {
        print('❌ El procurador no tiene rol asignado');
        return AuthResult(success: false, message: 'Usuario sin rol asignado');
      }

      // 3. Obtener y verificar el rol
      try {
        final rolRef = userData['id_rol'] as DocumentReference;
        final rolDoc = await rolRef.get();

        if (!rolDoc.exists) {
          print('❌ El rol referenciado no existe');
          return AuthResult(success: false, message: 'Rol no encontrado');
        }

        final roleData = rolDoc.data() as Map<String, dynamic>;
        print('🎭 Rol encontrado:');
        print('   - ID: ${rolDoc.id}');
        print('   - Rol: ${roleData['rol']}');
        print('   - Eliminado: ${roleData['eliminado']}');

        // 4. Verificar que el rol no esté eliminado
        if (roleData['eliminado'] == true) {
          print('❌ El rol está marcado como eliminado');
          return AuthResult(success: false, message: 'Rol deshabilitado');
        }

        // 5. Verificar que el rol sea "alumno"
        if (roleData['rol'] != 'alumno') {
          print('❌ El rol no es "alumno": ${roleData['rol']}');
          return AuthResult(
            success: false,
            message: 'Acceso denegado: Solo alumnos pueden acceder',
          );
        }

        print('🎉 Autenticación exitosa');
        print('👤 Usuario: ${userData['nombre']}');
        print('🎭 Rol: ${roleData['rol']}');
        print('📧 Email: ${userData['email']}');

        // Guardar el procurador actual
        setProcuradorActual(userData);

        return AuthResult(
          success: true,
          message: 'Autenticación exitosa',
          userData: userData,
          roleData: roleData,
        );
      } catch (e) {
        print('❌ Error al verificar rol: $e');
        return AuthResult(
          success: false,
          message: 'Error al verificar rol. Intenta nuevamente.',
        );
      }
    } catch (e) {
      print('💥 Error durante la autenticación: $e');
      return AuthResult(
        success: false,
        message: 'Error de conexión. Intenta nuevamente.',
      );
    }
  }

  /// Verifica si un usuario existe
  static Future<bool> usuarioExiste(String usuario) async {
    try {
      final query = await _firestore
          .collection('Procuradores')
          .where('usuario', isEqualTo: usuario)
          .where('eliminado', isEqualTo: false)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar usuario: $e');
      return false;
    }
  }

  /// Obtiene información del procurador por ID
  static Future<Map<String, dynamic>?> obtenerProcuradorPorId(String id) async {
    try {
      final doc = await _firestore.collection('Procuradores').doc(id).get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener procurador: $e');
      return null;
    }
  }

  /// Verifica la estructura de la base de datos
  static Future<void> verificarEstructuraBD() async {
    try {
      print('🔍 Verificando estructura de la base de datos...');

      // Verificar colección Procuradores
      final procuradores = await _firestore
          .collection('Procuradores')
          .limit(1)
          .get();
      print(
        '📋 Colección Procuradores: ${procuradores.docs.length} documentos',
      );

      if (procuradores.docs.isNotEmpty) {
        final data = procuradores.docs.first.data();
        print('📊 Campos del procurador:');
        data.keys.forEach(
          (key) => print('   - $key: ${data[key].runtimeType}'),
        );
      }

      // Verificar colección Rol_Procurador
      final roles = await _firestore
          .collection('Rol_Procurador')
          .limit(1)
          .get();
      print('🎭 Colección Rol_Procurador: ${roles.docs.length} documentos');

      if (roles.docs.isNotEmpty) {
        final data = roles.docs.first.data();
        print('📊 Campos del rol:');
        data.keys.forEach(
          (key) => print('   - $key: ${data[key].runtimeType}'),
        );
      }

      // Verificar colección Clase
      final clases = await _firestore.collection('Clase').limit(1).get();
      print('📚 Colección Clase: ${clases.docs.length} documentos');

      // Verificar colección Cuatrimestres
      final cuatrimestres = await _firestore
          .collection('Cuatrimestres')
          .limit(1)
          .get();
      print(
        '📅 Colección Cuatrimestres: ${cuatrimestres.docs.length} documentos',
      );

      print('✅ Estructura de base de datos verificada');
    } catch (e) {
      print('❌ Error al verificar estructura: $e');
    }
  }
}
