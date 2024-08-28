import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaturaDetayPage extends StatefulWidget {
  final String ocrResult;
  final String imagePath;

  FaturaDetayPage({required this.ocrResult, required this.imagePath});

  @override
  _FaturaDetayPageState createState() => _FaturaDetayPageState();
}

class _FaturaDetayPageState extends State<FaturaDetayPage> {
  Map<String, String> extractedData = {
    'Şirket Adı': '',
    'Adres': '',
    'Vergi Dairesi': '',
    'Vergi Numarası': '',
    'Fiş Tarihi': '',
    'Saat': '',
    'Fiş No': '',
    'KDV Oranı': '',
    'KDV Tutarı': '',
    'Toplam Tutar': '',
    'Ödeme Yöntemi': '',
    'Satın Alınan Ürünler': '',
  };

  String firstLine = '';

  @override
  void initState() {
    super.initState();
    _processOcrResult();
  }

  Future<void> _processOcrResult() async {
    final apiKey =
        'sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A'; // Update with your API key
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content': '''
            Bu bir OCR sonuçlarıdır:
            ${widget.ocrResult}
            
            Lütfen aşağıdaki bilgileri tablonun içine yerleştirin:
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
            '''
          }
        ],
        'max_tokens': 1000, // Specify max tokens as in the JavaScript example
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final textResponse = jsonResponse['choices']?[0]['message']['content'];
      _parseResponse(textResponse);
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to get GPT result.');
    }
  }

  void _parseResponse(String? response) {
    if (response != null) {
      final lines = response.split('\n');
      if (lines.isNotEmpty) {
        setState(() {
          firstLine = lines[0];
        });
      }

      final newExtractedData = <String, String>{};
      for (var line in lines) {
        final parts = line.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          if (extractedData.containsKey(key)) {
            newExtractedData[key] = value;
          }
        }
      }

      setState(() {
        extractedData = newExtractedData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura Detay'),
        backgroundColor: Color(0xFF162dd4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imagePath.isNotEmpty)
              FutureBuilder<bool>(
                future: _checkFileExists(widget.imagePath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.data == true) {
                    return Image.file(
                      File(widget.imagePath),
                      height: 200,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Text('File not found');
                  }
                },
              ),
            SizedBox(height: 16),
            Text("Başlık: $firstLine",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: extractedData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle button press if needed
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(entry.value),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        backgroundColor: Colors.white,
                        elevation: 4,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkFileExists(String path) async {
    final file = File(path);
    return await file.exists();
  }
}
