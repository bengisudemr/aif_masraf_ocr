import 'package:flutter/material.dart';

class FaturaDetayPage extends StatelessWidget {
  final String? ocrResult; // Nullable string

  FaturaDetayPage({this.ocrResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura Detayları'),
        backgroundColor: Color(0xFF162dd4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OCR Sonuçları:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildOcrContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOcrContent() {
    return Text(
      ocrResult ?? 'OCR sonucu bulunamadı.', // Null kontrolü
      style: TextStyle(fontSize: 16),
    );
  }
}
