import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Script de prueba para verificar la conexión a Firebase
class FirebaseTest {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ejecuta todas las pruebas de Firebase
  static Future<void> ejecutarPruebas() async {
    print('🧪 Iniciando pruebas de Firebase...');

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

      // 3. Verificar conexión a Firestore
      print('🔥 Probando conexión a Firestore...');
      final testQuery = await _firestore.collection('test').limit(1).get();
      print('✅ Conexión a Firestore exitosa');

      // 4. Verificar estructura de la base de datos
      await _verificarEstructuraBD();

      // 5. Verificar usuario de prueba
      await _verificarUsuarioPrueba();

      print('🎉 Todas las pruebas pasaron exitosamente');
    } catch (e) {
      print('❌ Error en las pruebas: $e');
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

      // Verificar colección Rol_Procurador
      final roles = await _firestore
          .collection('Rol_Procurador')
          .limit(1)
          .get();
      print('🎭 Colección Rol_Procurador: ${roles.docs.length} documentos');

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

  /// Verifica el usuario de prueba
  static Future<void> _verificarUsuarioPrueba() async {
    print('👤 Verificando usuario de prueba...');

    try {
      final query = await _firestore
          .collection('Procuradores')
          .where('usuario', isEqualTo: 'lowfrax')
          .where('password', isEqualTo: 'casa')
          .where('eliminado', isEqualTo: false)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        print('✅ Usuario encontrado:');
        print('   - ID: ${doc.id}');
        print('   - Nombre: ${data['nombre']}');
        print('   - Email: ${data['email']}');
        print('   - Rol ID: ${data['id_rol']}');

        // Verificar rol
        if (data['id_rol'] != null) {
          final rolDoc = await data['id_rol'].get();
          if (rolDoc.exists) {
            final rolData = rolDoc.data();
            print('   - Rol: ${rolData['rol']}');
            print('   - Rol eliminado: ${rolData['eliminado']}');
          }
        }
      } else {
        print('❌ Usuario de prueba no encontrado');
        print('🔧 Creando usuario de prueba...');
        await _crearUsuarioPrueba();
      }
    } catch (e) {
      print('❌ Error al verificar usuario: $e');
    }
  }

  /// Crea el usuario de prueba
  static Future<void> _crearUsuarioPrueba() async {
    try {
      // Crear rol de alumno si no existe
      final rolQuery = await _firestore
          .collection('Rol_Procurador')
          .where('rol', isEqualTo: 'alumno')
          .where('eliminado', isEqualTo: false)
          .get();

      DocumentReference? rolRef;

      if (rolQuery.docs.isEmpty) {
        print('➕ Creando rol de alumno...');
        final rolDoc = await _firestore.collection('Rol_Procurador').add({
          'rol': 'alumno',
          'eliminado': false,
          'creado_el': FieldValue.serverTimestamp(),
          'actualizado_el': FieldValue.serverTimestamp(),
        });
        rolRef = rolDoc;
        print('✅ Rol creado con ID: ${rolDoc.id}');
      } else {
        rolRef = rolQuery.docs.first.reference;
        print('✅ Rol existente encontrado: ${rolRef.id}');
      }

      // Crear usuario
      final usuarioDoc = await _firestore.collection('Procuradores').add({
        'nombre': 'Usuario de Prueba',
        'usuario': 'lowfrax',
        'password': 'casa',
        'email': 'lowfrax@test.com',
        'telefono': '123456789',
        'n_cuenta': '2023001',
        'id_rol': rolRef,
        'eliminado': false,
        'creado_el': FieldValue.serverTimestamp(),
        'actualizado_el': FieldValue.serverTimestamp(),
      });

      print('✅ Usuario creado con ID: ${usuarioDoc.id}');
      print('🎉 Usuario de prueba creado exitosamente');
    } catch (e) {
      print('❌ Error al crear usuario de prueba: $e');
    }
  }
}
