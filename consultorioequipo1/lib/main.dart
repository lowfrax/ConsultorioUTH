import 'package:consultorioequipo1/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'data/recursos/firebase_service.dart';
import 'data/recursos/db.dart';
import 'data/recursos/auth_service.dart';
import 'test_firebase.dart';
import 'test_login.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  try {
    // Inicialización de Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🚀 Firebase inicializado correctamente');

    // Ejecutar pruebas de Firebase
    await FirebaseTest.ejecutarPruebas();

    // Ejecutar pruebas específicas del login
    await LoginTest.ejecutarPruebasLogin();

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
        await AuthService.verificarEstructuraBD();

        // Verificar usuario específico
        await LoginTest.verificarUsuario('lowfrax', 'casa');

        // Listar usuarios para verificación
        await LoginTest.listarUsuarios();
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
