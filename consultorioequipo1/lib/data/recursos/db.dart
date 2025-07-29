import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Clase para manejar la base de datos local y verificar datos de Firebase
class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica si el usuario existe en la base de datos
  static Future<bool> verificarUsuario(String usuario, String password) async {
    try {
      print('🔍 Verificando usuario: $usuario');

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
        print('👤 Datos del usuario:');
        print('   - ID: ${doc.id}');
        print('   - Nombre: ${doc.data()['nombre']}');
        print('   - Email: ${doc.data()['email']}');
        print('   - Rol ID: ${doc.data()['id_rol']}');
      }

      return existe;
    } catch (e) {
      print('❌ Error al verificar usuario: $e');
      return false;
    }
  }

  /// Lista todos los usuarios en la base de datos
  static Future<void> listarUsuarios() async {
    try {
      print('📋 Listando todos los usuarios...');

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
    } catch (e) {
      print('❌ Error al verificar estructura: $e');
    }
  }

  /// Crea un usuario de prueba si no existe
  static Future<void> crearUsuarioPrueba() async {
    try {
      print('🔧 Creando usuario de prueba...');

      // Verificar si el usuario ya existe
      final existe = await verificarUsuario('lowfrax', 'casa');

      if (!existe) {
        print('➕ Usuario no existe, creando...');

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
      } else {
        print('✅ Usuario ya existe');
      }
    } catch (e) {
      print('❌ Error al crear usuario de prueba: $e');
    }
  }
}
