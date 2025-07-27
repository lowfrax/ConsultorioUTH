import 'dart:io';

import 'package:consultorioequipo1/screens/pdfviewer.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:consultorioequipo1/screens/img_preview.dart';
import 'camara.dart';
import 'pdfviewer.dart';

class DashboardScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  DashboardScreen({super.key, required this.cameras});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> capturedImagePaths = [];

  Future<void> _scanImage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: widget.cameras.first),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        capturedImagePaths.add(result);
      });
    }
  }

  Future<void> _generatePDF() async {
    if (capturedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay imágenes para generar PDF')),
      );
      return;
    }

    final pdf = pw.Document();

    for (final imagePath in capturedImagePaths) {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(child: pw.Image(image)),
        ),
      );
    }

    final output = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${output.path}/scan_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF generado exitosamente')));

    await Share.shareFiles([file.path], text: 'Documento PDF generado');

    setState(() {
      capturedImagePaths.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UTH Consultorio Jurídico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Pdfviewer()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Resumen de Casos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: const [
              DashboardCard(
                count: 1,
                label: 'Casos Totales',
                color: Colors.green,
              ),
              DashboardCard(
                count: 1,
                label: 'Pendientes',
                color: Colors.orange,
              ),
              DashboardCard(count: 0, label: 'En Proceso', color: Colors.blue),
              DashboardCard(
                count: 0,
                label: 'Finalizados',
                color: Colors.green,
              ),
              DashboardCard(count: 0, label: 'Retrasados', color: Colors.red),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _scanImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Escanear Imagen (Agregar)'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _generatePDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generar PDF y Compartir'),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const DashboardCard({
    super.key,
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
