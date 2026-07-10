import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutterer_app/pages/face_detection_page.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'dart:io';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String selectedTool = "";
  String resultText = "";

  late File pickedImage;
  var imageFile;
  bool isImageLoaded = false;

  List<Rect> rect = List<Rect>.empty(growable: true);

  Future getImageFromGallery() async {
    var tempStore = await ImagePicker().pickImage(source: ImageSource.gallery);

    // User cancelled the picker — nothing to load.
    if (tempStore == null) return;

    imageFile = await tempStore.readAsBytes();
    imageFile = await decodeImageFromList(imageFile);

    setState(() {
      pickedImage = File(tempStore.path);
      resultText = "";
      isImageLoaded = true;
    });
  }

  Future readTextFromImage() async {
    resultText = "";

    final inputImage = InputImage.fromFile(pickedImage);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final recognisedText = await textDetector.processImage(inputImage);

    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          setState(() {
            resultText += '${element.text} ';
          });
        }
      }
    }
  }

  Future decodeBarCode() async {
    resultText = "";

    final inputImage = InputImage.fromFile(pickedImage);
    final barcodeScanner = GoogleMlKit.vision.barcodeScanner();
    final barcodes = await barcodeScanner.processImage(inputImage);

    for (Barcode barcode in barcodes) {
      final type = barcode.type;
      final displayValue = barcode.displayValue;

      setState(() {
        resultText += '$type : $displayValue\n';
      });
    }
  }

  Future labelsReader() async {
    resultText = "";

    final inputImage = InputImage.fromFile(pickedImage);
    final imageLabeler = GoogleMlKit.vision.imageLabeler();
    final labels = await imageLabeler.processImage(inputImage);

    for (ImageLabel label in labels) {
      final text = label.label;
      final confidence = label.confidence;

      setState(() {
        resultText += '$text : ${confidence.toStringAsFixed(2)}\n';
      });
    }
  }

  Future detectFaces() async {
    final inputImage = InputImage.fromFile(pickedImage);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final faces = await faceDetector.processImage(inputImage);

    if (rect.isNotEmpty) {
      rect.clear();
    }

    for (Face face in faces) {
      rect.add(face.boundingBox);
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceDetectionPage(
          imageFile: imageFile,
          rect: rect,
        ),
      ),
    );
  }

  List<String> _pictures = [];

  Future<void> scanDocument() async {
    List<String> pictures;
    try {
      pictures = await CunningDocumentScanner.getPictures() ?? [];
      if (!mounted) return;
      setState(() {
        _pictures = pictures;
        pickedImage = File(_pictures.last);
        isImageLoaded = true;
      });
      imageFile = await File(pictures.last).readAsBytes();
      imageFile = await decodeImageFromList(imageFile);
    } catch (e) {
      print(e);
    }
  }

  void detectMLModel() {
    if (!isImageLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select an image first."),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    if (selectedTool == "Text Scanner") {
      readTextFromImage();
    } else if (selectedTool == "Barcode Scanner") {
      decodeBarCode();
    } else if (selectedTool == "Label Scanner") {
      labelsReader();
    } else if (selectedTool == "Face Detection") {
      detectFaces();
    }
  }

  @override
  Widget build(BuildContext context) {
    selectedTool = ModalRoute.of(context)?.settings.arguments?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.purple[900],
        title: Text(
          selectedTool,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                items: [
                  const PopupMenuItem<String>(
                    value: 'Use Camera',
                    child: Text('Use Camera'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Get from Gallery',
                    child: Text('Get from Gallery'),
                  ),
                ],
              ).then((value) {
                if (value == 'Use Camera') {
                  scanDocument();
                } else if (value == 'Get from Gallery') {
                  getImageFromGallery();
                }
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          isImageLoaded
              ? Center(
                  child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(pickedImage),
                          fit: BoxFit.contain,
                        ),
                      )),
                )
              : Container(),
          Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(resultText, style: const TextStyle(fontSize: 20)))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple[900],
        onPressed: detectMLModel,
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
