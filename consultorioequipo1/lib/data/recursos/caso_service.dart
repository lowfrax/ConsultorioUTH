import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../modelos/caso.dart';
import '../modelos/expediente.dart';
import '../modelos/archivoexpediente.dart';
import '../modelos/tipocaso.dart';
import '../modelos/juzgado.dart';
import '../modelos/legitario.dart';
import '../modelos/rol_legitario.dart';
import '../modelos/procurador.dart';

class CasoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Colecciones
  static const String _casosCollection = 'Casos';
  static const String _expedientesCollection = 'Expedientes';
  static const String _archivosCollection = 'ArchivoExpediente';
  static const String _tiposCasoCollection = 'TipoCaso';
  static const String _juzgadosCollection = 'Juzgados';
  static const String _legitariosCollection = 'Legitarios';
  static const String _rolesLegitarioCollection = 'Rol_Legitario';
  static const String _procuradoresCollection = 'Procuradores';

  // ========== CASOS ==========

  /// Obtiene todos los casos
  static Future<List<Caso>> obtenerCasos() async {
    try {
      final snapshot = await _firestore
          .collection(_casosCollection)
          .where('eliminado', isEqualTo: false)
          .orderBy('creado_el', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Caso.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener casos: $e');
      return [];
    }
  }

  /// Crea un nuevo caso
  static Future<String?> crearCaso(Caso caso) async {
    try {
      final docRef = await _firestore
          .collection(_casosCollection)
          .add(caso.toMap());
      return docRef.id;
    } catch (e) {
      print('Error al crear caso: $e');
      return null;
    }
  }

  /// Actualiza un caso
  static Future<bool> actualizarCaso(Caso caso) async {
    try {
      await _firestore
          .collection(_casosCollection)
          .doc(caso.id)
          .update(caso.toMap());
      return true;
    } catch (e) {
      print('Error al actualizar caso: $e');
      return false;
    }
  }

  /// Cambia el estado de un caso
  static Future<bool> cambiarEstadoCaso(
    String casoId,
    String nuevoEstado,
  ) async {
    try {
      await _firestore.collection(_casosCollection).doc(casoId).update({
        'estado': nuevoEstado,
        'actualizado_el': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al cambiar estado del caso: $e');
      return false;
    }
  }

  /// Elimina un caso (marcado como eliminado)
  static Future<bool> eliminarCaso(String casoId) async {
    try {
      await _firestore.collection(_casosCollection).doc(casoId).update({
        'eliminado': true,
        'actualizado_el': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al eliminar caso: $e');
      return false;
    }
  }

  // ========== EXPEDIENTES ==========

  /// Obtiene todos los expedientes
  static Future<List<Expediente>> obtenerExpedientes() async {
    try {
      final snapshot = await _firestore
          .collection(_expedientesCollection)
          .where('eliminado', isEqualTo: false)
          .orderBy('creado_el', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expediente.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener expedientes: $e');
      return [];
    }
  }

  /// Crea un nuevo expediente
  static Future<String?> crearExpediente(Expediente expediente) async {
    try {
      final docRef = await _firestore
          .collection(_expedientesCollection)
          .add(expediente.toMap());
      return docRef.id;
    } catch (e) {
      print('Error al crear expediente: $e');
      return null;
    }
  }

  // ========== ARCHIVOS ==========

  /// Sube un archivo al storage y crea el registro en Firestore
  static Future<String?> subirArchivo(File archivo, String expedienteId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${archivo.path.split('/').last}';
      final storageRef = _storage.ref().child(
        'expedientes/$expedienteId/$fileName',
      );

      final uploadTask = storageRef.putFile(archivo);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Crear registro en Firestore
      final archivoExpediente = ArchivoExpediente(
        expedienteId: expedienteId,
        formatoEntrada: archivo.path.split('.').last.toLowerCase(),
        formatoActual: archivo.path.split('.').last.toLowerCase(),
        urlArchivo: downloadUrl,
        nombreArchivo: fileName,
      );

      final docRef = await _firestore
          .collection(_archivosCollection)
          .add(archivoExpediente.toMap());
      return docRef.id;
    } catch (e) {
      print('Error al subir archivo: $e');
      return null;
    }
  }

  /// Obtiene todos los archivos de un expediente
  static Future<List<ArchivoExpediente>> obtenerArchivosExpediente(
    String expedienteId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_archivosCollection)
          .where('expediente_id', isEqualTo: expedienteId)
          .where('eliminado', isEqualTo: false)
          .orderBy('creado_el', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ArchivoExpediente.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener archivos del expediente: $e');
      return [];
    }
  }

  /// Elimina un archivo
  static Future<bool> eliminarArchivo(String archivoId) async {
    try {
      await _firestore.collection(_archivosCollection).doc(archivoId).update({
        'eliminado': true,
        'actualizado_el': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  // ========== TIPOS DE CASO ==========

  /// Obtiene todos los tipos de caso
  static Future<List<TipoCaso>> obtenerTiposCaso() async {
    try {
      final snapshot = await _firestore
          .collection(_tiposCasoCollection)
          .where('eliminado', isEqualTo: false)
          .orderBy('nombre_caso')
          .get();

      return snapshot.docs
          .map((doc) => TipoCaso.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener tipos de caso: $e');
      return [];
    }
  }

  // ========== JUZGADOS ==========

  /// Obtiene todos los juzgados
  static Future<List<Juzgado>> obtenerJuzgados() async {
    try {
      final snapshot = await _firestore
          .collection(_juzgadosCollection)
          .where('eliminado', isEqualTo: false)
          .orderBy('nombre_juzgado')
          .get();

      return snapshot.docs
          .map((doc) => Juzgado.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener juzgados: $e');
      return [];
    }
  }

  // ========== LEGITARIOS ==========

  /// Obtiene todos los legitarios
  static Future<List<Legitario>> obtenerLegitarios() async {
    try {
      final snapshot = await _firestore
          .collection(_legitariosCollection)
          .where('eliminado', isEqualTo: false)
          .orderBy('nombre')
          .get();

      return snapshot.docs
          .map((doc) => Legitario.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener legitarios: $e');
      return [];
    }
  }

  // ========== PROCURADORES ==========

  /// Obtiene todos los procuradores
  static Future<List<Procurador>> obtenerProcuradores() async {
    try {
      final snapshot = await _firestore
          .collection(_procuradoresCollection)
          .where('eliminado', isEqualTo: false)
          .orderBy('nombre')
          .get();

      return snapshot.docs.map((doc) => Procurador.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error al obtener procuradores: $e');
      return [];
    }
  }

  // ========== ESTADÍSTICAS ==========

  /// Obtiene estadísticas de casos
  static Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final casos = await obtenerCasos();

      final pendientes = casos.where((c) => c.estado == 'pendiente').length;
      final enProceso = casos.where((c) => c.estado == 'en proceso').length;
      final finalizados = casos.where((c) => c.estado == 'finalizado').length;
      final retrasados = casos.where((c) => c.estado == 'retrasado').length;

      return {
        'pendientes': pendientes,
        'en_proceso': enProceso,
        'finalizados': finalizados,
        'retrasados': retrasados,
        'total': casos.length,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {
        'pendientes': 0,
        'en_proceso': 0,
        'finalizados': 0,
        'retrasados': 0,
        'total': 0,
      };
    }
  }

  // ========== DATOS DE PRUEBA ==========

  /// Crea datos de prueba en Firebase
  static Future<void> crearDatosPrueba() async {
    try {
      // Crear tipos de caso
      final tiposCaso = [
        {'nombre_caso': 'Civil', 'descripcion': 'Casos civiles'},
        {'nombre_caso': 'Penal', 'descripcion': 'Casos penales'},
        {'nombre_caso': 'Laboral', 'descripcion': 'Casos laborales'},
        {'nombre_caso': 'Familiar', 'descripcion': 'Casos familiares'},
      ];

      for (final tipo in tiposCaso) {
        await _firestore.collection(_tiposCasoCollection).add({
          ...tipo,
          'eliminado': false,
          'creado_el': FieldValue.serverTimestamp(),
          'actualizado_el': FieldValue.serverTimestamp(),
        });
      }

      // Crear juzgados
      final juzgados = [
        {
          'nombre_juzgado': 'Juzgado Primero Civil',
          'direccion': 'Centro Histórico',
          'telefono': '123456789',
        },
        {
          'nombre_juzgado': 'Juzgado Segundo Penal',
          'direccion': 'Zona Norte',
          'telefono': '987654321',
        },
        {
          'nombre_juzgado': 'Juzgado Laboral',
          'direccion': 'Zona Sur',
          'telefono': '555666777',
        },
      ];

      for (final juzgado in juzgados) {
        await _firestore.collection(_juzgadosCollection).add({
          ...juzgado,
          'eliminado': false,
          'creado_el': FieldValue.serverTimestamp(),
          'actualizado_el': FieldValue.serverTimestamp(),
        });
      }

      // Crear roles de legitario
      final rolesLegitario = [
        {'rol': 'demandante'},
        {'rol': 'demandado'},
        {'rol': 'testigo'},
      ];

      for (final rol in rolesLegitario) {
        await _firestore.collection(_rolesLegitarioCollection).add({
          ...rol,
          'eliminado': false,
          'creado_el': FieldValue.serverTimestamp(),
          'actualizado_el': FieldValue.serverTimestamp(),
        });
      }

      // Crear legitarios de prueba
      final legitarios = [
        {
          'rol_id': '', // Se asignará después de crear roles
          'nombre': 'Juan Pérez',
          'email': 'juan.perez@email.com',
          'direccion': 'Calle Principal 123',
          'telefono': '555123456',
        },
        {
          'rol_id': '',
          'nombre': 'María García',
          'email': 'maria.garcia@email.com',
          'direccion': 'Avenida Central 456',
          'telefono': '555789012',
        },
        {
          'rol_id': '',
          'nombre': 'Carlos López',
          'email': 'carlos.lopez@email.com',
          'direccion': 'Plaza Mayor 789',
          'telefono': '555345678',
        },
      ];

      // Obtener roles creados
      final rolesSnapshot = await _firestore
          .collection(_rolesLegitarioCollection)
          .get();
      final roles = rolesSnapshot.docs;

      if (roles.isNotEmpty) {
        for (int i = 0; i < legitarios.length; i++) {
          final legitario = legitarios[i];
          legitario['rol_id'] = roles[i % roles.length].id;

          await _firestore.collection(_legitariosCollection).add({
            ...legitario,
            'eliminado': false,
            'creado_el': FieldValue.serverTimestamp(),
            'actualizado_el': FieldValue.serverTimestamp(),
          });
        }
      }

      // Crear expedientes de prueba
      final expedientes = [
        {'nombre_expediente': 'Expediente Divorcio García'},
        {'nombre_expediente': 'Expediente Herencia Pérez'},
        {'nombre_expediente': 'Expediente Laboral López'},
      ];

      final expedientesIds = <String>[];
      for (final expediente in expedientes) {
        final docRef = await _firestore.collection(_expedientesCollection).add({
          ...expediente,
          'eliminado': false,
          'creado_el': FieldValue.serverTimestamp(),
          'actualizado_el': FieldValue.serverTimestamp(),
        });
        expedientesIds.add(docRef.id);
      }

      // Crear casos de prueba
      final casos = [
        {
          'nombre_caso': 'Divorcio García vs López',
          'tipocaso_id': '', // Se asignará después
          'expediente_id': expedientesIds[0],
          'procurador_id': '', // Se asignará después
          'descripcion': 'Proceso de divorcio por mutuo acuerdo',
          'demandante_id': '', // Se asignará después
          'demandado_id': '', // Se asignará después
          'juzgado_id': '', // Se asignará después
          'plazo': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 90)),
          ),
          'costo': 5000.0,
          'estado': 'pendiente',
        },
        {
          'nombre_caso': 'Herencia Pérez',
          'tipocaso_id': '',
          'expediente_id': expedientesIds[1],
          'procurador_id': '',
          'descripcion': 'Proceso de sucesión intestamentaria',
          'demandante_id': '',
          'demandado_id': '',
          'juzgado_id': '',
          'plazo': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 120)),
          ),
          'costo': 8000.0,
          'estado': 'en proceso',
        },
        {
          'nombre_caso': 'Despido Laboral López',
          'tipocaso_id': '',
          'expediente_id': expedientesIds[2],
          'procurador_id': '',
          'descripcion': 'Demanda por despido injustificado',
          'demandante_id': '',
          'demandado_id': '',
          'juzgado_id': '',
          'plazo': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 60)),
          ),
          'costo': 3000.0,
          'estado': 'pendiente',
        },
      ];

      // Obtener datos necesarios para asignar IDs
      final tiposCasoSnapshot = await _firestore
          .collection(_tiposCasoCollection)
          .get();
      final procuradoresSnapshot = await _firestore
          .collection(_procuradoresCollection)
          .get();
      final legitariosSnapshot = await _firestore
          .collection(_legitariosCollection)
          .get();
      final juzgadosSnapshot = await _firestore
          .collection(_juzgadosCollection)
          .get();

      if (tiposCasoSnapshot.docs.isNotEmpty &&
          procuradoresSnapshot.docs.isNotEmpty &&
          legitariosSnapshot.docs.isNotEmpty &&
          juzgadosSnapshot.docs.isNotEmpty) {
        for (int i = 0; i < casos.length; i++) {
          final caso = casos[i];
          caso['tipocaso_id'] =
              tiposCasoSnapshot.docs[i % tiposCasoSnapshot.docs.length].id;
          caso['procurador_id'] = procuradoresSnapshot
              .docs[i % procuradoresSnapshot.docs.length]
              .id;
          caso['demandante_id'] =
              legitariosSnapshot.docs[i % legitariosSnapshot.docs.length].id;
          caso['demandado_id'] = legitariosSnapshot
              .docs[(i + 1) % legitariosSnapshot.docs.length]
              .id;
          caso['juzgado_id'] =
              juzgadosSnapshot.docs[i % juzgadosSnapshot.docs.length].id;

          await _firestore.collection(_casosCollection).add({
            ...caso,
            'eliminado': false,
            'creado_el': FieldValue.serverTimestamp(),
            'actualizado_el': FieldValue.serverTimestamp(),
          });
        }
      }

      print('✅ Datos de prueba creados exitosamente');
    } catch (e) {
      print('❌ Error al crear datos de prueba: $e');
    }
  }
}
