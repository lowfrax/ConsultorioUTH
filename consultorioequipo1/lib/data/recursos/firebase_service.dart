import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

/// Servicio para manejar las conexiones y verificaciones de Firebase
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifica la conectividad de red básica
  static Future<bool> _verificarConectividadRed() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Verifica la conexión a Firebase Firestore con timeout y verificación real
  static Future<bool> verificarConexionFirestore() async {
    try {
      // Primero verificar conectividad de red
      final tieneInternet = await _verificarConectividadRed();
      if (!tieneInternet) {
        print('❌ No hay conexión a internet');
        return false;
      }

      // Realizar una consulta con timeout para verificar la conexión real
      final query = _firestore.collection('test').limit(1);

      // Usar timeout para detectar problemas de conectividad rápidamente
      final snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Timeout al conectar con Firestore');
        },
      );

      // Verificar que realmente se pudo conectar (incluso si la colección está vacía)
      print('✅ Conexión exitosa a Firebase Firestore');
      print('📊 Base de datos: ${_firestore.app.name}');
      print('🌐 Proyecto: ${_firestore.app.options.projectId}');
      print('📄 Documentos en colección test: ${snapshot.docs.length}');

      return true;
    } catch (e) {
      print('❌ Error al conectar con Firebase Firestore:');
      print('🔍 Detalles del error: $e');

      _mostrarMensajeError(e);
      return false;
    }
  }

  /// Verifica la conexión a Firebase Auth con timeout
  static Future<bool> verificarConexionAuth() async {
    try {
      // Primero verificar conectividad de red
      final tieneInternet = await _verificarConectividadRed();
      if (!tieneInternet) {
        print('❌ No hay conexión a internet');
        return false;
      }

      // Verificar que Auth esté disponible con timeout
      await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Timeout al conectar con Firebase Auth');
        },
      );

      print('✅ Conexión exitosa a Firebase Auth');
      print('🔐 Proyecto: ${_auth.app.options.projectId}');

      return true;
    } catch (e) {
      print('❌ Error al conectar con Firebase Auth:');
      print('🔍 Detalles del error: $e');

      _mostrarMensajeError(e);
      return false;
    }
  }

  /// Verifica todas las conexiones de Firebase con manejo mejorado
  static Future<Map<String, bool>> verificarTodasLasConexiones() async {
    print('🔍 Iniciando verificación de conexiones Firebase...');

    final resultados = <String, bool>{};

    try {
      // Verificar conectividad de red primero
      final tieneInternet = await _verificarConectividadRed();
      if (!tieneInternet) {
        print('❌ No hay conexión a internet - No se puede verificar Firebase');
        return {'firestore': false, 'auth': false, 'internet': false};
      }

      // Verificar Firestore
      resultados['firestore'] = await verificarConexionFirestore();

      // Verificar Auth
      resultados['auth'] = await verificarConexionAuth();

      // Verificar si todas las conexiones están funcionando
      final todasFuncionando = resultados.values.every((conexion) => conexion);

      if (todasFuncionando) {
        print(
          '🎉 Todas las conexiones a Firebase están funcionando correctamente',
        );
      } else {
        print('⚠️  Algunas conexiones a Firebase fallaron');
        print('📊 Resultados: $resultados');
      }

      return resultados;
    } catch (e) {
      print('💥 Error general en la verificación de Firebase: $e');
      return {'firestore': false, 'auth': false, 'error': true};
    }
  }

  /// Muestra mensajes de error específicos según el tipo de error
  static void _mostrarMensajeError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission-denied')) {
      print(
        '⚠️  Error de permisos: Verifica las reglas de seguridad de Firestore',
      );
    } else if (errorString.contains('unavailable') ||
        errorString.contains('network') ||
        errorString.contains('timeout')) {
      print('⚠️  Error de conectividad: Verifica tu conexión a internet');
    } else if (errorString.contains('not-found') ||
        errorString.contains('project')) {
      print(
        '⚠️  Error de configuración: Verifica la configuración de Firebase',
      );
    } else if (errorString.contains('quota-exceeded')) {
      print(
        '⚠️  Error de cuota: Has excedido el límite de consultas de Firebase',
      );
    } else if (errorString.contains('unauthenticated')) {
      print(
        '⚠️  Error de autenticación: Verifica las credenciales de Firebase',
      );
    } else if (errorString.contains('timeout')) {
      print('⚠️  Timeout: La conexión tardó demasiado en responder');
    } else {
      print('⚠️  Error desconocido: Revisa la configuración de Firebase');
    }
  }

  /// Obtiene información del proyecto de Firebase
  static Map<String, String> obtenerInformacionProyecto() {
    try {
      return {
        'nombre_app': _firestore.app.name,
        'proyecto_id': _firestore.app.options.projectId ?? '',
        'api_key': _firestore.app.options.apiKey ?? '',
        'auth_domain': _firestore.app.options.authDomain ?? '',
      };
    } catch (e) {
      print('❌ Error al obtener información del proyecto: $e');
      return {};
    }
  }

  /// Verifica la conectividad de red de forma más robusta
  static Future<bool> verificarConectividadInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final tieneInternet =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (tieneInternet) {
        print('✅ Conexión a internet disponible');
      } else {
        print('❌ No hay conexión a internet');
      }

      return tieneInternet;
    } on SocketException catch (_) {
      print('❌ No hay conexión a internet');
      return false;
    }
  }

  /// Prueba la conexión a Firebase de forma exhaustiva
  static Future<Map<String, dynamic>> probarConexionExhaustiva() async {
    print('🔬 Iniciando prueba exhaustiva de conexión a Firebase...');

    final resultados = <String, dynamic>{};

    try {
      // 1. Verificar conectividad de red
      print('📡 Verificando conectividad de red...');
      final tieneInternet = await verificarConectividadInternet();
      resultados['internet'] = tieneInternet;

      if (!tieneInternet) {
        print('❌ Sin internet - No se puede probar Firebase');
        return resultados;
      }

      // 2. Verificar configuración de Firebase
      print('⚙️  Verificando configuración de Firebase...');
      try {
        final info = obtenerInformacionProyecto();
        resultados['configuracion'] = info.isNotEmpty;
        print('📋 Configuración: ${info['proyecto_id']}');
      } catch (e) {
        print('❌ Error en configuración: $e');
        resultados['configuracion'] = false;
      }

      // 3. Probar conexión a Firestore con diferentes timeouts
      print('🔥 Probando conexión a Firestore...');
      try {
        final firestoreResult = await _probarFirestoreConTimeout();
        resultados['firestore'] = firestoreResult;
      } catch (e) {
        print('❌ Error en Firestore: $e');
        resultados['firestore'] = false;
      }

      // 4. Probar conexión a Auth
      print('🔐 Probando conexión a Auth...');
      try {
        final authResult = await _probarAuthConTimeout();
        resultados['auth'] = authResult;
      } catch (e) {
        print('❌ Error en Auth: $e');
        resultados['auth'] = false;
      }

      // 5. Generar resumen
      final exitosas = resultados.values.where((v) => v == true).length;
      final total = resultados.length;

      print('📊 Resultados de prueba exhaustiva:');
      resultados.forEach((key, value) {
        print('   $key: ${value == true ? "✅" : "❌"}');
      });

      print(
        '📈 Éxito: $exitosas/$total (${(exitosas / total * 100).toStringAsFixed(1)}%)',
      );

      return resultados;
    } catch (e) {
      print('💥 Error en prueba exhaustiva: $e');
      return {'error': true, 'mensaje': e.toString()};
    }
  }

  /// Prueba Firestore con diferentes timeouts
  static Future<bool> _probarFirestoreConTimeout() async {
    try {
      // Intentar con timeout corto primero
      await _firestore
          .collection('test')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Timeout corto'),
          );
      return true;
    } catch (e) {
      if (e is TimeoutException) {
        print('⏱️  Timeout corto, intentando con timeout largo...');
        try {
          await _firestore
              .collection('test')
              .limit(1)
              .get()
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () => throw TimeoutException('Timeout largo'),
              );
          return true;
        } catch (e2) {
          print('❌ Timeout largo también falló');
          return false;
        }
      }
      return false;
    }
  }

  /// Prueba Auth con timeout
  static Future<bool> _probarAuthConTimeout() async {
    try {
      await _auth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timeout en Auth'),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Excepción personalizada para timeouts
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
