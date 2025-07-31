import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../data/modelos/caso.dart';
import '../data/modelos/expediente.dart';
import '../data/modelos/tipocaso.dart';
import '../data/modelos/juzgado.dart';
import '../data/modelos/legitario.dart';
import '../data/modelos/procurador.dart';
import '../data/recursos/caso_service.dart';
import 'camara.dart';
import 'package:camera/camera.dart';
import 'img_preview.dart';
import '../data/recursos/auth_service.dart';

class CaseFormScreen extends StatefulWidget {
  const CaseFormScreen({super.key});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Paso 1: Archivos
  final List<File> _archivosAdjuntos = [];

  // Paso 2: Expediente
  final TextEditingController _nombreExpedienteController =
      TextEditingController();

  // Paso 3: Caso
  final TextEditingController _nombreCasoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _costoController = TextEditingController();
  DateTime? _fechaLimite;

  TipoCaso? _selectedTipoCaso;
  Juzgado? _selectedJuzgado;
  Legitario? _selectedDemandante;
  Legitario? _selectedDemandado;

  // Datos cargados
  List<TipoCaso> _tiposCaso = [];
  List<Juzgado> _juzgados = [];
  List<Legitario> _legitarios = [];
  List<Legitario> _demandantes = [];
  List<Legitario> _demandados = [];
  List<Procurador> _procuradores = [];

  // Procurador actual (obtenido del login)
  Map<String, dynamic>? _procuradorActual;
  Procurador? _selectedProcurador;

  bool _isLoading = false;
  String? _expedienteId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Obtener el procurador actual del login
      _procuradorActual = AuthService.procuradorActual;

      print('👤 Procurador actual:');
      print('  - Nombre: ${_procuradorActual?['nombre']}');
      print('  - Datos completos: $_procuradorActual');

      final tiposCaso = await CasoService.obtenerTiposCaso();
      final procuradores = await CasoService.obtenerProcuradores();
      final juzgados = await CasoService.obtenerJuzgados();
      final legitarios = await CasoService.obtenerLegitarios();

      // Obtener legitarios por rol específico
      final demandantes = await CasoService.obtenerLegitariosPorRol(
        'demandante',
      );
      final demandados = await CasoService.obtenerLegitariosPorRol('demandado');

      print('📊 Datos cargados:');
      print('  - Tipos de caso: ${tiposCaso.length}');
      print('  - Procuradores: ${procuradores.length}');
      print('  - Juzgados: ${juzgados.length}');
      print('  - Legitarios total: ${legitarios.length}');
      print('  - Demandantes: ${demandantes.length}');
      print('  - Demandados: ${demandados.length}');

      setState(() {
        _tiposCaso = tiposCaso;
        _procuradores = procuradores;
        _juzgados = juzgados;
        _legitarios = legitarios;
        _demandantes = demandantes;
        _demandados = demandados;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromStorage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      final files = result.paths.map((path) => File(path!)).toList();
      setState(() => _archivosAdjuntos.addAll(files));
    }
  }

  Future<void> _pickFromCamera() async {
    final cameras = await availableCameras();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(initialImages: [], cameras: cameras),
      ),
    );

    if (result != null && result is List<File>) {
      setState(() => _archivosAdjuntos.addAll(result));
    }
  }

  void _removeFile(int index) {
    setState(() => _archivosAdjuntos.removeAt(index));
  }

  Future<void> _crearExpediente() async {
    if (_nombreExpedienteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del expediente'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 Creando expediente: ${_nombreExpedienteController.text}');
      final expediente = Expediente(
        nombreExpediente: _nombreExpedienteController.text,
      );

      _expedienteId = await CasoService.crearExpediente(expediente);

      if (_expedienteId != null) {
        print('✅ Expediente creado con ID: $_expedienteId');
        print('📤 Archivos a guardar localmente: ${_archivosAdjuntos.length}');

        // Guardar archivos localmente
        int archivosGuardados = 0;
        for (int i = 0; i < _archivosAdjuntos.length; i++) {
          final archivo = _archivosAdjuntos[i];
          print(
            '💾 Guardando archivo ${i + 1}/${_archivosAdjuntos.length}: ${archivo.path}',
          );

          final archivoId = await CasoService.guardarArchivoLocal(
            archivo,
            _expedienteId!,
          );

          if (archivoId != null) {
            print('✅ Archivo guardado localmente con ID: $archivoId');
            archivosGuardados++;
          } else {
            print('❌ Error al guardar archivo localmente: ${archivo.path}');
          }
        }

        print(
          '🎯 Total de archivos guardados localmente: $archivosGuardados/${_archivosAdjuntos.length}',
        );

        if (archivosGuardados > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expediente creado y $archivosGuardados archivos guardados localmente',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Expediente creado pero no se pudieron guardar archivos',
              ),
            ),
          );
        }

        setState(() => _currentStep = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear el expediente')),
        );
      }
    } catch (e) {
      print('❌ Error al crear expediente: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _crearCaso() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación específica de cada campo
    String? errorMessage;
    if (_selectedTipoCaso == null) {
      errorMessage = 'Por favor selecciona un tipo de caso';
    } else if (_selectedProcurador == null) {
      errorMessage = 'Por favor selecciona un procurador';
    } else if (_selectedJuzgado == null) {
      errorMessage = 'Por favor selecciona un juzgado';
    } else if (_selectedDemandante == null) {
      errorMessage = 'Por favor selecciona un demandante';
    } else if (_selectedDemandado == null) {
      errorMessage = 'Por favor selecciona un demandado';
    } else if (_fechaLimite == null) {
      errorMessage = 'Por favor selecciona una fecha límite';
    } else if (_costoController.text.isEmpty) {
      errorMessage = 'Por favor ingresa el costo';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 Creando caso...');
      print(
        '  - Procurador: ${_selectedProcurador!.nombre} (ID: ${_selectedProcurador!.id})',
      );
      print('  - Tipo de caso: ${_selectedTipoCaso!.nombreCaso}');
      print('  - Juzgado: ${_selectedJuzgado!.nombreJuzgado}');
      print('  - Demandante: ${_selectedDemandante!.nombre}');
      print('  - Demandado: ${_selectedDemandado!.nombre}');
      print('  - Fecha límite: $_fechaLimite');
      print('  - Costo: ${_costoController.text}');

      final caso = Caso(
        nombreCaso: _nombreCasoController.text,
        tipocasoId: _selectedTipoCaso!.id!,
        expedienteId: _expedienteId!,
        procuradorId: _selectedProcurador!.id!,
        descripcion: _descripcionController.text,
        demandanteId: _selectedDemandante!.id!,
        demandadoId: _selectedDemandado!.id!,
        juzgadoId: _selectedJuzgado!.id!,
        plazo: _fechaLimite!,
        costo: double.parse(_costoController.text),
        estado: 'pendiente',
      );

      final casoId = await CasoService.crearCaso(caso);

      if (casoId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caso creado exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error al crear caso: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear caso: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _fechaLimite) {
      setState(() => _fechaLimite = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color greenColor = Colors.green[800]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Caso'),
        backgroundColor: greenColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Diagnóstico de Datos'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipos de caso: ${_tiposCaso.length}'),
                      Text('Juzgados: ${_juzgados.length}'),
                      Text('Legitarios: ${_legitarios.length}'),
                      const SizedBox(height: 10),
                      const Text(
                        'Detalles:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_tiposCaso.isNotEmpty)
                        Text(
                          'Tipos: ${_tiposCaso.map((t) => t.nombreCaso).join(', ')}',
                        ),
                      if (_juzgados.isNotEmpty)
                        Text(
                          'Juzgados: ${_juzgados.map((j) => j.nombreJuzgado).join(', ')}',
                        ),
                      if (_legitarios.isNotEmpty)
                        Text(
                          'Legitarios: ${_legitarios.map((l) => l.nombre).join(', ')}',
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
                        _cargarDatos();
                      },
                      child: const Text('Recargar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        print('🔍 Verificando juzgados...');
                        final juzgados = await CasoService.obtenerJuzgados();
                        print('📊 Juzgados encontrados: ${juzgados.length}');
                        for (final juzgado in juzgados) {
                          print(
                            '  - ${juzgado.nombreJuzgado} (${juzgado.direccion})',
                          );
                        }
                        _cargarDatos();
                      },
                      child: const Text('Verificar Juzgados'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        print('🔍 Diagnóstico de datos...');
                        _cargarDatos();
                      },
                      child: const Text('Diagnóstico Completo'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Diagnóstico',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_archivosAdjuntos.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor adjunta al menos un archivo'),
                      ),
                    );
                    return;
                  }
                  setState(() => _currentStep = 1);
                } else if (_currentStep == 1) {
                  _crearExpediente();
                } else if (_currentStep == 2) {
                  _crearCaso();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep = _currentStep - 1);
                }
              },
              steps: [
                // Paso 1: Adjuntar archivos
                Step(
                  title: const Text('Adjuntar Archivos'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selecciona los archivos para el expediente:'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                              ),
                              icon: const Icon(Icons.folder),
                              label: const Text('Desde almacenamiento'),
                              onPressed: _pickFromStorage,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.camera_alt, size: 32),
                            tooltip: 'Escanear Documento',
                            color: greenColor,
                            onPressed: _pickFromCamera,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_archivosAdjuntos.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _archivosAdjuntos.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final file = entry.value;
                            return ListTile(
                              leading: Icon(
                                Icons.insert_drive_file,
                                color: greenColor,
                              ),
                              title: Text(file.path.split('/').last),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeFile(index),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                  isActive: _currentStep >= 0,
                ),

                // Paso 2: Crear expediente
                Step(
                  title: const Text('Crear Expediente'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nombre del expediente:'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nombreExpedienteController,
                        decoration: const InputDecoration(
                          hintText: 'Ej: Expediente Divorcio García',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el nombre del expediente';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text('Archivos adjuntos: ${_archivosAdjuntos.length}'),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                ),

                // Paso 3: Crear caso
                Step(
                  title: const Text('Información del Caso'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre del caso:'),
                        TextFormField(
                          controller: _nombreCasoController,
                          decoration: const InputDecoration(
                            hintText: 'Ej: Divorcio García vs López',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el nombre del caso';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        const Text('Tipo de caso:'),
                        DropdownButtonFormField<TipoCaso>(
                          value: _selectedTipoCaso,
                          items: _tiposCaso
                              .map(
                                (tipo) => DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo.nombreCaso),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedTipoCaso = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona un tipo de caso';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        const Text('Procurador asignado:'),
                        DropdownButtonFormField<Procurador>(
                          value: _selectedProcurador,
                          items: _procuradores
                              .map(
                                (procurador) => DropdownMenuItem(
                                  value: procurador,
                                  child: Text(procurador.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedProcurador = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona un procurador';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        const Text('Juzgado:'),
                        DropdownButtonFormField<Juzgado>(
                          value: _selectedJuzgado,
                          items: _juzgados
                              .map(
                                (juz) => DropdownMenuItem(
                                  value: juz,
                                  child: Text(juz.nombreJuzgado),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedJuzgado = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona un juzgado';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        const Text('Demandante:'),
                        DropdownButtonFormField<Legitario>(
                          value: _selectedDemandante,
                          items: _demandantes
                              .map(
                                (leg) => DropdownMenuItem(
                                  value: leg,
                                  child: Text(leg.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDemandante = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona un demandante';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        const Text('Demandado:'),
                        DropdownButtonFormField<Legitario>(
                          value: _selectedDemandado,
                          items: _demandados
                              .map(
                                (leg) => DropdownMenuItem(
                                  value: leg,
                                  child: Text(leg.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDemandado = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona un demandado';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        const Text('Descripción:'),
                        TextFormField(
                          controller: _descripcionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Descripción del caso...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        const Text('Costo:'),
                        TextFormField(
                          controller: _costoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el costo';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Por favor ingresa un número válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        const Text('Fecha límite:'),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                controller: TextEditingController(
                                  text: _fechaLimite != null
                                      ? '${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}'
                                      : 'Seleccionar fecha',
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (value) {
                                  if (_fechaLimite == null) {
                                    return 'Por favor selecciona una fecha límite';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _selectDate,
                              child: const Text('Seleccionar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _nombreExpedienteController.dispose();
    _nombreCasoController.dispose();
    _descripcionController.dispose();
    _costoController.dispose();
    super.dispose();
  }
}
