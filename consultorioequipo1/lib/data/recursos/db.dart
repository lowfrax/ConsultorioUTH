import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
}
