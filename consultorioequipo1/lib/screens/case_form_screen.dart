import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/caso.dart';
import 'camara.dart';
import 'package:camera/camera.dart';
import 'img_preview.dart';

class CaseFormScreen extends StatefulWidget {
  const CaseFormScreen({super.key});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String nombre = 'Divorcio Kevin';
  String? selectedTipo;
  String? selectedProcurador;
  String? selectedJuzgado;
  String? selectedDemandante;
  String? selectedDemandado;
  String fecha = '31/12/2025';

  final List<File> archivosAdjuntos = [];
  final List<String> tipos = ['Civil', 'Penal', 'Laboral'];
  final List<String> procuradores = ['Lic. Pérez', 'Lic. López'];
  final List<String> juzgados = ['Juzgado 1', 'Juzgado 2'];
  final List<String> personas = ['Juan García', 'Ana Torres', 'Carlos Díaz'];

  Future<void> _pickFromStorage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      final files = result.paths.map((path) => File(path!)).toList();
      setState(() => archivosAdjuntos.addAll(files));
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

    // You could handle the result here if you want to append images to archivosAdjuntos
  }

  void _removeFile(int index) {
    setState(() => archivosAdjuntos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final Color greenColor = Colors.green[800]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Caso'),
        backgroundColor: greenColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Nombre del caso *'),
              TextFormField(
                initialValue: nombre,
                onChanged: (val) => nombre = val,
                decoration: const InputDecoration(
                  hintText: 'Ej: Divorcio Kevin',
                ),
              ),
              const SizedBox(height: 10),
              const Text('Tipo de caso *'),
              DropdownButtonFormField<String>(
                value: selectedTipo,
                items: tipos
                    .map(
                      (tipo) =>
                          DropdownMenuItem(value: tipo, child: Text(tipo)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedTipo = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Procurador Asignado *'),
              DropdownButtonFormField<String>(
                value: selectedProcurador,
                items: procuradores
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedProcurador = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Juzgado *'),
              DropdownButtonFormField<String>(
                value: selectedJuzgado,
                items: juzgados
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: (val) => setState(() => selectedJuzgado = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Demandante *'),
              DropdownButtonFormField<String>(
                value: selectedDemandante,
                items: personas
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedDemandante = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Demandado *'),
              DropdownButtonFormField<String>(
                value: selectedDemandado,
                items: personas
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedDemandado = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Fecha límite *'),
              TextFormField(
                initialValue: fecha,
                onChanged: (val) => fecha = val,
                decoration: const InputDecoration(hintText: 'dd/mm/yyyy'),
              ),
              const SizedBox(height: 20),
              const Text('Adjuntar Archivos *'),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                    ),
                    icon: const Icon(Icons.folder),
                    label: const Text('Desde almacenamiento'),
                    onPressed: _pickFromStorage,
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
              if (archivosAdjuntos.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: archivosAdjuntos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return ListTile(
                      leading: Icon(Icons.insert_drive_file, color: greenColor),
                      title: Text(file.path.split('/').last),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeFile(index),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: greenColor),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newCaso = Caso(
                      nombre: nombre,
                      tipo: selectedTipo ?? '',
                      procurador: selectedProcurador ?? '',
                      juzgado: selectedJuzgado ?? '',
                      demandante: selectedDemandante ?? '',
                      demandado: selectedDemandado ?? '',
                      fecha: fecha,
                    );
                    Navigator.pop(context, newCaso);
                  }
                },
                child: const Text('Guardar Caso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
