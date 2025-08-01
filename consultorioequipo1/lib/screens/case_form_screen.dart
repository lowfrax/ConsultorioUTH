import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../data/modelos/caso.dart';
import '../data/modelos/expediente.dart';
import '../data/modelos/tipocaso.dart';
import '../data/modelos/juzgado.dart';
import '../data/modelos/legitario.dart';
import '../data/modelos/procurador.dart';
import '../data/recursos/caso_service.dart';
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
  final _pageController = PageController();
  int _currentPage = 0;

  // Paso 1: Archivos y Expediente
  final List<File> _archivosAdjuntos = [];
  final TextEditingController _nombreExpedienteController =
      TextEditingController();

  // Paso 2: Información del Caso
  final TextEditingController _nombreCasoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _costoController = TextEditingController();
  DateTime? _fechaLimite;

  // Selecciones
  TipoCaso? _selectedTipoCaso;
  Juzgado? _selectedJuzgado;
  Legitario? _selectedDemandante;
  Legitario? _selectedDemandado;
  Procurador? _selectedProcurador;

  // Datos
  List<TipoCaso> _tiposCaso = [];
  List<Juzgado> _juzgados = [];
  List<Legitario> _demandantes = [];
  List<Legitario> _demandados = [];
  List<Procurador> _procuradores = [];

  // Estado
  bool _isLoading = false;
  String? _expedienteId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all data in parallel for better performance
      final results = await Future.wait([
        CasoService.obtenerTiposCaso(),
        CasoService.obtenerJuzgados(),
        CasoService.obtenerLegitariosPorRol('demandante'),
        CasoService.obtenerLegitariosPorRol('demandado'),
        CasoService.obtenerProcuradores(),
      ]);

      setState(() {
        _tiposCaso = results[0] as List<TipoCaso>;
        _juzgados = results[1] as List<Juzgado>;
        _demandantes = results[2] as List<Legitario>;
        _demandados = results[3] as List<Legitario>;
        _procuradores = results[4] as List<Procurador>;
      });

      // Auto-select the logged-in procurador after data is loaded
      _autoSelectProcurador();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: ${e.toString()}';
      });
      debugPrint('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _autoSelectProcurador() {
    final currentUser = AuthService.procuradorActual;
    if (currentUser != null && _procuradores.isNotEmpty) {
      try {
        final procurador = _procuradores.firstWhere(
          (p) => p.id == currentUser['id'], // Asegúrate que coincidan los IDs
          orElse: () => _procuradores.first, // Fallback al primer procurador
        );
        setState(() => _selectedProcurador = procurador);
      } catch (e) {
        debugPrint('Error al seleccionar procurador: $e');
        setState(
          () => _selectedProcurador = _procuradores.isNotEmpty
              ? _procuradores.first
              : null,
        );
      }
    }
  }

  Future<void> _pickFromStorage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        setState(() => _archivosAdjuntos.addAll(files));
      }
    } catch (e) {
      _showErrorSnackbar('Error al seleccionar archivos: ${e.toString()}');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final cameras = await availableCameras();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ImagePreviewScreen(initialImages: [], cameras: cameras),
        ),
      );

      if (result != null && result is List<File>) {
        setState(() => _archivosAdjuntos.addAll(result));
      }
    } catch (e) {
      _showErrorSnackbar('Error al acceder a la cámara: ${e.toString()}');
    }
  }

  void _removeFile(int index) {
    setState(() => _archivosAdjuntos.removeAt(index));
  }

  Future<void> _crearExpediente() async {
    if (_nombreExpedienteController.text.isEmpty) {
      _showErrorSnackbar('Por favor ingresa el nombre del expediente');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final expediente = Expediente(
        nombreExpediente: _nombreExpedienteController.text,
      );

      _expedienteId = await CasoService.crearExpediente(expediente);

      if (_expedienteId != null) {
        // Subir archivos en segundo plano
        _subirArchivosEnSegundoPlano();

        // Avanzar al siguiente paso
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = 1);
      } else {
        _showErrorSnackbar('Error al crear el expediente');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subirArchivosEnSegundoPlano() async {
    if (_archivosAdjuntos.isEmpty || _expedienteId == null) return;

    try {
      for (final archivo in _archivosAdjuntos) {
        await CasoService.subirArchivo(archivo, _expedienteId!);
      }
    } catch (e) {
      debugPrint('Error al subir archivos: $e');
      // No mostramos error al usuario ya que es en segundo plano
    }
  }

  Future<void> _crearCaso() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar selecciones
    if (_selectedTipoCaso == null ||
        _selectedJuzgado == null ||
        _selectedDemandante == null ||
        _selectedDemandado == null ||
        _selectedProcurador == null ||
        _fechaLimite == null) {
      _showErrorSnackbar('Por favor completa todos los campos requeridos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
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
        _showSuccessSnackbar('Caso creado exitosamente');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackbar('Error al crear el caso');
      }
    } catch (e) {
      _showErrorSnackbar('Error al crear caso: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _fechaLimite) {
      setState(() => _fechaLimite = picked);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildFileList() {
    if (_archivosAdjuntos.isEmpty) {
      return const Center(child: Text('No hay archivos adjuntos'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _archivosAdjuntos.length,
      itemBuilder: (context, index) {
        final file = _archivosAdjuntos[index];
        final fileName = file.path.split('/').last;
        final fileSize = (file.lengthSync() / 1024).toStringAsFixed(2);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(fileName, overflow: TextOverflow.ellipsis),
            subtitle: Text('$fileSize KB'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFile(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentos del Expediente',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Adjunta los documentos necesarios para el expediente',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Seleccionar archivos'),
                          onPressed: _pickFromStorage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cámara'),
                        onPressed: _pickFromCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFileList(),
          const SizedBox(height: 24),
          Text(
            'Información del Expediente',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nombreExpedienteController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del expediente*',
                      hintText: 'Ej: Expediente Divorcio García',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Caso',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreCasoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del caso*',
                        hintText: 'Ej: Divorcio García vs López',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cases),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipoCaso>(
                      value: _selectedTipoCaso,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de caso*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _tiposCaso.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo.nombreCaso),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTipoCaso = value),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un tipo de caso';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Procurador>(
                      value: _selectedProcurador,
                      decoration: const InputDecoration(
                        labelText: 'Procurador asignado*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _procuradores.map((procurador) {
                        return DropdownMenuItem(
                          value: procurador,
                          child: Text(procurador.nombre ?? 'Sin nombre'),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedProcurador = value),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un procurador';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Juzgado>(
                      value: _selectedJuzgado,
                      decoration: const InputDecoration(
                        labelText: 'Juzgado*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.gavel),
                      ),
                      items: _juzgados.map((juzgado) {
                        return DropdownMenuItem(
                          value: juzgado,
                          child: Text(juzgado.nombreJuzgado),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedJuzgado = value),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un juzgado';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partes involucradas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(
                        _selectedDemandante?.nombre ??
                            'Seleccionar demandante*',
                        style: TextStyle(
                          color: _selectedDemandante == null
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showLegitarioSelectionDialog(isDemandante: true),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: Colors.red,
                      ),
                      title: Text(
                        _selectedDemandado?.nombre ?? 'Seleccionar demandado*',
                        style: TextStyle(
                          color: _selectedDemandado == null
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showLegitarioSelectionDialog(isDemandante: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción del caso',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _costoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Costo estimado*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingresa un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _fechaLimite != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaLimite!)
                            : 'Seleccionar fecha límite*',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Fecha límite*',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _fechaLimite = null),
                        ),
                      ),
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (_fechaLimite == null) {
                          return 'Selecciona una fecha';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegitarioSelectionDialog({required bool isDemandante}) {
    final list = isDemandante ? _demandantes : _demandados;
    final currentSelection = isDemandante
        ? _selectedDemandante
        : _selectedDemandado;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDemandante ? 'Seleccionar Demandante' : 'Seleccionar Demandado',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final legitario = list[index];
              return RadioListTile<Legitario>(
                title: Text(legitario.nombre),
                subtitle: legitario.email != null
                    ? Text(legitario.email!)
                    : null,
                value: legitario,
                groupValue: currentSelection,
                onChanged: (value) {
                  setState(() {
                    if (isDemandante) {
                      _selectedDemandante = value;
                    } else {
                      _selectedDemandado = value;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCreateLegitarioDialog(isDemandante: isDemandante);
            },
            child: const Text('Crear Nuevo'),
          ),
        ],
      ),
    );
  }

  void _showCreateLegitarioDialog({required bool isDemandante}) {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDemandante ? 'Nuevo Demandante' : 'Nuevo Demandado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isEmpty) {
                _showErrorSnackbar('El nombre es requerido');
                return;
              }

              setState(() => _isLoading = true);
              Navigator.pop(context);

              try {
                final legitario = Legitario(
                  nombre: nombreController.text,
                  email: emailController.text,
                  telefono: telefonoController.text,
                  rolId: isDemandante ? 'demandante' : 'demandado',
                );

                final id = await CasoService.crearLegitario(legitario);

                if (id != null) {
                  setState(() {
                    if (isDemandante) {
                      _selectedDemandante = Legitario(
                        id: id,
                        nombre: nombreController.text,
                        email: emailController.text,
                        telefono: telefonoController.text,
                        rolId: 'demandante',
                      );
                      _demandantes.add(_selectedDemandante!);
                    } else {
                      _selectedDemandado = Legitario(
                        id: id,
                        nombre: nombreController.text,
                        email: emailController.text,
                        telefono: telefonoController.text,
                        rolId: 'demandado',
                      );
                      _demandados.add(_selectedDemandado!);
                    }
                  });
                }
              } catch (e) {
                _showErrorSnackbar('Error al crear legitario: ${e.toString()}');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Caso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ayuda'),
                  content: const Text(
                    'Complete todos los pasos para crear un nuevo caso:\n\n'
                    '1. Adjunte los documentos necesarios\n'
                    '2. Complete la información del expediente\n'
                    '3. Complete la información del caso\n',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentPage + 1) / 2,
                  backgroundColor: Colors.grey[200],
                  minHeight: 4,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [_buildStep1(), _buildStep2()],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Atrás'),
                ),
              ),
            if (_currentPage > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_currentPage == 0) {
                    await _crearExpediente();
                  } else {
                    await _crearCaso();
                  }
                },
                child: Text(_currentPage == 0 ? 'Continuar' : 'Guardar Caso'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombreExpedienteController.dispose();
    _nombreCasoController.dispose();
    _descripcionController.dispose();
    _costoController.dispose();
    super.dispose();
  }
}
