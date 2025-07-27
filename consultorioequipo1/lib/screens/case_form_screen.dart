import 'package:flutter/material.dart';

class CaseFormScreen extends StatelessWidget {
  const CaseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Caso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Nombre del caso *'),
              TextFormField(decoration: const InputDecoration(hintText: 'Ej: Divorcio Kevin')),
              const SizedBox(height: 10),
              const Text('Tipo de caso *'),
              DropdownButtonFormField(items: const [], onChanged: (val) {}),
              const SizedBox(height: 10),
              const Text('Procurador Asignado *'),
              DropdownButtonFormField(items: const [], onChanged: (val) {}),
              const SizedBox(height: 10),
              const Text('Juzgado *'),
              DropdownButtonFormField(items: const [], onChanged: (val) {}),
              const SizedBox(height: 10),
              const Text('Demandante *'),
              DropdownButtonFormField(items: const [], onChanged: (val) {}),
              const SizedBox(height: 10),
              const Text('Demandado *'),
              DropdownButtonFormField(items: const [], onChanged: (val) {}),
              const SizedBox(height: 10),
              const Text('Fecha límite *'),
              TextFormField(decoration: const InputDecoration(hintText: 'dd/mm/yyyy')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caso guardado')));
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
