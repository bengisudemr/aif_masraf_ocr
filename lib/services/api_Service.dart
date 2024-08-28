import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> analyzeOCRData(String ocrText) async {
  final apiUrl =
      'https://api.openai.com/v1/chat/completions'; // ChatGPT API URL
  final apiKey =
      'sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A'; // API Key

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization':
          'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A',
    },
    body: jsonEncode({
      'model': 'gpt-3.5-turbo', // veya kullandığınız model
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a helpful assistant that processes OCR data and formats it for a specific UI.'
        },
        {'role': 'user', 'content': 'Here is the OCR data: $ocrText'}
      ]
    }),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData; // ChatGPT'den dönen yanıt
  } else {
    throw Exception('Failed to load data');
  }
}
