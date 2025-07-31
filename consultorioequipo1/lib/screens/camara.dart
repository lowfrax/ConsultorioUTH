import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:consultorioequipo1/screens/dashboard_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initCamera;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initCamera = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    await _initCamera;
    final image = await _controller.takePicture();

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(image.path).copy(filePath);

    if (mounted) Navigator.pop(context, savedImage.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Escanear Documentos'),
        centerTitle: true,
        backgroundColor: Colors.green[800],
      ),
      body: FutureBuilder<void>(
        future: _initCamera,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          backgroundColor: Colors.green[800],
                          child: const Icon(Icons.camera_alt),
                          onPressed: _captureImage,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Presiona para escanear',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        ),
        tooltip: 'Volver al Dashboard',
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.home, color: Colors.white),
      ),
    );
  }
}
