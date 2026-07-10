import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';

class FaceDetectionPage extends StatefulWidget {
  final List<Rect> rect;
  final ui.Image? imageFile;

  const FaceDetectionPage({
    super.key,
    required this.rect,
    required this.imageFile,
  });

  @override
  State<FaceDetectionPage> createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool isUploading = false;

  Future<void> uploadImage() async {
    setState(() {
      isUploading = true;
    });

    try {
      final ui.Image customImage =
          await convertCustomPaintToImage(_repaintBoundaryKey);

      final filename = DateTime.now().millisecondsSinceEpoch.toString();
      final byteData =
          await customImage.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final compressedBytes = await FlutterImageCompress.compressWithList(
        buffer,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
        format: CompressFormat.png,
      );

      final tempDir = Directory.systemTemp.path;
      final file =
          await File("$tempDir/$filename").writeAsBytes(compressedBytes);

      final path = "uploads/$filename";
      await Supabase.instance.client.storage.from('images').upload(path, file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Image uploaded successfully"),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to upload image"),
        duration: Duration(seconds: 2),
      ));
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<ui.Image> convertCustomPaintToImage(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("RepaintBoundary not found!");
      }
      return await boundary.toImage(pixelRatio: 3.0);
    } catch (e) {
      print("Error converting CustomPaint to Image: $e");
      rethrow;
    }
  }

  Future<void> shareFile(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final compressedBytes = await FlutterImageCompress.compressWithList(
        buffer,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
        format: CompressFormat.png,
      );

      final tempDir = Directory.systemTemp.path;
      final file =
          await File('$tempDir/temp_image.png').writeAsBytes(compressedBytes);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Check out this face-detected image!');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to share the file"),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.purple[900],
        title: const Text(
          "Result",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: widget.imageFile != null
            ? FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: widget.imageFile!.width.toDouble(),
                  height: widget.imageFile!.height.toDouble(),
                  child: RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: CustomPaint(
                      painter: FacePainter(
                          rect: widget.rect, imageFile: widget.imageFile!),
                    ),
                  ),
                ),
              )
            : const Center(child: Text("No image loaded")),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "upload",
            backgroundColor: Colors.purple[900],
            onPressed: uploadImage,
            child: isUploading
                ? const SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  )
                : const Icon(Icons.save_alt, color: Colors.white),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "share",
            backgroundColor: Colors.purple[900],
            onPressed: () async {
              if (widget.imageFile != null) {
                final image =
                    await convertCustomPaintToImage(_repaintBoundaryKey);
                shareFile(image);
              }
            },
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Rect> rect;
  final ui.Image imageFile;

  FacePainter({required this.rect, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(imageFile, Offset.zero, Paint());

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;

    for (final r in rect) {
      canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
