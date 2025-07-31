import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? pdfPathToOpen; // PDF específico para abrir inmediatamente

  const PdfViewerScreen({super.key, this.pdfPathToOpen});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  List<FileSystemEntity> pdfFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPDFFiles();

    // Si se proporcionó un PDF para abrir, cargarlo después de un breve delay
    if (widget.pdfPathToOpen != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _openPdf(widget.pdfPathToOpen!);
      });
    }
  }

  Future<void> _loadPDFFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    setState(() {
      pdfFiles = files.where((f) => f.path.endsWith('.pdf')).toList();
      isLoading = false;
    });
  }

  Future<void> _openPdf(String path) async {
    await OpenFile.open(path);
  }

  Future<void> _sharePdf(String path) async {
    await Share.shareFiles([path], text: 'Documento PDF generado');
  }

  Future<void> _deletePdf(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar PDF'),
        content: Text(
          '¿Estás seguro de eliminar ${pdfFiles[index].path.split('/').last}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final file = File(pdfFiles[index].path);
      await file.delete();
      await _loadPDFFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Archivos PDF Generados")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfFiles.isEmpty
          ? const Center(child: Text("No hay PDFs generados aún"))
          : ListView.builder(
              itemCount: pdfFiles.length,
              itemBuilder: (context, index) {
                final file = pdfFiles[index];
                final fileName = file.path.split('/').last;
                final fileDate = File(file.path).lastModifiedSync();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    title: Text(fileName),
                    subtitle: Text(
                      'Creado: ${fileDate.day}/${fileDate.month}/${fileDate.year} '
                      '${fileDate.hour}:${fileDate.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _sharePdf(file.path),
                          tooltip: 'Compartir',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePdf(index),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                    onTap: () => _openPdf(file.path),
                  ),
                );
              },
            ),
    );
  }
}
