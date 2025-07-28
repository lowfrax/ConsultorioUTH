import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DBProvider {
  static Database? _db;

  static Future<Database> initDB() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'casos.db');

    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Cuatrimestres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE Procuradores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        telefono INTEGER NOT NULL UNIQUE DEFAULT 0,
        cuatrimestre_id INTEGER,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0,
        FOREIGN KEY(cuatrimestre_id) REFERENCES Cuatrimestres(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE Demandantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        dni TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        direccion TEXT NOT NULL,
        telefono INTEGER NOT NULL UNIQUE DEFAULT 0,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE Demandados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        dni TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        direccion TEXT NOT NULL,
        telefono INTEGER NOT NULL UNIQUE DEFAULT 0,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE Juzgados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_juzgado TEXT NOT NULL UNIQUE,
        direccion TEXT NOT NULL,
        telefono INTEGER UNIQUE DEFAULT 0,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE TipoCaso (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_caso TEXT NOT NULL UNIQUE,
        descripcion TEXT NOT NULL UNIQUE,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE Materias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_materia TEXT NOT NULL UNIQUE,
        descripcion TEXT,
        cuatrimestre_id INTEGER,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0,
        FOREIGN KEY(cuatrimestre_id) REFERENCES Cuatrimestres(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE ProcuradoresMaterias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        procurador_id INTEGER,
        materia_id INTEGER,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(procurador_id) REFERENCES Procuradores(id),
        FOREIGN KEY(materia_id) REFERENCES Materias(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE Casos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_caso TEXT NOT NULL,
        tipocaso_id INTEGER,
        procurador_id INTEGER,
        descripcion TEXT,
        demandante_id INTEGER,
        demandado_id INTEGER,
        juzgado_id INTEGER,
        plazo TEXT,
        estado TEXT NOT NULL,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0,
        FOREIGN KEY(tipocaso_id) REFERENCES TipoCaso(id),
        FOREIGN KEY(procurador_id) REFERENCES Procuradores(id),
        FOREIGN KEY(demandante_id) REFERENCES Demandantes(id),
        FOREIGN KEY(demandado_id) REFERENCES Demandados(id),
        FOREIGN KEY(juzgado_id) REFERENCES Juzgados(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE CasosMaterias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caso_id INTEGER,
        materia_id INTEGER,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(caso_id) REFERENCES Casos(id),
        FOREIGN KEY(materia_id) REFERENCES Materias(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE Expedientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_expediente TEXT,
        caso_id INTEGER,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0,
        FOREIGN KEY(caso_id) REFERENCES Casos(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE ArchivoExpediente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expediente_id INTEGER,
        formato_entrada TEXT,
        formato_actual TEXT,
        creado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_el TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        eliminado INTEGER DEFAULT 0,
        FOREIGN KEY(expediente_id) REFERENCES Expedientes(id)
      );
    ''');
  }

  /// Verifica la conexión a Firebase Firestore con manejo de errores
  static Future<void> verificarConexionFirebase() async {
    try {
      // Intentar acceder a Firestore para verificar la conexión
      final firestore = FirebaseFirestore.instance;

      // Realizar una consulta simple para verificar la conexión
      await firestore.collection('test').limit(1).get();

      print('✅ Conexión exitosa a Firebase Firestore');
      print('📊 Base de datos: ${firestore.app.name}');
      print('🌐 Proyecto: ${firestore.app.options.projectId}');
    } catch (e) {
      print('❌ Error al conectar con Firebase Firestore:');
      print('🔍 Detalles del error: $e');

      // Verificar si es un error de configuración
      if (e.toString().contains('permission-denied')) {
        print(
          '⚠️  Error de permisos: Verifica las reglas de seguridad de Firestore',
        );
      } else if (e.toString().contains('unavailable')) {
        print('⚠️  Error de conectividad: Verifica tu conexión a internet');
      } else if (e.toString().contains('not-found')) {
        print(
          '⚠️  Error de configuración: Verifica la configuración de Firebase',
        );
      }

      // Re-lanzar el error para que pueda ser manejado por el código que llama a esta función
      rethrow;
    }
  }

  /// Verifica la conexión a Firebase Auth
  static Future<void> verificarConexionFirebaseAuth() async {
    try {
      // Intentar acceder a Firebase Auth para verificar la conexión
      final auth = FirebaseAuth.instance;

      print('✅ Conexión exitosa a Firebase Auth');
      print('🔐 Proyecto: ${auth.app.options.projectId}');
    } catch (e) {
      print('❌ Error al conectar con Firebase Auth:');
      print('🔍 Detalles del error: $e');
      rethrow;
    }
  }

  /// Verifica todas las conexiones de Firebase
  static Future<void> verificarTodasLasConexionesFirebase() async {
    print('🔍 Iniciando verificación de conexiones Firebase...');

    try {
      // Verificar Firestore
      await verificarConexionFirebase();

      // Verificar Auth
      await verificarConexionFirebaseAuth();

      print(
        '🎉 Todas las conexiones a Firebase están funcionando correctamente',
      );
    } catch (e) {
      print('💥 Error general en la verificación de Firebase: $e');
      rethrow;
    }
  }
}
