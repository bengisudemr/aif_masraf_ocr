import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaturaDetayPage extends StatefulWidget {
  final String analysisResult;
  final String imagePath;
  final Map<String, dynamic> invoiceData;

  FaturaDetayPage({
    required this.analysisResult,
    required this.imagePath,
    required this.invoiceData,
  });

  @override
  _FaturaDetayPageState createState() => _FaturaDetayPageState();
}

class _FaturaDetayPageState extends State<FaturaDetayPage> {
  String formattedResult = 'Yükleniyor...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _formatOcrResult(widget.analysisResult);
  }

  Future<void> _formatOcrResult(String ocrResult) async {
    final apiKey =
        'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A'; // Replace with your OpenAI API key
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A', // Ensure this is correct
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo', // Use the appropriate model
          'messages': [
            {
              'role': 'user',
              'content':
                  'Aşağıdaki metinden fiş bilgilerini analiz et ve tablo olarak ver:\n\n$ocrResult'
            },
          ],
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          formattedResult = data['choices'][0]['message']['content'].trim();
          isLoading = false;
        });
      } else {
        setState(() {
          formattedResult =
              'Hata: ${response.statusCode} ${response.reasonPhrase}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        formattedResult = 'Bir hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura Detayı'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the uploaded image with error handling
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
            // Display the formatted OCR result or loading indicator
            Text(
              'Düzenlenmiş OCR Çıktısı:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Text(
                      formattedResult,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: null, // Allow multiline text
                      overflow: TextOverflow.visible, // Show all text
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
