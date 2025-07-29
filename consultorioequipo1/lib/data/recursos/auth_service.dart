import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/procurador.dart';
import '../modelos/rol_procurador.dart';

/// Resultado de la autenticación
class AuthResult {
  final bool success;
  final String? message;
  final Procurador? procurador;
  final RolProcurador? rol;

  AuthResult({required this.success, this.message, this.procurador, this.rol});
}

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Autentica un usuario verificando credenciales y rol
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
      final procurador = Procurador.fromFirestore(procuradorDoc);

      print('✅ Procurador encontrado: ${procurador.nombre}');
      print('📋 ID del procurador: ${procurador.id}');

      // 2. Verificar que el procurador no esté eliminado
      if (procurador.eliminado) {
        print('❌ El procurador está marcado como eliminado');
        return AuthResult(success: false, message: 'Cuenta deshabilitada');
      }

      // 3. Verificar que tenga un rol asignado
      if (procurador.idRol == null) {
        print('❌ El procurador no tiene rol asignado');
        return AuthResult(success: false, message: 'Usuario sin rol asignado');
      }

      // 4. Obtener y verificar el rol
      final rolDoc = await procurador.idRol!.get();

      if (!rolDoc.exists) {
        print('❌ El rol referenciado no existe');
        return AuthResult(success: false, message: 'Rol no encontrado');
      }

      final rol = RolProcurador.fromFirestore(rolDoc);
      print('🎭 Rol encontrado: ${rol.rol}');

      // 5. Verificar que el rol no esté eliminado
      if (rol.eliminado) {
        print('❌ El rol está marcado como eliminado');
        return AuthResult(success: false, message: 'Rol deshabilitado');
      }

      // 6. Verificar que el rol sea "alumno"
      if (rol.rol.toLowerCase() != 'alumno') {
        print('❌ El rol no es "alumno": ${rol.rol}');
        return AuthResult(
          success: false,
          message: 'Acceso denegado: Solo alumnos pueden acceder',
        );
      }

      print('🎉 Autenticación exitosa');
      print('👤 Usuario: ${procurador.nombre}');
      print('🎭 Rol: ${rol.rol}');
      print('📧 Email: ${procurador.email}');

      return AuthResult(
        success: true,
        message: 'Autenticación exitosa',
        procurador: procurador,
        rol: rol,
      );
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
  static Future<Procurador?> obtenerProcuradorPorId(String id) async {
    try {
      final doc = await _firestore.collection('Procuradores').doc(id).get();

      if (doc.exists) {
        return Procurador.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener procurador: $e');
      return null;
    }
  }

  /// Obtiene el rol de un procurador
  static Future<RolProcurador?> obtenerRolProcurador(
    DocumentReference rolRef,
  ) async {
    try {
      final doc = await rolRef.get();

      if (doc.exists) {
        return RolProcurador.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener rol: $e');
      return null;
    }
  }
}
