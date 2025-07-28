import 'package:flutter/material.dart';
import '../models/caso.dart';

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

  final List<String> tipos = ['Civil', 'Penal', 'Laboral'];
  final List<String> procuradores = ['Lic. Pérez', 'Lic. López'];
  final List<String> juzgados = ['Juzgado 1', 'Juzgado 2'];
  final List<String> personas = ['Juan García', 'Ana Torres', 'Carlos Díaz'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Caso')),
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
                decoration: const InputDecoration(hintText: 'Ej: Divorcio Kevin'),
              ),
              const SizedBox(height: 10),
              const Text('Tipo de caso *'),
              DropdownButtonFormField<String>(
                value: selectedTipo,
                items: tipos.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                onChanged: (val) => setState(() => selectedTipo = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Procurador Asignado *'),
              DropdownButtonFormField<String>(
                value: selectedProcurador,
                items: procuradores.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => selectedProcurador = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Juzgado *'),
              DropdownButtonFormField<String>(
                value: selectedJuzgado,
                items: juzgados.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                onChanged: (val) => setState(() => selectedJuzgado = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Demandante *'),
              DropdownButtonFormField<String>(
                value: selectedDemandante,
                items: personas.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => selectedDemandante = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              const Text('Demandado *'),
              DropdownButtonFormField<String>(
                value: selectedDemandado,
                items: personas.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
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
              ElevatedButton(
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
