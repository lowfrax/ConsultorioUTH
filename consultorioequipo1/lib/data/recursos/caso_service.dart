import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../modelos/caso.dart';
import '../modelos/expediente.dart';
import '../modelos/archivoexpediente.dart';
import '../modelos/tipocaso.dart';
import '../modelos/juzgado.dart';
import '../modelos/legitario.dart';
import '../modelos/procurador.dart';
import '../modelos/rol_legitario.dart';

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
          .get();

      print('📊 Casos encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        print('  - Caso: ${doc.data()['nombre_caso']} (ID: ${doc.id})');
      }

      return snapshot.docs.map((doc) => Caso.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error al obtener casos: $e');
      return [];
    }
  }

  /// Crea un nuevo legitario en Firestore
  static Future<String?> crearLegitario(Legitario legitario) async {
    try {
      // 1. Primero verificar si el rol existe
      final rolSnapshot = await _firestore
          .collection(_rolesLegitarioCollection)
          .where('rol', isEqualTo: legitario.rolId)
          .where('eliminado', isEqualTo: false)
          .get();

      String rolId;

      if (rolSnapshot.docs.isEmpty) {
        // Si el rol no existe, crearlo
        print('⚠️ Rol no encontrado, creando nuevo rol: ${legitario.rolId}');
        final nuevoRolRef = await _firestore
            .collection(_rolesLegitarioCollection)
            .add({
              'rol': legitario.rolId,
              'eliminado': false,
              'creado_el': FieldValue.serverTimestamp(),
              'actualizado_el': FieldValue.serverTimestamp(),
            });
        rolId = nuevoRolRef.id;
      } else {
        // Usar el rol existente
        rolId = rolSnapshot.docs.first.id;
      }

      // 2. Crear el legitario
      final legitarioData = {
        'nombre': legitario.nombre,
        'rol_id': rolId,
        'eliminado': false,
        'creado_el': FieldValue.serverTimestamp(),
        'actualizado_el': FieldValue.serverTimestamp(),
      };

      // Campos opcionales
      if (legitario.email != null) {
        legitarioData['email'] = legitario.email;
      }
      if (legitario.telefono != null) {
        legitarioData['telefono'] = legitario.telefono;
      }

      print('📝 Creando legitario con datos:');
      print(legitarioData);

      final legitarioRef = await _firestore
          .collection(_legitariosCollection)
          .add(legitarioData);

      print('✅ Legitario creado exitosamente con ID: ${legitarioRef.id}');
      return legitarioRef.id;
    } catch (e) {
      print('❌ Error al crear legitario: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  static Future<Map<String, dynamic>> obtenerEstadisticasPorProcurador(
    String procuradorId,
  ) async {
    final casos = await obtenerCasosPorProcurador(procuradorId);

    // Simple example: contar por estado
    final Map<String, int> estadoCount = {};
    for (final caso in casos) {
      final estado = caso.estado ?? 'desconocido';
      estadoCount[estado] = (estadoCount[estado] ?? 0) + 1;
    }

    return {'total': casos.length, 'porEstado': estadoCount};
  }

  Future<Expediente?> _obtenerExpediente(String expedienteId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Expedientes')
          .doc(expedienteId)
          .get();
      return doc.exists ? Expediente.fromMap(doc.data()!, doc.id) : null;
    } catch (e) {
      print('Error obteniendo expediente $expedienteId: $e');
      return null;
    }
  }

  Future<List<ArchivoExpediente>> _obtenerArchivosExpediente(
    String expedienteId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ArchivoExpediente')
          .where('expediente_id', isEqualTo: expedienteId)
          .get();

      return snapshot.docs
          .map((doc) => ArchivoExpediente.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo archivos para expediente $expedienteId: $e');
      return [];
    }
  }

  static Future<List<Caso>> obtenerCasosPorProcurador(
    String procuradorId,
  ) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('Casos')
          .where('procuradorId', isEqualTo: procuradorId)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return Caso(
          id: doc.id,
          nombreCaso: data['nombreCaso'] ?? '',
          tipocasoId: data['tipocasoId'] ?? '',
          expedienteId: data['expedienteId'] ?? '',
          procuradorId: data['procuradorId'] ?? '',
          descripcion: data['descripcion'] ?? '',
          demandanteId: data['demandanteId'] ?? '',
          demandadoId: data['demandadoId'] ?? '',
          juzgadoId: data['juzgadoId'] ?? '',
          plazo: (data['plazo'] as Timestamp).toDate(),
          costo: (data['costo'] as num).toDouble(),
          estado: data['estado'] ?? 'pendiente',
        );
      }).toList();
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

  static Future<List<Expediente>> obtenerExpedientes() async {
    final snapshot = await _firestore
        .collection(_expedientesCollection)
        .where('eliminado', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => Expediente.fromMap(doc.data(), doc.id))
        .toList();
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
      print('📤 Iniciando subida de archivo: ${archivo.path}');
      print('📁 Expediente ID: $expedienteId');

      // Verificar que el archivo existe
      if (!await archivo.exists()) {
        print('❌ El archivo no existe: ${archivo.path}');
        return null;
      }

      // Obtener información del archivo
      final fileSize = await archivo.length();
      final fileName = archivo.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      print('📋 Información del archivo:');
      print('  - Nombre: $fileName');
      print('  - Tamaño: ${fileSize} bytes');
      print('  - Extensión: $fileExtension');

      // Crear nombre único para el archivo en Storage
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storageRef = _storage.ref().child(
        'expedientes/$expedienteId/$uniqueFileName',
      );

      print('📤 Subiendo archivo a Firebase Storage...');
      print('📁 Ruta en Storage: expedientes/$expedienteId/$uniqueFileName');

      final uploadTask = storageRef.putFile(archivo);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Archivo subido exitosamente');
      print('📥 URL de descarga: $downloadUrl');

      // Crear registro en Firestore
      print('📝 Creando registro en Firestore...');

      final archivoExpediente = ArchivoExpediente(
        expedienteId: expedienteId,
        urlArchivo: downloadUrl,
        nombreArchivo: fileName,
        formatoEntrada: fileExtension,
        formatoActual: fileExtension,
      );

      print('📋 Datos del archivo: ${archivoExpediente.toMap()}');

      final docRef = await _firestore
          .collection(_archivosCollection)
          .add(archivoExpediente.toMap());

      print('✅ Registro creado con ID: ${docRef.id}');
      print('🎯 Archivo subido y registrado exitosamente');

      return docRef.id;
    } catch (e) {
      print('❌ Error al subir archivo: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Obtiene todos los archivos de un expediente
  static Future<List<ArchivoExpediente>> obtenerArchivosExpediente(
    String expedienteId,
  ) async {
    try {
      print('🔍 Buscando archivos para expediente: $expedienteId');

      final snapshot = await _firestore
          .collection(_archivosCollection)
          .where('expediente_id', isEqualTo: expedienteId)
          .where('eliminado', isEqualTo: false)
          .get();

      print(
        '📁 Archivos encontrados para expediente $expedienteId: ${snapshot.docs.length}',
      );

      if (snapshot.docs.isEmpty) {
        print('⚠️ No se encontraron archivos para el expediente $expedienteId');
        return [];
      }

      final archivos = <ArchivoExpediente>[];
      for (final doc in snapshot.docs) {
        print('  📄 Archivo ID: ${doc.id}');
        print('  📋 Datos del archivo: ${doc.data()}');

        try {
          final archivo = ArchivoExpediente.fromMap(doc.data(), doc.id);
          print('  ✅ Archivo procesado: ${archivo.nombreArchivo}');
          archivos.add(archivo);
        } catch (e) {
          print(
            '  ❌ Error al crear ArchivoExpediente desde documento ${doc.id}: $e',
          );
        }
      }

      print(
        '🎯 Total de archivos procesados para expediente $expedienteId: ${archivos.length}',
      );
      return archivos;
    } catch (e) {
      print('❌ Error al obtener archivos del expediente: $e');
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
          .get();

      print('🏷️ Tipos de caso encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        print('  - Tipo: ${doc.data()['nombre_caso']} (ID: ${doc.id})');
      }

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
          .get();

      print('⚖️ Juzgados encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        print('  - Juzgado: ${doc.data()['nombre_juzgado']} (ID: ${doc.id})');
      }

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
          .get();

      print('👥 Legitarios encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        print('  - Legitario: ${doc.data()['nombre']} (ID: ${doc.id})');
      }

      return snapshot.docs
          .map((doc) => Legitario.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener legitarios: $e');
      return [];
    }
  }

  /// Obtiene legitarios por rol específico
  static Future<List<Legitario>> obtenerLegitariosPorRol(String rol) async {
    try {
      print('🔍 Buscando legitarios con rol: $rol');

      // Primero obtener todos los roles
      final rolesSnapshot = await _firestore
          .collection(_rolesLegitarioCollection)
          .where('rol', isEqualTo: rol)
          .where('eliminado', isEqualTo: false)
          .get();

      if (rolesSnapshot.docs.isEmpty) {
        print('⚠️ No se encontraron roles con nombre: $rol');
        return [];
      }

      final roleIds = rolesSnapshot.docs.map((doc) => doc.id).toList();
      print('📋 IDs de roles encontrados: $roleIds');

      // Obtener legitarios que tengan estos roles
      final legitarios = <Legitario>[];
      for (final roleId in roleIds) {
        final legitariosSnapshot = await _firestore
            .collection(_legitariosCollection)
            .where('rol_id', isEqualTo: roleId)
            .where('eliminado', isEqualTo: false)
            .get();

        for (final doc in legitariosSnapshot.docs) {
          try {
            final legitario = Legitario.fromMap(doc.data(), doc.id);
            legitarios.add(legitario);
            print('  ✅ Legitario agregado: ${legitario.nombre} (rol: $rol)');
          } catch (e) {
            print('  ❌ Error al crear Legitario: $e');
          }
        }
      }

      print('🎯 Total de legitarios con rol $rol: ${legitarios.length}');
      return legitarios;
    } catch (e) {
      print('❌ Error al obtener legitarios por rol: $e');
      return [];
    }
  }

  // ========== PROCURADORES ==========

  /// Obtiene todos los procuradores
  static Future<List<Procurador>> obtenerProcuradores() async {
    try {
      print(
        '🔍 Buscando procuradores en la colección: $_procuradoresCollection',
      );

      // Primero obtener todos los documentos sin filtro
      final snapshot = await _firestore
          .collection(_procuradoresCollection)
          .get();

      print(
        '👨‍💼 Total de documentos en Procuradores: ${snapshot.docs.length}',
      );

      if (snapshot.docs.isEmpty) {
        print('⚠️ No hay documentos en la colección Procuradores');
        return [];
      }

      // Filtrar documentos no eliminados manualmente
      final documentosNoEliminados = snapshot.docs.where((doc) {
        final data = doc.data();
        final eliminado = data['eliminado'] ?? false;
        print('  📄 Documento ${doc.id}: eliminado = $eliminado');
        return !eliminado;
      }).toList();

      print('✅ Documentos no eliminados: ${documentosNoEliminados.length}');

      final procuradores = <Procurador>[];
      for (final doc in documentosNoEliminados) {
        print('  📄 Procesando documento ID: ${doc.id}');
        print('  📋 Datos del documento: ${doc.data()}');

        try {
          final procurador = Procurador.fromMap(doc.data(), doc.id);
          print('  ✅ Procurador creado exitosamente: ${procurador.nombre}');
          procuradores.add(procurador);
        } catch (e) {
          print('  ❌ Error al crear Procurador desde documento ${doc.id}: $e');
          print('  📋 Datos problemáticos: ${doc.data()}');
        }
      }

      print(
        '🎯 Total de procuradores procesados exitosamente: ${procuradores.length}',
      );
      return procuradores;
    } catch (e) {
      print('❌ Error al obtener procuradores: $e');
      print('❌ Stack trace: ${StackTrace.current}');
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

      print(
        '📈 Estadísticas: P=$pendientes, EP=$enProceso, F=$finalizados, R=$retrasados, T=${casos.length}',
      );

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
      print('🔧 Iniciando creación de datos de prueba...');

      // Verificar si ya existen datos
      final tiposCasoSnapshot = await _firestore
          .collection(_tiposCasoCollection)
          .get();
      final juzgadosSnapshot = await _firestore
          .collection(_juzgadosCollection)
          .get();
      final rolesSnapshot = await _firestore
          .collection(_rolesLegitarioCollection)
          .get();
      final legitariosSnapshot = await _firestore
          .collection(_legitariosCollection)
          .get();
      final procuradoresSnapshot = await _firestore
          .collection(_procuradoresCollection)
          .get();

      print('📊 Datos existentes:');
      print('  - Tipos de caso: ${tiposCasoSnapshot.docs.length}');
      print('  - Juzgados: ${juzgadosSnapshot.docs.length}');
      print('  - Roles legitario: ${rolesSnapshot.docs.length}');
      print('  - Legitarios: ${legitariosSnapshot.docs.length}');
      print('  - Procuradores: ${procuradoresSnapshot.docs.length}');

      // Solo crear datos si no existen
      if (tiposCasoSnapshot.docs.isEmpty) {
        print('➕ Creando tipos de caso...');
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
      }

      if (juzgadosSnapshot.docs.isEmpty) {
        print('➕ Creando juzgados...');
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
      }

      if (rolesSnapshot.docs.isEmpty) {
        print('➕ Creando roles de legitario...');
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
      }

      if (legitariosSnapshot.docs.isEmpty) {
        print('➕ Creando legitarios...');
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
      }

      // Crear expedientes de prueba
      print('➕ Creando expedientes...');
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
      print('➕ Creando casos...');
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
      final tiposCasoSnapshotFinal = await _firestore
          .collection(_tiposCasoCollection)
          .get();
      final procuradoresSnapshotFinal = await _firestore
          .collection(_procuradoresCollection)
          .get();
      final legitariosSnapshotFinal = await _firestore
          .collection(_legitariosCollection)
          .get();
      final juzgadosSnapshotFinal = await _firestore
          .collection(_juzgadosCollection)
          .get();

      print('📋 Asignando IDs a casos...');
      print(
        '  - Tipos de caso disponibles: ${tiposCasoSnapshotFinal.docs.length}',
      );
      print(
        '  - Procuradores disponibles: ${procuradoresSnapshotFinal.docs.length}',
      );
      print(
        '  - Legitarios disponibles: ${legitariosSnapshotFinal.docs.length}',
      );
      print('  - Juzgados disponibles: ${juzgadosSnapshotFinal.docs.length}');

      if (tiposCasoSnapshotFinal.docs.isNotEmpty &&
          procuradoresSnapshotFinal.docs.isNotEmpty &&
          legitariosSnapshotFinal.docs.isNotEmpty &&
          juzgadosSnapshotFinal.docs.isNotEmpty) {
        for (int i = 0; i < casos.length; i++) {
          final caso = casos[i];
          caso['tipocaso_id'] = tiposCasoSnapshotFinal
              .docs[i % tiposCasoSnapshotFinal.docs.length]
              .id;
          caso['procurador_id'] = procuradoresSnapshotFinal
              .docs[i % procuradoresSnapshotFinal.docs.length]
              .id;
          caso['demandante_id'] = legitariosSnapshotFinal
              .docs[i % legitariosSnapshotFinal.docs.length]
              .id;
          caso['demandado_id'] = legitariosSnapshotFinal
              .docs[(i + 1) % legitariosSnapshotFinal.docs.length]
              .id;
          caso['juzgado_id'] = juzgadosSnapshotFinal
              .docs[i % juzgadosSnapshotFinal.docs.length]
              .id;

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

  // ========== MÉTODOS DE PRUEBA ==========

  /// Obtiene todos los casos sin filtros (para pruebas)
  static Future<List<Caso>> obtenerTodosLosCasos() async {
    try {
      final snapshot = await _firestore.collection(_casosCollection).get();

      print('📊 Todos los casos encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print(
          '  - Caso: ${data['nombre_caso']} (ID: ${doc.id}, Eliminado: ${data['eliminado']})',
        );
      }

      return snapshot.docs.map((doc) => Caso.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error al obtener todos los casos: $e');
      return [];
    }
  }

  /// Obtiene todos los tipos de caso sin filtros (para pruebas)
  static Future<List<TipoCaso>> obtenerTodosLosTiposCaso() async {
    try {
      final snapshot = await _firestore.collection(_tiposCasoCollection).get();

      print('🏷️ Todos los tipos de caso encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print(
          '  - Tipo: ${data['nombre_caso']} (ID: ${doc.id}, Eliminado: ${data['eliminado']})',
        );
      }

      return snapshot.docs
          .map((doc) => TipoCaso.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener todos los tipos de caso: $e');
      return [];
    }
  }

  /// Obtiene todos los juzgados sin filtros (para pruebas)
  static Future<List<Juzgado>> obtenerTodosLosJuzgados() async {
    try {
      final snapshot = await _firestore.collection(_juzgadosCollection).get();

      print('⚖️ Todos los juzgados encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print(
          '  - Juzgado: ${data['nombre_juzgado']} (ID: ${doc.id}, Eliminado: ${data['eliminado']})',
        );
      }

      return snapshot.docs
          .map((doc) => Juzgado.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener todos los juzgados: $e');
      return [];
    }
  }

  /// Obtiene todos los legitarios sin filtros (para pruebas)
  static Future<List<Legitario>> obtenerTodosLosLegitarios() async {
    try {
      final snapshot = await _firestore.collection(_legitariosCollection).get();

      print('👥 Todos los legitarios encontrados: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print(
          '  - Legitario: ${data['nombre']} (ID: ${doc.id}, Eliminado: ${data['eliminado']})',
        );
      }

      return snapshot.docs
          .map((doc) => Legitario.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener todos los legitarios: $e');
      return [];
    }
  }

  /// Obtiene todos los procuradores sin filtros (para pruebas)
  static Future<List<Procurador>> obtenerTodosLosProcuradores() async {
    try {
      final snapshot = await _firestore
          .collection(_procuradoresCollection)
          .get();

      print(
        '👨‍💼 Todos los procuradores encontrados: ${snapshot.docs.length}',
      );
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print(
          '  - Procurador: ${data['nombre']} (ID: ${doc.id}, Eliminado: ${data['eliminado']})',
        );
      }

      return snapshot.docs
          .map((doc) => Procurador.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al obtener todos los procuradores: $e');
      return [];
    }
  }

  // ========== DIAGNÓSTICO ==========

  /// Verifica la existencia de datos en todas las colecciones
  static Future<Map<String, dynamic>> diagnosticarDatos() async {
    try {
      print('🔍 Iniciando diagnóstico de datos...');

      final resultados = <String, dynamic>{};

      // Verificar tipos de caso
      final tiposCasoSnapshot = await _firestore
          .collection(_tiposCasoCollection)
          .get();
      resultados['tipos_caso'] = {
        'total': tiposCasoSnapshot.docs.length,
        'no_eliminados': tiposCasoSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': tiposCasoSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nombre': doc.data()['nombre_caso'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      // Verificar juzgados
      final juzgadosSnapshot = await _firestore
          .collection(_juzgadosCollection)
          .get();
      resultados['juzgados'] = {
        'total': juzgadosSnapshot.docs.length,
        'no_eliminados': juzgadosSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': juzgadosSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nombre': doc.data()['nombre_juzgado'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      // Verificar roles de legitario
      final rolesSnapshot = await _firestore
          .collection(_rolesLegitarioCollection)
          .get();
      resultados['roles_legitario'] = {
        'total': rolesSnapshot.docs.length,
        'no_eliminados': rolesSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': rolesSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'rol': doc.data()['rol'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      // Verificar legitarios
      final legitariosSnapshot = await _firestore
          .collection(_legitariosCollection)
          .get();
      resultados['legitarios'] = {
        'total': legitariosSnapshot.docs.length,
        'no_eliminados': legitariosSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': legitariosSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nombre': doc.data()['nombre'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      // Verificar procuradores
      final procuradoresSnapshot = await _firestore
          .collection(_procuradoresCollection)
          .get();
      resultados['procuradores'] = {
        'total': procuradoresSnapshot.docs.length,
        'no_eliminados': procuradoresSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': procuradoresSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nombre': doc.data()['nombre'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      // Verificar expedientes
      final expedientesSnapshot = await _firestore
          .collection(_expedientesCollection)
          .get();
      resultados['expedientes'] = {
        'total': expedientesSnapshot.docs.length,
        'no_eliminados': expedientesSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': expedientesSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nombre': doc.data()['nombre_expediente'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      // Verificar casos
      final casosSnapshot = await _firestore.collection(_casosCollection).get();
      resultados['casos'] = {
        'total': casosSnapshot.docs.length,
        'no_eliminados': casosSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': casosSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nombre': doc.data()['nombre_caso'],
                'estado': doc.data()['estado'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      // Verificar archivos
      final archivosSnapshot = await _firestore
          .collection(_archivosCollection)
          .get();
      resultados['archivos'] = {
        'total': archivosSnapshot.docs.length,
        'no_eliminados': archivosSnapshot.docs
            .where((doc) => !(doc.data()['eliminado'] ?? false))
            .length,
        'datos': archivosSnapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'nombre': doc.data()['nombre_archivo'],
                'expediente_id': doc.data()['expediente_id'],
                'eliminado': doc.data()['eliminado'] ?? false,
              },
            )
            .toList(),
      };

      print('✅ Diagnóstico completado');
      return resultados;
    } catch (e) {
      print('❌ Error en diagnóstico: $e');
      return {};
    }
  }

  /// Diagnóstico específico para procuradores
  static Future<void> diagnosticarProcuradores() async {
    try {
      print('🔍 === DIAGNÓSTICO DE PROCURADORES ===');

      // 1. Verificar si la colección existe
      print('1️⃣ Verificando colección Procuradores...');
      final snapshot = await _firestore
          .collection(_procuradoresCollection)
          .get();
      print(
        '   📊 Total de documentos en Procuradores: ${snapshot.docs.length}',
      );

      if (snapshot.docs.isEmpty) {
        print('   ❌ No hay documentos en la colección Procuradores');
        return;
      }

      // 2. Mostrar todos los documentos sin filtro
      print('2️⃣ Documentos encontrados (sin filtro):');
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        print('   📄 Documento ${i + 1}:');
        print('      ID: ${doc.id}');
        print('      Nombre: ${data['nombre']}');
        print('      Email: ${data['email']}');
        print('      Teléfono: ${data['telefono']}');
        print('      Eliminado: ${data['eliminado']}');
        print('      ---');
      }

      // 3. Verificar documentos no eliminados
      print('3️⃣ Documentos no eliminados:');
      final noEliminados = snapshot.docs
          .where((doc) => !(doc.data()['eliminado'] ?? false))
          .toList();
      print('   📊 Documentos no eliminados: ${noEliminados.length}');

      for (int i = 0; i < noEliminados.length; i++) {
        final doc = noEliminados[i];
        final data = doc.data();
        print('   ✅ Procurador ${i + 1}: ${data['nombre']} (${data['email']})');
      }

      // 4. Intentar crear objetos Procurador
      print('4️⃣ Creando objetos Procurador...');
      final procuradores = <Procurador>[];
      for (final doc in noEliminados) {
        try {
          final procurador = Procurador.fromMap(doc.data(), doc.id);
          procuradores.add(procurador);
          print('   ✅ Procurador creado: ${procurador.nombre}');
        } catch (e) {
          print('   ❌ Error al crear Procurador: $e');
          print('   📋 Datos problemáticos: ${doc.data()}');
        }
      }

      print('🎯 Total de procuradores válidos: ${procuradores.length}');
      print('🔍 === FIN DIAGNÓSTICO ===');
    } catch (e) {
      print('❌ Error en diagnóstico de procuradores: $e');
    }
  }

  // ========== MANEJO DE ARCHIVOS LOCALES ==========

  /// Copia un archivo al directorio local de la aplicación
  static Future<String?> copiarArchivoLocal(
    File archivo,
    String expedienteId,
  ) async {
    try {
      print('📁 Copiando archivo localmente: ${archivo.path}');

      // Obtener el directorio de documentos de la aplicación
      final appDir = await getApplicationDocumentsDirectory();
      final expedienteDir = Directory(
        '${appDir.path}/expedientes/$expedienteId',
      );

      // Crear el directorio si no existe
      if (!await expedienteDir.exists()) {
        await expedienteDir.create(recursive: true);
      }

      // Crear nombre único para el archivo
      final fileName = archivo.path.split('/').last;
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final localPath = '${expedienteDir.path}/$uniqueFileName';

      // Copiar el archivo
      final localFile = await archivo.copy(localPath);

      print('✅ Archivo copiado localmente: $localPath');
      return localPath;
    } catch (e) {
      print('❌ Error al copiar archivo localmente: $e');
      return null;
    }
  }

  /// Guarda un archivo localmente y crea el registro en Firestore
  static Future<String?> guardarArchivoLocal(
    File archivo,
    String expedienteId,
  ) async {
    try {
      print('💾 Guardando archivo localmente...');

      // Copiar archivo localmente
      final rutaLocal = await copiarArchivoLocal(archivo, expedienteId);
      if (rutaLocal == null) {
        print('❌ No se pudo copiar el archivo localmente');
        return null;
      }

      // Obtener información del archivo
      final fileName = archivo.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Crear registro en Firestore
      final archivoExpediente = ArchivoExpediente(
        expedienteId: expedienteId,
        nombreArchivo: fileName,
        formatoEntrada: fileExtension,
        formatoActual: fileExtension,
        rutaLocal: rutaLocal,
      );

      print('📝 Creando registro local en Firestore...');
      final docRef = await _firestore
          .collection(_archivosCollection)
          .add(archivoExpediente.toMap());

      print('✅ Archivo guardado localmente con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error al guardar archivo localmente: $e');
      return null;
    }
  }

  /// Sube un archivo local a Firebase Storage
  static Future<String?> subirArchivoLocalAFirebase(String archivoId) async {
    try {
      print('📤 Subiendo archivo local a Firebase Storage...');

      // Obtener el registro del archivo
      final doc = await _firestore
          .collection(_archivosCollection)
          .doc(archivoId)
          .get();
      if (!doc.exists) {
        print('❌ No se encontró el registro del archivo');
        return null;
      }

      final data = doc.data()!;
      final rutaLocal = data['ruta_local'];
      final expedienteId = data['expediente_id'];
      final nombreArchivo = data['nombre_archivo'];

      if (rutaLocal == null) {
        print('❌ No hay ruta local para el archivo');
        return null;
      }

      // Verificar que el archivo local existe
      final localFile = File(rutaLocal);
      if (!await localFile.exists()) {
        print('❌ El archivo local no existe: $rutaLocal');
        return null;
      }

      // Subir a Firebase Storage
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo';
      final storageRef = _storage.ref().child(
        'expedientes/$expedienteId/$uniqueFileName',
      );

      print('📤 Subiendo archivo a Firebase Storage...');
      final uploadTask = storageRef.putFile(localFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Archivo subido a Firebase Storage');
      print('📥 URL de descarga: $downloadUrl');

      // Actualizar el registro con la URL de Firebase
      await _firestore.collection(_archivosCollection).doc(archivoId).update({
        'url_archivo': downloadUrl,
        'actualizado_el': FieldValue.serverTimestamp(),
      });

      print('✅ Registro actualizado con URL de Firebase');
      return downloadUrl;
    } catch (e) {
      print('❌ Error al subir archivo a Firebase: $e');
      return null;
    }
  }
}
