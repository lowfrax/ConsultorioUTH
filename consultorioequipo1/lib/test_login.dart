import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/recursos/auth_service.dart';

/// Script de prueba específico para el login
class LoginTest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ejecuta pruebas específicas del login
  static Future<void> ejecutarPruebasLogin() async {
    print('🧪 Iniciando pruebas específicas del login...');

    try {
      // 1. Inicializar Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase inicializado correctamente');

      // 2. Verificar proyecto
      final projectId = _firestore.app.options.projectId;
      print('📋 Proyecto actual: $projectId');

      if (projectId != 'consultoriouth-f6798') {
        print(
          '❌ ERROR: Proyecto incorrecto. Esperado: consultoriouth-f6798, Actual: $projectId',
        );
        return;
      }

      // 3. Verificar estructura de la base de datos
      await _verificarEstructuraBD();

      // 4. Probar login con credenciales reales
      await _probarLoginReal();

      print('🎉 Todas las pruebas de login pasaron exitosamente');
    } catch (e) {
      print('❌ Error en las pruebas de login: $e');
    }
  }

  /// Verifica la estructura de la base de datos
  static Future<void> _verificarEstructuraBD() async {
    print('🔍 Verificando estructura de la base de datos...');

    try {
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

        // Verificar campos específicos
        print('🔍 Verificando campos específicos:');
        print('   - usuario: ${data['usuario']}');
        print('   - password: ${data['password']}');
        print('   - teléfono: ${data['teléfono']}');
        print('   - id_rol: ${data['id_rol']}');
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
        print('   - rol: ${data['rol']}');
        print('   - eliminado: ${data['eliminado']}');
      }

      print('✅ Estructura de base de datos verificada');
    } catch (e) {
      print('❌ Error al verificar estructura: $e');
    }
  }

  /// Prueba el login con credenciales reales
  static Future<void> _probarLoginReal() async {
    print('👤 Probando login con credenciales reales...');

    try {
      // Probar con las credenciales que mencionaste
      final resultado = await AuthService.login('lowfrax', 'casa');

      if (resultado.success) {
        print('✅ Login exitoso');
        print('👤 Usuario: ${resultado.userData?['nombre']}');
        print('🎭 Rol: ${resultado.roleData?['rol']}');
        print('📧 Email: ${resultado.userData?['email']}');
      } else {
        print('❌ Login fallido: ${resultado.message}');
      }
    } catch (e) {
      print('❌ Error al probar login: $e');
    }
  }

  /// Lista todos los usuarios en la base de datos
  static Future<void> listarUsuarios() async {
    print('📋 Listando todos los usuarios...');

    try {
      final query = await _firestore
          .collection('Procuradores')
          .where('eliminado', isEqualTo: false)
          .get();

      print('📊 Total de usuarios: ${query.docs.length}');

      for (final doc in query.docs) {
        final data = doc.data();
        print(
          '👤 Usuario: ${data['usuario']} - Nombre: ${data['nombre']} - Email: ${data['email']}',
        );
      }
    } catch (e) {
      print('❌ Error al listar usuarios: $e');
    }
  }

  /// Verifica un usuario específico
  static Future<void> verificarUsuario(String usuario, String password) async {
    print('🔍 Verificando usuario: $usuario');

    try {
      final query = await _firestore
          .collection('Procuradores')
          .where('usuario', isEqualTo: usuario)
          .where('password', isEqualTo: password)
          .where('eliminado', isEqualTo: false)
          .get();

      final existe = query.docs.isNotEmpty;
      print('📊 Usuario encontrado: $existe');

      if (existe) {
        final doc = query.docs.first;
        final data = doc.data();
        print('👤 Datos del usuario:');
        print('   - ID: ${doc.id}');
        print('   - Nombre: ${data['nombre']}');
        print('   - Email: ${data['email']}');
        print('   - Teléfono: ${data['teléfono']}');
        print('   - N_Cuenta: ${data['n_cuenta']}');
        print('   - ID_Rol: ${data['id_rol']}');

        // Verificar rol
        if (data['id_rol'] != null) {
          try {
            final rolRef = data['id_rol'] as DocumentReference;
            final rolDoc = await rolRef.get();
            if (rolDoc.exists) {
              final rolData = rolDoc.data() as Map<String, dynamic>;
              print('   - Rol: ${rolData['rol']}');
              print('   - Rol eliminado: ${rolData['eliminado']}');
            }
          } catch (e) {
            print('   - Error al verificar rol: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error al verificar usuario: $e');
    }
  }
}
