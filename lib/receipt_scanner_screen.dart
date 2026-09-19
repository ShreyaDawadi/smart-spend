import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'main.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  File? _image;
  bool _processing = false;
  String? _error;

  Map<String, dynamic>? _parsedResult;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _processing = true;
      _parsedResult = null;
      _error = null;
    });

    await _runOCRAndParse(_image!);
  }

  Future<void> _runOCRAndParse(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      if (rawText.trim().isEmpty) {
        setState(() {
          _error = 'No text found in image. Try a clearer photo.';
          _processing = false;
        });
        return;
      }

      await _sendToBackend(rawText);
    } catch (e) {
      setState(() {
        _error = 'Failed to read text: $e';
        _processing = false;
      });
    } finally {
      textRecognizer.close();
    }
  }

  Future<void> _sendToBackend(String rawText) async {
    const backendUrl = 'https://smartspend-backend-2c6i.onrender.com/api/parse-receipt';

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rawText': rawText}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _parsedResult = jsonDecode(response.body);
          _processing = false;
        });
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _processing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not reach backend: $e';
        _processing = false;
      });
    }
  }

  void _confirmTransaction() {
    if (_parsedResult == null) return;

    final merchant = _parsedResult!['merchant'] ?? 'Unknown';
    final amount = (_parsedResult!['amount'] ?? 0).toDouble();
    final category = _parsedResult!['category'] ?? 'Other';

    final transaction = Transaction(
      title: merchant,
      category: category,
      amount: -amount,
      date: DateTime.now(),
    );

    Navigator.pop(context, transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: const Color(0xFFF7F7FB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 220, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            if (_processing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Reading receipt and asking AI to organize it...'),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            if (_parsedResult != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI found this:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    Text(
                      _parsedResult!['merchant'] ?? 'Unknown merchant',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${_parsedResult!['amount'] ?? '?'}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7)),
                    ),
                    const SizedBox(height: 4),
                    Text('Category: ${_parsedResult!['category'] ?? 'Other'}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: _confirmTransaction,
                child: const Text('Confirm & Save Transaction'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}