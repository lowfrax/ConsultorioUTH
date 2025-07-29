import 'package:consultorioequipo1/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'data/recursos/firebase_service.dart';
import 'data/recursos/db.dart';
import 'test_firebase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicialización de Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🚀 Firebase inicializado correctamente');

    // Ejecutar pruebas de Firebase
    await FirebaseTest.ejecutarPruebas();

    // Realizar prueba exhaustiva de conexión
    final resultados = await FirebaseService.probarConexionExhaustiva();

    // Mostrar resumen final
    if (resultados.containsKey('error')) {
      print('💥 Error en la verificación: ${resultados['mensaje']}');
    } else {
      final exitosas = resultados.values.where((v) => v == true).length;
      final total = resultados.length;

      if (exitosas == total) {
        print('🎉 Conexión completa a Firebase establecida correctamente');

        // Verificar estructura de la base de datos
        await DatabaseService.verificarEstructuraBD();

        // Verificar si existe el usuario de prueba
        final usuarioExiste = await DatabaseService.verificarUsuario(
          'lowfrax',
          'casa',
        );

        if (!usuarioExiste) {
          print('🔧 Usuario de prueba no existe, creando...');
          await DatabaseService.crearUsuarioPrueba();
        } else {
          print('✅ Usuario de prueba ya existe');
        }

        // Listar usuarios para verificación
        await DatabaseService.listarUsuarios();
      } else {
        print('⚠️  Problemas detectados en la conexión a Firebase');
        print('📊 Éxito: $exitosas/$total');
      }
    }
  } catch (e) {
    print('💥 Error durante la inicialización de Firebase: $e');
    print('⚠️  La aplicación continuará sin conexión a Firebase');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTH Consultorio Jurídico',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(),
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}
