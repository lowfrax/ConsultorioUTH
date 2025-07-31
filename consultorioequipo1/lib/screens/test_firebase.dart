import 'package:flutter/material.dart';
import '../data/recursos/firebase_service.dart';
import '../data/recursos/caso_service.dart';

class TestFirebaseScreen extends StatefulWidget {
  const TestFirebaseScreen({super.key});

  @override
  State<TestFirebaseScreen> createState() => _TestFirebaseScreenState();
}

class _TestFirebaseScreenState extends State<TestFirebaseScreen> {
  Map<String, bool> resultados = {};
  Map<String, dynamic> resultadosExhaustivos = {};
  bool isLoading = false;
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _ejecutarPruebas();
  }

  Future<void> _ejecutarPruebas() async {
    setState(() {
      isLoading = true;
      mensaje = 'Ejecutando pruebas...';
    });

    try {
      // Prueba básica de conexión
      resultados = await FirebaseService.verificarTodasLasConexiones();

      // Prueba exhaustiva
      resultadosExhaustivos = await FirebaseService.probarConexionExhaustiva();

      setState(() {
        isLoading = false;
        mensaje = 'Pruebas completadas';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        mensaje = 'Error en las pruebas: $e';
      });
    }
  }

  Future<void> _crearDatosPrueba() async {
    setState(() {
      isLoading = true;
      mensaje = 'Creando datos de prueba...';
    });

    try {
      await CasoService.crearDatosPrueba();
      setState(() {
        isLoading = false;
        mensaje = 'Datos de prueba creados exitosamente';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        mensaje = 'Error al crear datos de prueba: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas Firebase'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _ejecutarPruebas,
            tooltip: 'Ejecutar pruebas',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensaje,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón para crear datos de prueba
                  ElevatedButton.icon(
                    onPressed: _crearDatosPrueba,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Datos de Prueba'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resultados de conexión básica
                  if (resultados.isNotEmpty) ...[
                    const Text(
                      'Resultados de Conexión:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...resultados.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              entry.value ? Icons.check_circle : Icons.error,
                              color: entry.value ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text('${entry.key}: ${entry.value ? "✅" : "❌"}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Resultados exhaustivos
                  if (resultadosExhaustivos.isNotEmpty) ...[
                    const Text(
                      'Prueba Exhaustiva:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...resultadosExhaustivos.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              entry.value == true
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: entry.value == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${entry.value == true ? "✅" : "❌"}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
