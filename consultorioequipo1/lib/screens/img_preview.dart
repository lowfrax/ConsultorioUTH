import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:camera/camera.dart';
import 'camara.dart';
import 'pdfviewer.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<String> initialImages;
  final List<CameraDescription> cameras;

  const ImagePreviewScreen({
    super.key,
    required this.initialImages,
    required this.cameras,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late List<String> imagePaths;

  @override
  void initState() {
    super.initState();
    imagePaths = List.from(widget.initialImages);
    if (imagePaths.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToCamera());
    }
  }

  Future<void> _goToCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(camera: widget.cameras.first),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        imagePaths.add(result);
      });
    } else if (imagePaths.isEmpty && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _generatePDF() async {
    if (imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay imágenes para generar PDF')),
      );
      return;
    }

    final pdf = pw.Document();

    for (var path in imagePaths) {
      final imageBytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(pw.Page(build: (_) => pw.Center(child: pw.Image(image))));
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(pdfPathToOpen: filePath),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      final removedPath = imagePaths.removeAt(index);
      File(removedPath).delete();
    });
  }

  void _editImage(int index) async {
    final editedPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(camera: widget.cameras.first),
      ),
    );

    if (editedPath != null && editedPath is String) {
      setState(() {
        File(imagePaths[index]).delete();
        imagePaths[index] = editedPath;
      });
    }
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = imagePaths.removeAt(oldIndex);
      imagePaths.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsualización de Imágenes'),
        actions: [
          if (imagePaths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePDF,
              tooltip: 'Generar PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: imagePaths.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No hay imágenes capturadas'),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _goToCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Tomar Foto'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: imagePaths.length,
                    onReorder: _reorderImages,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(imagePaths[index]),
                        background: Container(color: Colors.red),
                        secondaryBackground: Container(color: Colors.red),
                        confirmDismiss: (direction) async {
                          _removeImage(index);
                          return false;
                        },
                        child: Card(
                          key: Key('$index'),
                          elevation: 2,
                          child: SizedBox(
                            height: 200, // Altura fija para cada imagen
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.file(
                                    File(imagePaths[index]),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            ),
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  left: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.black54,
                                    child: Text(
                                      'Imagen ${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _editImage(index),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (imagePaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _goToCamera,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Agregar Más'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _generatePDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generar PDF'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
