import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class Pdfviewer extends StatefulWidget {
  Pdfviewer({super.key});

  @override
  State<Pdfviewer> createState() => _PdfPreviewerScreenState();
}

class _PdfPreviewerScreenState extends State<Pdfviewer> {
  List<FileSystemEntity> pdfFiles = [];

  Future<void> _loadPDFFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().where((f) => f.path.endsWith('.pdf')).toList();
    setState(() {
      pdfFiles = files.reversed.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPDFFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Archivos PDF Generados")),
      body: pdfFiles.isEmpty
          ? Center(child: Text("No hay PDFs generados aún"))
          : ListView.builder(
              itemCount: pdfFiles.length,
              itemBuilder: (context, index) {
                final file = pdfFiles[index];
                return ListTile(
                  title: Text(file.path.split('/').last),
                  trailing: const Icon(Icons.picture_as_pdf),
                  onTap: () => OpenFile.open(file.path),
                );
              },
            ),
    );
  }
}
