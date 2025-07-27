import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ImagePreviewScreen({super.key, required this.cameras});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  List<String> imagePaths = [];

  Future<void> _takePicture() async {
    final camera = widget.cameras.first;
    final controller = CameraController(camera, ResolutionPreset.medium);

    await controller.initialize();
    final tempDir = await getTemporaryDirectory();
    final imagePath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await controller.takePicture().then((XFile file) async {
      await file.saveTo(imagePath);
      setState(() => imagePaths.add(imagePath));
    });

    await controller.dispose();
  }

  void _deleteImage(int index) {
    setState(() {
      imagePaths.removeAt(index);
    });
  }

  Future<void> _generatePDF() async {
    if (imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay imágenes para generar PDF")),
      );
      return;
    }

    final pdf = pw.Document();
    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(child: pw.Image(image)),
        ),
      );
    }

    final output = await getApplicationDocumentsDirectory();
    final file = File(
      '${output.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("PDF generado")));
    await Share.shareFiles([file.path], text: 'Documento escaneado');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear Imágenes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      body: imagePaths.isEmpty
          ? const Center(child: Text("No hay imágenes aún"))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: imagePaths.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Image.file(
                      File(imagePaths[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteImage(index),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
