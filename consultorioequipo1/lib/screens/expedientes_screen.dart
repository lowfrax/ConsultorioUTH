import 'package:flutter/material.dart';
import 'dart:io';
import '../data/recursos/caso_service.dart';
import '../data/modelos/expediente.dart';
import '../data/modelos/archivoexpediente.dart';
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
      print('📁 Cargando expedientes...');
      final expedientesData = await CasoService.obtenerExpedientes();
      print('✅ Expedientes cargados: ${expedientesData.length}');

      // Cargar archivos para cada expediente
      final archivosMap = <String, List<ArchivoExpediente>>{};
      for (int i = 0; i < expedientesData.length; i++) {
        final expediente = expedientesData[i];
        print(
          '📂 Cargando archivos para expediente ${i + 1}/${expedientesData.length}: ${expediente.nombreExpediente} (ID: ${expediente.id})',
        );

        final archivos = await CasoService.obtenerArchivosExpediente(
          expediente.id!,
        );
        print(
          '📄 Archivos encontrados para ${expediente.nombreExpediente}: ${archivos.length}',
        );

        archivosMap[expediente.id!] = archivos;
      }

      setState(() {
        expedientes = expedientesData;
        archivosPorExpediente = archivosMap;
        isLoading = false;
      });

      print('🎯 Total de expedientes cargados: ${expedientesData.length}');
      print('📊 Total de expedientes con archivos: ${archivosMap.length}');
    } catch (e) {
      print('❌ Error al cargar expedientes: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _verArchivo(ArchivoExpediente archivo) async {
    try {
      if (archivo.rutaLocal != null) {
        // Verificar si el archivo local existe
        final localFile = File(archivo.rutaLocal!);
        if (await localFile.exists()) {
          print('📁 Abriendo archivo local: ${archivo.rutaLocal}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PdfViewerScreen(pdfPathToOpen: archivo.rutaLocal!),
            ),
          );
        } else {
          print('❌ Archivo local no existe: ${archivo.rutaLocal}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo local no existe')),
          );
        }
      } else if (archivo.urlArchivo != null) {
        // Abrir archivo desde Firebase Storage
        print('🌐 Abriendo archivo desde Firebase: ${archivo.urlArchivo}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PdfViewerScreen(pdfPathToOpen: archivo.urlArchivo!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay archivo disponible')),
        );
      }
    } catch (e) {
      print('❌ Error al abrir archivo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir archivo: $e')));
    }
  }

  Future<void> _subirArchivoAFirebase(ArchivoExpediente archivo) async {
    try {
      print('📤 Subiendo archivo a Firebase: ${archivo.nombreArchivo}');

      final url = await CasoService.subirArchivoLocalAFirebase(archivo.id!);

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo subido a Firebase exitosamente'),
          ),
        );
        // Recargar expedientes para mostrar la URL actualizada
        _cargarExpedientes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir archivo a Firebase')),
        );
      }
    } catch (e) {
      print('❌ Error al subir archivo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
                    children: archivos.isEmpty
                        ? [
                            const ListTile(
                              leading: Icon(Icons.info_outline),
                              title: Text('No hay archivos'),
                              subtitle: Text(
                                'Este expediente no tiene archivos adjuntos',
                              ),
                            ),
                          ]
                        : archivos.map<Widget>((archivo) {
                            final tieneUrlFirebase = archivo.urlArchivo != null;
                            final tieneRutaLocal = archivo.rutaLocal != null;

                            return ListTile(
                              leading: Icon(
                                Icons.insert_drive_file,
                                color: tieneUrlFirebase
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text(archivo.nombreArchivo),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Formato: ${archivo.formatoActual}'),
                                  if (tieneUrlFirebase)
                                    const Text(
                                      '✅ Subido a Firebase',
                                      style: TextStyle(color: Colors.green),
                                    )
                                  else if (tieneRutaLocal)
                                    const Text(
                                      '💾 Guardado localmente',
                                      style: TextStyle(color: Colors.orange),
                                    )
                                  else
                                    const Text(
                                      '❌ No disponible',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _verArchivo(archivo),
                                    tooltip: 'Ver archivo',
                                  ),
                                  if (tieneRutaLocal && !tieneUrlFirebase)
                                    IconButton(
                                      icon: const Icon(Icons.cloud_upload),
                                      onPressed: () =>
                                          _subirArchivoAFirebase(archivo),
                                      tooltip: 'Subir a Firebase',
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
