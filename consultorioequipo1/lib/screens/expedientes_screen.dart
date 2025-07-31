import 'package:flutter/material.dart';
import '../data/modelos/expediente.dart';
import '../data/modelos/archivoexpediente.dart';
import '../data/recursos/caso_service.dart';
import 'pdfviewer.dart';

class ExpedientesScreen extends StatefulWidget {
  const ExpedientesScreen({super.key});

  @override
  State<ExpedientesScreen> createState() => _ExpedientesScreenState();
}

class _ExpedientesScreenState extends State<ExpedientesScreen> {
  List<Expediente> expedientes = [];
  Map<String, List<ArchivoExpediente>> archivosPorExpediente = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarExpedientes();
  }

  Future<void> _cargarExpedientes() async {
    setState(() => isLoading = true);

    try {
      final expedientesData = await CasoService.obtenerExpedientes();

      // Cargar archivos para cada expediente
      final archivosMap = <String, List<ArchivoExpediente>>{};
      for (final expediente in expedientesData) {
        final archivos = await CasoService.obtenerArchivosExpediente(
          expediente.id!,
        );
        archivosMap[expediente.id!] = archivos;
      }

      setState(() {
        expedientes = expedientesData;
        archivosPorExpediente = archivosMap;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar expedientes: $e');
      setState(() => isLoading = false);
    }
  }

  void _verArchivo(ArchivoExpediente archivo) {
    // Aquí puedes implementar la lógica para ver el archivo
    // Por ahora solo mostramos un diálogo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${archivo.nombreArchivo}'),
            Text('Formato: ${archivo.formatoActual}'),
            Text('Tamaño: ${archivo.urlArchivo.length} bytes'),
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
              // Aquí puedes abrir el archivo en el visor PDF
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PdfViewerScreen()),
              );
            },
            child: const Text('Ver'),
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
        title: const Text('Expedientes'),
        backgroundColor: greenColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarExpedientes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expedientes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay expedientes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los expedientes aparecerán aquí cuando crees casos',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: expedientes.length,
              itemBuilder: (context, index) {
                final expediente = expedientes[index];
                final archivos = archivosPorExpediente[expediente.id] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    leading: Icon(Icons.folder, color: greenColor),
                    title: Text(
                      expediente.nombreExpediente,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${archivos.length} archivo${archivos.length != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    children: [
                      if (archivos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No hay archivos en este expediente',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: archivos.length,
                          itemBuilder: (context, archivoIndex) {
                            final archivo = archivos[archivoIndex];
                            return ListTile(
                              leading: Icon(
                                archivo.formatoActual.toLowerCase() == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                color: greenColor,
                              ),
                              title: Text(archivo.nombreArchivo),
                              subtitle: Text(
                                'Formato: ${archivo.formatoActual}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => _verArchivo(archivo),
                                tooltip: 'Ver archivo',
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
