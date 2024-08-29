import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String apiUrl = 'https://api.openai.com/v1/chat/completions';
  final String apiKey =
      'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A';

  Future<String> analyzeText(String extractedText) async {
    final prompt = '''
Aşağıdaki metinden fiş bilgilerini analiz et ve tablo olarak ver:
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

Lütfen sonucu HTML tablosu olarak ver ve ürünleri ayrı bir tabloda listelerken, her satırda Ürün Adı, KDV Oranı ve Tutar'ı göster:

Metin: \n\n$extractedText
''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': apiKey,
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['choices'][0]['message']['content'];
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to analyze text.');
    }
  }
}
