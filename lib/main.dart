import 'package:aif_masraf_ocr/faturadetay.dart';
import 'package:aif_masraf_ocr/loginpage.dart';
import 'package:aif_masraf_ocr/manuelmasrafdetaypage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF162dd4),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF162dd4)),
          bodyMedium: TextStyle(color: Color(0xFF162dd4)),
          displayLarge:
              TextStyle(color: Color(0xFF162dd4), fontWeight: FontWeight.bold),
          displayMedium:
              TextStyle(color: Color(0xFF162dd4), fontWeight: FontWeight.bold),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF162dd4),
          textTheme: ButtonTextTheme.primary,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF162dd4).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: const Color(0xFF162dd4),
        )
            .copyWith(secondary: const Color(0xFF162dd4))
            .copyWith(surface: Colors.grey[100]),
      ),
      home: const Loginpage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> invoices = []; // List to store invoice data
  bool _isLoading = false; // Yükleme durumunu tutacak değişken

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
    });

    const apiUrl = 'https://masrafapi.aifdigital.com.tr/api/Masraf/getAll';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      // Yanıtı kontrol etmek için doğrudan yazdırıyoruz
      print("API raw response: ${response.body}");

      if (response.statusCode == 200) {
        // jsonDecode işlemi öncesinde yanıtın tipini kontrol ediyoruz
        final decodedResponse = jsonDecode(response.body);
        print("Decoded response: $decodedResponse");

        // Yanıtın içinde '$values' var mı ve '$values' bir liste mi?
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey('\$values') &&
            decodedResponse['\$values'] is List) {
          final List<dynamic> invoiceList = decodedResponse['\$values'];

          setState(() {
            invoices = invoiceList
                .map((invoice) {
                  final String sirketAdi =
                      invoice['sirketAdi'] ?? 'Şirket Adı Yok';
                  final String faturaDurumu = invoice['faturaDurumu'] == 0
                      ? 'Onay Bekliyor'
                      : 'Onaylandı';

                  return "$sirketAdi - Durum: $faturaDurumu";
                })
                .cast<Map<String, dynamic>>()
                .toList();
          });
        } else {
          print('Fatura listesi beklenen formatta değil');
        }
      } else {
        print('API isteği başarısız oldu: ${response.statusCode}');
      }
    } catch (e) {
      print('Fatura çekerken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final filePath = pickedFile.path;
      final ocrResult = await _sendToGoogleVisionApi(filePath);
      await _splitJsonAndAnalyze(ocrResult, filePath);
    } else {
      print('No image selected.');
    }
  }

  void _showFloatingMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title:
                    const Text('Galeri', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _selectFromGallery(context);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload, color: Colors.white),
                title: const Text('Dosya yükle',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  _uploadFile(context);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.format_align_center, color: Colors.white),
                title:
                    const Text('Manuel', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManuelMasrafFormPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera, color: Colors.white),
                title:
                    const Text('Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _pickImageFromCamera();
                  Navigator.pop(context);
                },
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFromGallery(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final filePath = file.path;
      if (filePath != null) {
        final ocrResult = await _sendToGoogleVisionApi(filePath);
        await _splitJsonAndAnalyze(ocrResult, filePath);
      } else {
        print('File path is null.');
      }
    } else {
      print('No image selected.');
    }
  }

  Future<void> _uploadFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.path != null) {
        final ocrResult = await _sendToGoogleVisionApi(file.path!);
        await _splitJsonAndAnalyze(ocrResult, file.path!);
      } else {
        print('File path is null.');
      }
    } else {
      print('No file selected.');
    }
  }

  Future<String> _convertImageToBase64(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> _sendToGoogleVisionApi(String filePath) async {
    const apiKey =
        'AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s'; // Replace with your Google Vision API key
    const url =
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
      print('Error in _sendToGoogleVisionApi: $e');
      return 'Error occurred during API call';
    }
  }

  Future<void> _splitJsonAndAnalyze(String ocrResult, String filePath) async {
    int middleIndex = ocrResult.length ~/ 2;
    String jsonPart1 = ocrResult.substring(0, middleIndex);
    String jsonPart2 = ocrResult.substring(middleIndex);

    setState(() {
      _isLoading = true; // Yükleme göstergesini aç
    });

    await _analyzeWithGPTAndNavigate(filePath, jsonPart1, jsonPart2);

    setState(() {
      _isLoading = false; // Yükleme göstergesini kapat
    });
  }

  String _cleanAndMergeJsonResponse(String response) {
    response = response.replaceAll("\n", "").replaceAll("\t", "").trim();

    if (response.contains("}{")) {
      response = response.split("}{")[0] + "}";
    }

    return response;
  }

  Future<void> _analyzeWithGPTAndNavigate(
      String filePath, String jsonPart1, String jsonPart2) async {
    try {
      final analysisResultPart1 = await fetchGPTAnalysisPart1(jsonPart1);
      final analysisResultPart2 = await fetchGPTAnalysisPart2(jsonPart2);

      final combinedResult = '$analysisResultPart1\n\n$analysisResultPart2';

      final cleanedJson = _cleanAndMergeJsonResponse(combinedResult);

      final decodedData = jsonDecode(cleanedJson);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaturaDetayPage(
            imagePath: filePath,
            invoiceData: decodedData,
            analysisResult: '',
          ),
        ),
      );
    } catch (e) {
      print('Error analyzing with GPT: $e');
    }
  }

  Future<String> fetchGPTAnalysisPart1(String jsonPart1) async {
    const apiKey =
        'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A'; // Replace with your OpenAI API key

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
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
            'content': '''
          OCR çıktısını analiz et ve aşağıdaki JSON formatında döndür:
          {
            "sirketAdi": "Şirket Adı",
            "adres": "Adres",
            "vergiDairesi": "Vergi Dairesi",
            "vergiNumarasi": "Vergi Numarası",
            "fisNo": "Fiş Numarası",
            "kdvTutari": "KDV Tutarı",
            "toplamTutar": "Toplam Tutar",
            "urunler": [
                {
                    "urunAdi": "Ürün Adı",
                    "kdvOrani": "KDV Oranı",
                    "tutar": "Tutar"
                },
                ...
            ]
          }
          OCR Çıktısı:
          $jsonPart1
        '''
          }
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Failed to fetch data from GPT');
    }
  }

  Future<String> fetchGPTAnalysisPart2(String jsonPart2) async {
    const apiKey =
        'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A'; // Replace with your OpenAI API key

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
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
            'content': '''
         OCR çıktısını analiz et ve aşağıdaki JSON formatında döndür:
          {
            "sirketAdi": "Şirket Adı",
            "adres": "Adres",
            "vergiDairesi": "Vergi Dairesi",
            "vergiNumarasi": "Vergi Numarası",
            "fisNo": "Fiş Numarası",
            "kdvTutari": "KDV Tutarı",
            "toplamTutar": "Toplam Tutar"
          }

          OCR Çıktısı:
          $jsonPart2
          '''
          }
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Failed to fetch data from GPT');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF162dd4),
        elevation: 0,
        toolbarHeight: 100,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF162dd4), size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Merhaba, ",
                        style: TextStyle(fontWeight: FontWeight.w300),
                      ),
                      TextSpan(
                        text: "Bilal",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Masraf girmeye hazır mısın?",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: invoices.isNotEmpty
                    ? ListView.builder(
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Card(
                              elevation: 2,
                              child: ListTile(
                                title: Text(
                                  invoice['sirketAdi'] ?? 'Şirket Adı Yok',
                                  style: const TextStyle(
                                      color: Color(0xFF162dd4),
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Durum: ${invoice['faturaDurumu'] ?? 'Bilinmiyor'}',
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FaturaDetayPage(
                                        imagePath: '',
                                        invoiceData: {},
                                        analysisResult: '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          'Henüz masraf girişi yapılmadı',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          if (_isLoading) // Yükleme durumuna göre animasyonu göster
            Container(
              color: Colors.black.withOpacity(0.5), // Arkaplanı karartma
              child: Center(
                child: Lottie.asset(
                  'assets/money.json', // JSON animasyon dosyası
                  width: 200,
                  height: 200,
                  fit: BoxFit.fill,
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFloatingMenu(context),
        backgroundColor: const Color(0xFF162dd4),
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 20,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.home, color: Color(0xFF162dd4)),
              Icon(Icons.list_alt, color: Colors.grey),
              SizedBox(width: 24), // Center icon spacing
              Icon(Icons.check_sharp, color: Colors.grey),
              Icon(Icons.settings, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
