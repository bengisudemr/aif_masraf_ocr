import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaturaDetayPage extends StatefulWidget {
  final String imagePath;

  FaturaDetayPage(
      {required this.imagePath,
      required String analysisResult,
      required Map<String, dynamic> invoiceData});

  @override
  _FaturaDetayPageState createState() => _FaturaDetayPageState();
}

class _FaturaDetayPageState extends State<FaturaDetayPage> {
  String formattedResult = 'Yükleniyor...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _processImage(widget.imagePath);
  }

  Future<void> _processImage(String filePath) async {
    try {
      // Google Vision API ile OCR yap
      final ocrText = await _sendToGoogleVisionApi(filePath);

      // OCR sonucunu GPT-3.5-turbo'ya gönderip analiz et
      final analysisResult = await _analyzeWithGPT(ocrText);

      setState(() {
        formattedResult = analysisResult;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        formattedResult = 'Bir hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  Future<String> _sendToGoogleVisionApi(String filePath) async {
    const apiKey =
        'AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s'; // Google Vision API anahtarınızı buraya ekleyin
    final url =
        'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s';

    try {
      final base64Image = await _convertImageToBase64(filePath);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "TEXT_DETECTION"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final extractedText = jsonResponse['responses']?[0]
                ['fullTextAnnotation']?['text'] ??
            'No text found';
        return extractedText;
      } else {
        throw Exception(
            'Failed to get OCR result. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in _sendToGoogleVisionApi: $e');
    }
  }

  Future<String> _analyzeWithGPT(String ocrResult) async {
    const apiKey =
        'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A'; // OpenAI API anahtarınızı buraya ekleyin
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content':
                  '''Aşağıdaki metinden fiş bilgilerini analiz et ve tablo olarak ver:
                
                ŞİRKET ADI:
                ADRES:
                VERGİ DAİRESİ:
                VERGİ NUMARASI:
                FİŞ TARİHİ:
                SAAT:
                FİŞ NO:
                KDV ORANI:
                KDV TUTARI:
                TOPLAM TUTAR:
                ÖDEME YÖNTEMİ:
                SATIN ALINAN ÜRÜNLER: (Ürün Adı, KDV Oranı, Tutar)

                Lütfen sonucu flutter tablosu olarak ver ve ürünleri ayrı bir tabloda listelerken, her satırda Ürün Adı, KDV Oranı ve Tutar'ı göster:
                \n\n$ocrResult'''
            },
          ],
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        throw Exception(
            'Failed to analyze with GPT. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in _analyzeWithGPT: $e');
    }
  }

  Future<String> _convertImageToBase64(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura Detayı'),
        backgroundColor: Color(0xFF162dd4),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğrafın gösterimi
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  height: 300,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        'Görsel yüklenirken bir hata oluştu',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            // OCR ve GPT sonuçlarının gösterimi
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPT-3.5-turbo Sonucu:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        formattedResult,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
