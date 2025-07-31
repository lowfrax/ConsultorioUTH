import 'package:flutter/material.dart';
import 'case_form_screen.dart';
import 'expedientes_screen.dart';
import '../data/modelos/caso.dart';
import '../data/modelos/tipocaso.dart';
import '../data/modelos/juzgado.dart';
import '../data/modelos/legitario.dart';
import '../data/modelos/procurador.dart';
import '../data/recursos/caso_service.dart';
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
  List<Caso> casos = [];
  List<TipoCaso> tiposCaso = [];
  List<Juzgado> juzgados = [];
  List<Legitario> legitarios = [];
  List<Procurador> procuradores = [];
  String searchQuery = '';
  bool isLoading = true;
  Map<String, int> estadisticas = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => isLoading = true);

    try {
      final casosData = await CasoService.obtenerCasos();
      final tiposCasoData = await CasoService.obtenerTiposCaso();
      final juzgadosData = await CasoService.obtenerJuzgados();
      final legitariosData = await CasoService.obtenerLegitarios();
      final procuradoresData = await CasoService.obtenerProcuradores();
      final estadisticasData = await CasoService.obtenerEstadisticas();

      setState(() {
        casos = casosData;
        tiposCaso = tiposCasoData;
        juzgados = juzgadosData;
        legitarios = legitariosData;
        procuradores = procuradoresData;
        estadisticas = estadisticasData;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _cargarDatosSinFiltros() async {
    setState(() => isLoading = true);

    try {
      final casosData = await CasoService.obtenerTodosLosCasos();
      final tiposCasoData = await CasoService.obtenerTodosLosTiposCaso();
      final juzgadosData = await CasoService.obtenerTodosLosJuzgados();
      final legitariosData = await CasoService.obtenerTodosLosLegitarios();
      final procuradoresData = await CasoService.obtenerTodosLosProcuradores();

      // Filtrar manualmente los datos no eliminados
      final casosFiltrados = casosData.where((c) => !c.eliminado).toList();
      final tiposFiltrados = tiposCasoData.where((t) => !t.eliminado).toList();
      final juzgadosFiltrados = juzgadosData
          .where((j) => !j.eliminado)
          .toList();
      final legitariosFiltrados = legitariosData
          .where((l) => !l.eliminado)
          .toList();
      final procuradoresFiltrados = procuradoresData
          .where((p) => !p.eliminado)
          .toList();

      // Calcular estadísticas manualmente
      final estadisticasData = {
        'pendientes': casosFiltrados
            .where((c) => c.estado == 'pendiente')
            .length,
        'en_proceso': casosFiltrados
            .where((c) => c.estado == 'en proceso')
            .length,
        'finalizados': casosFiltrados
            .where((c) => c.estado == 'finalizado')
            .length,
        'retrasados': casosFiltrados
            .where((c) => c.estado == 'retrasado')
            .length,
        'total': casosFiltrados.length,
      };

      setState(() {
        casos = casosFiltrados;
        tiposCaso = tiposFiltrados;
        juzgados = juzgadosFiltrados;
        legitarios = legitariosFiltrados;
        procuradores = procuradoresFiltrados;
        estadisticas = estadisticasData;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos sin filtros: $e');
      setState(() => isLoading = false);
    }
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
            onTap: () => Navigator.pop(context, 'en proceso'),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('Finalizado'),
            onTap: () => Navigator.pop(context, 'finalizado'),
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Retrasado'),
            onTap: () => Navigator.pop(context, 'retrasado'),
          ),
        ],
      ),
    );

    if (nuevoEstado != null) {
      final success = await CasoService.cambiarEstadoCaso(
        caso.id!,
        nuevoEstado,
      );
      if (success) {
        await _cargarDatos(); // Recargar datos
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estado cambiado a: $nuevoEstado')),
          );
        }
      }
    }
  }

  String _obtenerNombreTipoCaso(String tipoCasoId) {
    final tipo = tiposCaso.firstWhere(
      (t) => t.id == tipoCasoId,
      orElse: () => TipoCaso(nombreCaso: 'Desconocido', descripcion: ''),
    );
    return tipo.nombreCaso;
  }

  String _obtenerNombreProcurador(String procuradorId) {
    final procurador = procuradores.firstWhere(
      (p) => p.id == procuradorId,
      orElse: () => Procurador(
        nombre: 'Desconocido',
        usuario: '',
        password: '',
        email: '',
        telefono: '',
        nCuenta: '',
        creadoEl: DateTime.now(),
        actualizadoEl: DateTime.now(),
      ),
    );
    return procurador.nombre;
  }

  String _obtenerNombreJuzgado(String juzgadoId) {
    final juzgado = juzgados.firstWhere(
      (j) => j.id == juzgadoId,
      orElse: () =>
          Juzgado(nombreJuzgado: 'Desconocido', direccion: '', telefono: ''),
    );
    return juzgado.nombreJuzgado;
  }

  String _obtenerNombreLegitario(String legitarioId) {
    final legitario = legitarios.firstWhere(
      (l) => l.id == legitarioId,
      orElse: () => Legitario(
        rolId: '',
        nombre: 'Desconocido',
        email: '',
        direccion: '',
        telefono: '',
      ),
    );
    return legitario.nombre;
  }

  List<Caso> get filteredCasos {
    if (searchQuery.isEmpty) return casos;
    return casos
        .where(
          (caso) =>
              caso.nombreCaso.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              _obtenerNombreTipoCaso(
                caso.tipocasoId,
              ).toLowerCase().contains(searchQuery.toLowerCase()) ||
              _obtenerNombreProcurador(
                caso.procuradorId,
              ).toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _crearDatosPrueba() async {
    setState(() => isLoading = true);

    try {
      await CasoService.crearDatosPrueba();
      await _cargarDatos(); // Recargar datos después de crear los de prueba

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos de prueba creados exitosamente'),
          ),
        );
      }
    } catch (e) {
      print('Error al crear datos de prueba: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al crear datos de prueba: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
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
    final Color greenColor = Colors.green[800]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: greenColor,
        actions: [
          // Botón para crear datos de prueba
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _crearDatosPrueba,
            tooltip: 'Crear datos de prueba',
          ),
          // Botón para probar carga de datos
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => isLoading = true);
              await _cargarDatos();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Datos cargados: ${casos.length} casos, ${tiposCaso.length} tipos, ${juzgados.length} juzgados, ${legitarios.length} legitarios, ${procuradores.length} procuradores',
                    ),
                  ),
                );
              }
            },
            tooltip: 'Recargar datos',
          ),
          // Botón para diagnóstico
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              setState(() => isLoading = true);

              try {
                final todosCasos = await CasoService.obtenerTodosLosCasos();
                final todosTipos = await CasoService.obtenerTodosLosTiposCaso();
                final todosJuzgados =
                    await CasoService.obtenerTodosLosJuzgados();
                final todosLegitarios =
                    await CasoService.obtenerTodosLosLegitarios();
                final todosProcuradores =
                    await CasoService.obtenerTodosLosProcuradores();

                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Diagnóstico de Datos'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📊 Todos los casos: ${todosCasos.length}'),
                          Text('🏷️ Todos los tipos: ${todosTipos.length}'),
                          Text(
                            '⚖️ Todos los juzgados: ${todosJuzgados.length}',
                          ),
                          Text(
                            '👥 Todos los legitarios: ${todosLegitarios.length}',
                          ),
                          Text(
                            '👨‍💼 Todos los procuradores: ${todosProcuradores.length}',
                          ),
                          const SizedBox(height: 10),
                          Text('📊 Casos filtrados: ${casos.length}'),
                          Text('🏷️ Tipos filtrados: ${tiposCaso.length}'),
                          Text('⚖️ Juzgados filtrados: ${juzgados.length}'),
                          Text('👥 Legitarios filtrados: ${legitarios.length}'),
                          Text(
                            '👨‍💼 Procuradores filtrados: ${procuradores.length}',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _cargarDatosSinFiltros();
                          },
                          child: const Text('Cargar sin filtros'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                print('Error en diagnóstico: $e');
              } finally {
                setState(() => isLoading = false);
              }
            },
            tooltip: 'Diagnóstico de datos',
          ),
          // Botón para escanear documentos
          IconButton(
            icon: const Icon(Icons.camera_alt, size: 32),
            tooltip: 'Escanear Documento',
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

                Navigator.of(context).pop();

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
                    ],
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop(); // Cerrar diálogo de carga
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
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ExpedientesScreen(),
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
                        ],
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
                      count: estadisticas['total'] ?? 0,
                      label: 'Casos totales',
                      color: Colors.green,
                    ),
                    _DashboardCard(
                      count: estadisticas['pendientes'] ?? 0,
                      label: 'Pendientes',
                      color: Colors.orange,
                    ),
                    _DashboardCard(
                      count: estadisticas['en_proceso'] ?? 0,
                      label: 'En proceso',
                      color: Colors.blue,
                    ),
                    _DashboardCard(
                      count: estadisticas['finalizados'] ?? 0,
                      label: 'Finalizados',
                      color: Colors.green,
                    ),
                    _DashboardCard(
                      count: estadisticas['retrasados'] ?? 0,
                      label: 'Retrasados',
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CaseFormScreen(),
                      ),
                    );
                    if (result == true) {
                      await _cargarDatos(); // Recargar datos
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Nuevo Caso'),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
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
                      final estaRetrasado =
                          caso.plazo.isBefore(DateTime.now()) &&
                          caso.estado != 'finalizado';
                      final estadoDisplay = estaRetrasado
                          ? 'retrasado'
                          : caso.estado;
                      final estadoColor = {
                        'pendiente': Colors.orange,
                        'en proceso': Colors.blue,
                        'finalizado': Colors.green,
                        'retrasado': Colors.red,
                      }[estadoDisplay]!;

                      return GestureDetector(
                        onLongPress: () => _cambiarEstado(caso),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(caso.nombreCaso),
                            subtitle: Text(
                              '${_obtenerNombreTipoCaso(caso.tipocasoId)} • ${caso.plazo.day}/${caso.plazo.month}/${caso.plazo.year}',
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _obtenerNombreProcurador(caso.procuradorId),
                                ),
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
                                    estadoDisplay.toUpperCase(),
                                    style: TextStyle(
                                      color: estadoColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
