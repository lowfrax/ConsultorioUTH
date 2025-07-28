import 'package:flutter/material.dart';
import 'case_form_screen.dart';
import '../models/caso.dart';

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
        return c.estado != 'Finalizado' && fechaLimite != null && fechaLimite.isBefore(ahora);
      }
      return c.estado == estado;
    }).length;
  }

  String _formatearFecha(String fecha) {
    final partes = fecha.split('/');
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredCasos = casos.where((c) => c.nombre.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyApp'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'UTH Consultorio Jurídico',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _DashboardCard(count: casos.length, label: 'Casos totales', color: Colors.green),
              _DashboardCard(count: _contarPorEstado('Pendiente'), label: 'Pendientes', color: Colors.orange),
              _DashboardCard(count: _contarPorEstado('En proceso'), label: 'En proceso', color: Colors.blue),
              _DashboardCard(count: _contarPorEstado('Finalizado'), label: 'Finalizados', color: Colors.green),
              _DashboardCard(count: _contarPorEstado('Retrasado'), label: 'Retrasados', color: Colors.red),
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
                final fechaLimite = DateTime.tryParse(_formatearFecha(caso.fecha));
                final estaRetrasado = fechaLimite != null && fechaLimite.isBefore(DateTime.now()) && caso.estado != 'Finalizado';
                final estadoDisplay = estaRetrasado ? 'Retrasado' : caso.estado;
                final estadoColor = {
                  'Pendiente': Colors.orange,
                  'En proceso': Colors.blue,
                  'Finalizado': Colors.green,
                  'Retrasado': Colors.red
                }[estadoDisplay]!;

                return GestureDetector(
                  onLongPress: () => _cambiarEstado(caso),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      title: Text(caso.nombre),
                      subtitle: Text('${caso.tipo} • ${caso.fecha}'),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(caso.procurador),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estadoColor.withOpacity(0.1),
                              border: Border.all(color: estadoColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estadoDisplay,
                              style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _DashboardCard({required this.count, required this.label, required this.color});

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
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}