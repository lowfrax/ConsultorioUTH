import 'package:flutter/material.dart';
import 'case_form_screen.dart';
import 'expedientes_screen.dart';
import '../data/modelos/caso.dart';
import '../data/modelos/tipocaso.dart';
import '../data/modelos/juzgado.dart';
import '../data/modelos/legitario.dart';
import '../data/modelos/procurador.dart';
import '../data/modelos/expediente.dart';
import '../data/modelos/archivoexpediente.dart';
import '../data/recursos/caso_service.dart';
import '../data/recursos/firebase_service.dart';
import 'pdfviewer.dart';
import 'img_preview.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widget.dart';
import 'package:intl/intl.dart';
import 'package:consultorioequipo1/data/recursos/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<Expediente> expedientes = [];
  String searchQuery = '';
  bool isLoading = true;
  Map<String, int> estadisticas = {};
  String? currentProcuradorId;

  // Filtros avanzados
  String? filterTipoCaso;
  String? filterEstado;
  DateTime? filterFechaDesde;
  DateTime? filterFechaHasta;
  String? filterDemandante;
  String? filterDemandado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

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

  Future<void> _cargarDatos() async {
    setState(() => isLoading = true);

    try {
      print('🔄 Cargando datos del dashboard...');

      final procurador = AuthService.procuradorActual;
      if (procurador == null || procurador['id'] == null) {
        print('❌ No hay procurador autenticado o falta ID');
        setState(() => isLoading = false);
        return;
      }

      final procuradorId = procurador['id'];
      print('🔍 Procurador actual ID: $procuradorId');

      // Cargar todos los datos necesarios en paralelo
      final results = await Future.wait([
        CasoService.obtenerCasosPorProcurador(procuradorId),
        CasoService.obtenerTiposCaso(),
        CasoService.obtenerJuzgados(),
        CasoService.obtenerLegitariosPorRol('demandante'),
        CasoService.obtenerLegitariosPorRol('demandado'),
        CasoService.obtenerProcuradores(),
      ]);

      final casosData = results[0] as List<Caso>;
      print('✅ Casos cargados: ${casosData.length}');

      // Debug: imprimir los casos obtenidos
      for (final caso in casosData) {
        print('Caso: ${caso.nombreCaso}, Estado: ${caso.estado}');
        print('Expediente ID: ${caso.expedienteId}');
        if (caso.expediente != null) {
          print('Expediente: ${caso.expediente!.nombreExpediente}');
        }
        print('Archivos: ${caso.archivos.length}');
      }

      setState(() {
        casos = casosData;
        tiposCaso = results[1] as List<TipoCaso>;
        juzgados = results[2] as List<Juzgado>;
        legitarios = [
          ...(results[3] as List<Legitario>),
          ...(results[4] as List<Legitario>),
        ];
        procuradores = results[5] as List<Procurador>;
        estadisticas = _calcularEstadisticas(casosData);
        isLoading = false;
      });

      print('📊 Estadísticas calculadas: $estadisticas');
    } catch (e) {
      print('❌ Error al cargar datos: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  Future<String?> _obtenerProcuradorIdActual() async {
    final procuradorActual = AuthService.procuradorActual;
    if (procuradorActual == null || procuradorActual['id'] == null) {
      print('⚠️ Procurador no autenticado');
      return null;
    }
    return procuradorActual['id'] as String;
  }

  List<Caso> _actualizarEstadosSegunFechas(List<Caso> casos) {
    final ahora = DateTime.now();
    return casos.map((caso) {
      if (caso.estado != 'finalizado') {
        if (caso.plazo.isBefore(ahora)) {
          return caso.copyWith(estado: 'retrasado');
        } else {
          return caso.copyWith(estado: 'pendiente');
        }
      }
      return caso;
    }).toList();
  }

  Map<String, int> _calcularEstadisticas(List<Caso> casos) {
    return {
      'pendientes': casos.where((c) => c.estado == 'pendiente').length,
      'en_proceso': casos.where((c) => c.estado == 'en proceso').length,
      'finalizados': casos.where((c) => c.estado == 'finalizado').length,
      'retrasados': casos.where((c) => c.estado == 'retrasado').length,
      'total': casos.length,
    };
  }

  void _mostrarFiltrosAvanzados() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filtros Avanzados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: filterTipoCaso,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de caso',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...tiposCaso
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo.id,
                              child: Text(tipo.nombreCaso),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (value) =>
                        setState(() => filterTipoCaso = value),
                  ),

                  DropdownButtonFormField<String>(
                    value: filterEstado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      const DropdownMenuItem(
                        value: 'pendiente',
                        child: Text('Pendiente'),
                      ),
                      const DropdownMenuItem(
                        value: 'en proceso',
                        child: Text('En proceso'),
                      ),
                      const DropdownMenuItem(
                        value: 'finalizado',
                        child: Text('Finalizado'),
                      ),
                      const DropdownMenuItem(
                        value: 'retrasado',
                        child: Text('Retrasado'),
                      ),
                    ],
                    onChanged: (value) => setState(() => filterEstado = value),
                  ),

                  ListTile(
                    title: const Text('Fecha desde'),
                    subtitle: Text(
                      filterFechaDesde == null
                          ? 'Seleccionar fecha'
                          : _formatearFecha(filterFechaDesde!),
                    ),
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null) {
                        setState(() => filterFechaDesde = fecha);
                      }
                    },
                  ),

                  ListTile(
                    title: const Text('Fecha hasta'),
                    subtitle: Text(
                      filterFechaHasta == null
                          ? 'Seleccionar fecha'
                          : _formatearFecha(filterFechaHasta!),
                    ),
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null) {
                        setState(() => filterFechaHasta = fecha);
                      }
                    },
                  ),

                  DropdownButtonFormField<String>(
                    value: filterDemandante,
                    decoration: const InputDecoration(labelText: 'Demandante'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...legitarios
                          .where((l) => l.rolId == 'demandante')
                          .map(
                            (legitario) => DropdownMenuItem(
                              value: legitario.id,
                              child: Text(legitario.nombre),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (value) =>
                        setState(() => filterDemandante = value),
                  ),

                  DropdownButtonFormField<String>(
                    value: filterDemandado,
                    decoration: const InputDecoration(labelText: 'Demandado'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...legitarios
                          .where((l) => l.rolId == 'demandado')
                          .map(
                            (legitario) => DropdownMenuItem(
                              value: legitario.id,
                              child: Text(legitario.nombre),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (value) =>
                        setState(() => filterDemandado = value),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            filterTipoCaso = null;
                            filterEstado = null;
                            filterFechaDesde = null;
                            filterFechaHasta = null;
                            filterDemandante = null;
                            filterDemandado = null;
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _obtenerNombreTipoCaso(String tipoCasoId) {
    if (tipoCasoId.isEmpty) return 'Sin tipo';
    final tipo = tiposCaso.firstWhere(
      (t) => t.id == tipoCasoId,
      orElse: () => TipoCaso(nombreCaso: 'Desconocido', descripcion: ''),
    );
    return tipo.nombreCaso;
  }

  String _obtenerNombreProcurador(String procuradorId) {
    if (procuradorId.isEmpty) return 'Sin procurador';
    final procurador = procuradores.firstWhere(
      (p) => p.id == procuradorId,
      orElse: () => Procurador(
        nombre: '',
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
    if (juzgadoId.isEmpty) return 'Sin juzgado';
    final juzgado = juzgados.firstWhere(
      (j) => j.id == juzgadoId,
      orElse: () =>
          Juzgado(nombreJuzgado: 'Desconocido', direccion: '', telefono: ''),
    );
    return juzgado.nombreJuzgado;
  }

  String _obtenerNombreLegitario(String legitarioId) {
    if (legitarioId.isEmpty) return 'Sin legitario';
    final legitario = legitarios.firstWhere(
      (l) => l.id == legitarioId,
      orElse: () =>
          Legitario(rolId: '', nombre: 'Desconocido', email: '', telefono: ''),
    );
    return legitario.nombre;
  }

  List<Caso> get filteredCasos {
    List<Caso> filtered = casos;

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((caso) {
        final nombreCaso = caso.nombreCaso.toLowerCase();
        final tipoCaso = _obtenerNombreTipoCaso(caso.tipocasoId).toLowerCase();
        final procurador = _obtenerNombreProcurador(
          caso.procuradorId,
        ).toLowerCase();
        final demandante = _obtenerNombreLegitario(
          caso.demandanteId,
        ).toLowerCase();
        final demandado = _obtenerNombreLegitario(
          caso.demandadoId,
        ).toLowerCase();

        return nombreCaso.contains(searchQuery.toLowerCase()) ||
            tipoCaso.contains(searchQuery.toLowerCase()) ||
            procurador.contains(searchQuery.toLowerCase()) ||
            demandante.contains(searchQuery.toLowerCase()) ||
            demandado.contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (filterTipoCaso != null) {
      filtered = filtered.where((c) => c.tipocasoId == filterTipoCaso).toList();
    }

    if (filterEstado != null) {
      filtered = filtered.where((c) => c.estado == filterEstado).toList();
    }

    if (filterFechaDesde != null) {
      filtered = filtered
          .where((c) => c.plazo.isAfter(filterFechaDesde!))
          .toList();
    }

    if (filterFechaHasta != null) {
      filtered = filtered
          .where((c) => c.plazo.isBefore(filterFechaHasta!))
          .toList();
    }

    if (filterDemandante != null) {
      filtered = filtered
          .where((c) => c.demandanteId == filterDemandante)
          .toList();
    }

    if (filterDemandado != null) {
      filtered = filtered
          .where((c) => c.demandadoId == filterDemandado)
          .toList();
    }

    return filtered;
  }

  Future<void> _cambiarEstado(Caso caso) async {
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
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estado cambiado a: $nuevoEstado')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color greenColor = Colors.green[800]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: greenColor,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _mostrarConfirmacionLogout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    DashboardCard(
                      count: estadisticas['total'] ?? 0,
                      label: 'Casos totales',
                      color: Colors.green,
                    ),
                    DashboardCard(
                      count: estadisticas['pendientes'] ?? 0,
                      label: 'Pendientes',
                      color: Colors.orange,
                    ),
                    DashboardCard(
                      count: estadisticas['en_proceso'] ?? 0,
                      label: 'En proceso',
                      color: Colors.blue,
                    ),
                    DashboardCard(
                      count: estadisticas['finalizados'] ?? 0,
                      label: 'Finalizados',
                      color: Colors.green,
                    ),
                    DashboardCard(
                      count: estadisticas['retrasados'] ?? 0,
                      label: 'Retrasados',
                      color: Colors.red,
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CaseFormScreen(),
                        ),
                      );
                      if (result == true) {
                        await _cargarDatos();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Nuevo Caso',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Buscar caso...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: _mostrarFiltrosAvanzados,
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                        ),
                      ),
                    ],
                  ),
                ),

                if (filterTipoCaso != null ||
                    filterEstado != null ||
                    filterFechaDesde != null ||
                    filterFechaHasta != null ||
                    filterDemandante != null ||
                    filterDemandado != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (filterTipoCaso != null)
                          Chip(
                            label: Text(
                              'Tipo: ${_obtenerNombreTipoCaso(filterTipoCaso!)}',
                            ),
                            onDeleted: () =>
                                setState(() => filterTipoCaso = null),
                          ),
                        if (filterEstado != null)
                          Chip(
                            label: Text('Estado: ${filterEstado!}'),
                            onDeleted: () =>
                                setState(() => filterEstado = null),
                          ),
                        if (filterFechaDesde != null)
                          Chip(
                            label: Text(
                              'Desde: ${_formatearFecha(filterFechaDesde!)}',
                            ),
                            onDeleted: () =>
                                setState(() => filterFechaDesde = null),
                          ),
                        if (filterFechaHasta != null)
                          Chip(
                            label: Text(
                              'Hasta: ${_formatearFecha(filterFechaHasta!)}',
                            ),
                            onDeleted: () =>
                                setState(() => filterFechaHasta = null),
                          ),
                        if (filterDemandante != null)
                          Chip(
                            label: Text(
                              'Demandante: ${_obtenerNombreLegitario(filterDemandante!)}',
                            ),
                            onDeleted: () =>
                                setState(() => filterDemandante = null),
                          ),
                        if (filterDemandado != null)
                          Chip(
                            label: Text(
                              'Demandado: ${_obtenerNombreLegitario(filterDemandado!)}',
                            ),
                            onDeleted: () =>
                                setState(() => filterDemandado = null),
                          ),
                      ],
                    ),
                  ),

                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCasos.length,
                    itemBuilder: (context, index) {
                      final caso = filteredCasos[index];
                      final estadoColor = {
                        'pendiente': Colors.orange,
                        'en proceso': Colors.blue,
                        'finalizado': Colors.green,
                        'retrasado': Colors.red,
                      }[caso.estado]!;

                      return GestureDetector(
                        onLongPress: () => _cambiarEstado(caso),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(caso.nombreCaso),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_obtenerNombreTipoCaso(caso.tipocasoId)),
                                Text('Plazo: ${_formatearFecha(caso.plazo)}'),
                                Text(
                                  'Demandante: ${_obtenerNombreLegitario(caso.demandanteId)}',
                                ),
                                Text(
                                  'Demandado: ${_obtenerNombreLegitario(caso.demandadoId)}',
                                ),
                              ],
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
                                    caso.estado.toUpperCase(),
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
