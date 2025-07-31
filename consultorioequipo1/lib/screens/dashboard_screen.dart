import 'package:flutter/material.dart';
import 'case_form_screen.dart';
import 'expedientes_screen.dart';
import '../models/caso.dart';
import '../data/recursos/firebase_service.dart';
import 'pdfviewer.dart';
import 'img_preview.dart';
import 'package:camera/camera.dart';

late final List<CameraDescription> cameras;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Caso> casos = [];
  String searchQuery = '';

  void _addCaso(Caso caso) {
    setState(() => casos.add(caso));
  }

  void _cambiarEstado(Caso caso) async {
    final nuevoEstado = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('En proceso'),
            onTap: () => Navigator.pop(context, 'En proceso'),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Finalizado'),
            onTap: () => Navigator.pop(context, 'Finalizado'),
          ),
        ],
      ),
    );
    if (nuevoEstado != null) {
      setState(() => caso.estado = nuevoEstado);
    }
  }

  int _contarPorEstado(String estado) {
    final ahora = DateTime.now();
    return casos.where((c) {
      if (estado == 'Retrasado') {
        final fechaLimite = DateTime.tryParse(_formatearFecha(c.fecha));
        return c.estado != 'Finalizado' &&
            fechaLimite != null &&
            fechaLimite.isBefore(ahora);
      }
      return c.estado == estado;
    }).length;
  }

  String _formatearFecha(String fecha) {
    final partes = fecha.split('/');
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  }

  /// Muestra un diálogo con los detalles de la conexión
  void _mostrarDetallesConexion(Map<String, dynamic> resultados) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.analytics, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('📊 Detalles de Conexión Firebase'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...resultados.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value == true ? Icons.check_circle : Icons.error,
                      color: entry.value == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value == true ? "✅ Funcionando" : "❌ Falló"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resumen: ${resultados.values.where((v) => v == true).length}/${resultados.length} exitosas',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de confirmación para logout
  void _mostrarConfirmacionLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Aquí puedes agregar lógica de logout si es necesario
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCasos = casos
        .where(
          (c) => c.nombre.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UTH Consultorio Jurídico'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PdfViewerScreen()),
              );
            },
            tooltip: 'Ver PDFs',
          ),
          IconButton(
            icon: const Icon(
              Icons.camera_alt,
              size: 32,
            ), // Icono de cámara más grande
            tooltip:
                'Escanear Documento', // Texto que aparece al mantener presionado
            onPressed: () async {
              final cameras = await availableCameras();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ImagePreviewScreen(initialImages: [], cameras: cameras),
                ),
              );

              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Documento guardado exitosamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // Botón para verificación rápida
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () async {
              try {
                final resultados =
                    await FirebaseService.verificarTodasLasConexiones();

                // Mostrar diálogo con resultados
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(
                          resultados.values.every((conexion) => conexion)
                              ? Icons.check_circle
                              : Icons.warning,
                          color: resultados.values.every((conexion) => conexion)
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text('Verificación Rápida'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resultados.values.every((conexion) => conexion)
                              ? '✅ Todas las conexiones funcionan correctamente'
                              : '⚠️  Algunas conexiones fallaron',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ...resultados.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  entry.value
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: entry.value
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.key}: ${entry.value ? "OK" : "Error"}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Error'),
                      ],
                    ),
                    content: Text('❌ Error en verificación rápida: $e'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              }
            },
            tooltip: 'Verificación rápida Firebase',
          ),
          // Botón para verificación exhaustiva
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              try {
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Ejecutando prueba exhaustiva...'),
                      ],
                    ),
                  ),
                );

                final resultados =
                    await FirebaseService.probarConexionExhaustiva();

                // Cerrar diálogo de carga
                Navigator.of(context).pop();

                // Mostrar resultados detallados
                final exitosas = resultados.values
                    .where((v) => v == true)
                    .length;
                final total = resultados.length;
                final porcentaje = (exitosas / total * 100).toStringAsFixed(1);

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(
                          exitosas == total
                              ? Icons.check_circle
                              : Icons.analytics,
                          color: exitosas == total
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text('Prueba Exhaustiva'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Resultados: $exitosas/$total ($porcentaje%)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...resultados.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  entry.value == true
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: entry.value == true
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
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
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _mostrarDetallesConexion(resultados);
                        },
                        child: const Text('Ver Detalles'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                // Cerrar diálogo de carga si está abierto
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Error'),
                      ],
                    ),
                    content: Text('❌ Error en prueba exhaustiva: $e'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              }
            },
            tooltip: 'Prueba exhaustiva Firebase',
          ),
          // Botón de logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _mostrarConfirmacionLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Barra de navegación
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpedientesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Expedientes',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _DashboardCard(
                count: casos.length,
                label: 'Casos totales',
                color: Colors.green,
              ),
              _DashboardCard(
                count: _contarPorEstado('Pendiente'),
                label: 'Pendientes',
                color: Colors.orange,
              ),
              _DashboardCard(
                count: _contarPorEstado('En proceso'),
                label: 'En proceso',
                color: Colors.blue,
              ),
              _DashboardCard(
                count: _contarPorEstado('Finalizado'),
                label: 'Finalizados',
                color: Colors.green,
              ),
              _DashboardCard(
                count: _contarPorEstado('Retrasado'),
                label: 'Retrasados',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final newCaso = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CaseFormScreen()),
              );
              if (newCaso != null && newCaso is Caso) {
                _addCaso(newCaso);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Nuevo Caso'),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar caso...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCasos.length,
              itemBuilder: (context, index) {
                final caso = filteredCasos[index];
                final fechaLimite = DateTime.tryParse(
                  _formatearFecha(caso.fecha),
                );
                final estaRetrasado =
                    fechaLimite != null &&
                    fechaLimite.isBefore(DateTime.now()) &&
                    caso.estado != 'Finalizado';
                final estadoDisplay = estaRetrasado ? 'Retrasado' : caso.estado;
                final estadoColor = {
                  'Pendiente': Colors.orange,
                  'En proceso': Colors.blue,
                  'Finalizado': Colors.green,
                  'Retrasado': Colors.red,
                }[estadoDisplay]!;

                return GestureDetector(
                  onLongPress: () => _cambiarEstado(caso),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(caso.nombre),
                      subtitle: Text('${caso.tipo} • ${caso.fecha}'),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(caso.procurador),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: estadoColor.withOpacity(0.1),
                              border: Border.all(color: estadoColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estadoDisplay,
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _DashboardCard({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
