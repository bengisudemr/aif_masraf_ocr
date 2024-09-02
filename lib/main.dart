import 'package:aif_masraf_ocr/faturadetay.dart';
import 'package:aif_masraf_ocr/loginpage.dart';
import 'package:aif_masraf_ocr/manuelmasrafdetaypage.dart';
import 'package:aif_masraf_ocr/services/api_Service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF162dd4),
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
          color: Color(0xFF162dd4).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Color(0xFF162dd4),
        )
            .copyWith(secondary: Color(0xFF162dd4))
            .copyWith(background: Colors.grey[100]),
      ),
      home: Loginpage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> invoices = [];
  List<String> titles = []; // List to store titles from OCR results

  Future<void> _pickImageFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final filePath = pickedFile.path;
      if (filePath != null) {
        final ocrResult = await _sendToGoogleVisionApi(filePath);
        await _analyzeWithGPTAndNavigate(ocrResult, filePath);
      } else {
        print('File path is null.');
      }
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
                leading: Icon(Icons.photo_library, color: Colors.white),
                title: Text('Galeri', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _selectFromGallery(context);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.file_upload, color: Colors.white),
                title:
                    Text('Dosya yükle', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _uploadFile(context);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.format_align_center, color: Colors.white),
                title: Text('Manuel', style: TextStyle(color: Colors.white)),
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
                leading: Icon(Icons.camera, color: Colors.white),
                title: Text('Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _pickImageFromCamera(); // Kamera ile resim çekmek için eklenen fonksiyon
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
        await _analyzeWithGPTAndNavigate(ocrResult, filePath);
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
        await _analyzeWithGPTAndNavigate(ocrResult, file.path!);
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
        'AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s'; // API anahtarınızı buraya ekleyin.
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

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

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

  /// Bu fonksiyon karakter hatalarını düzeltmek için manuel olarak müdahale eder
  String _fixMalformedCharacters(String input) {
    // Türkçe karakterleri manuel olarak düzeltiyoruz
    return input
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ã¶', 'ö')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('ÅŸ', 'ş')
        .replaceAll('Ä±', 'ı')
        .replaceAll('ÄŸ', 'ğ')
        .replaceAll('Ã‡', 'Ç')
        .replaceAll('Ã–', 'Ö')
        .replaceAll('Ãœ', 'Ü')
        .replaceAll('Åž', 'Ş')
        .replaceAll('Ä°', 'İ')
        .replaceAll('ÄŸ', 'ğ');
  }

  Future<void> _analyzeWithGPTAndNavigate(
      String ocrResult, String filePath) async {
    try {
      final analysisResult =
          await fetchGPTAnalysis(ocrResult); // GPT Analizini al

      // OpenAI'dan gelen sonucu UTF-8 olarak decode et
      final utf8Result =
          _decodeUtf8(analysisResult['choices'][0]['message']['content']);

      // Gelen yanıtı manuel olarak düzeltmek
      final fixedResult = _fixMalformedCharacters(utf8Result);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaturaDetayPage(
            analysisResult: _formatAnalysisResult(fixedResult),
            imagePath: filePath,
            invoiceData: _parseOcrResults(ocrResult),
          ),
        ),
      );
    } catch (e) {
      print('Error analyzing with GPT: $e');
    }
  }

  String _decodeUtf8(String encodedText) {
    // Metni UTF-8 olarak decode edin
    try {
      return utf8.decode(encodedText.runes.toList(), allowMalformed: true);
    } catch (e) {
      print("UTF-8 decoding error: $e");
      return encodedText; // Hata durumunda orijinal metni döndür
    }
  }

  Future<Map<String, dynamic>> fetchGPTAnalysis(String ocrText) async {
    const apiKey =
        'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A';
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': apiKey,
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content':
                '''Aşağıdaki metinden fiş bilgilerini analiz et ve tablo olarak ver:
          
          $ocrText
          
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
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to fetch data from GPT');
    }
  }

  String _formatAnalysisResult(String analysisResult) {
    // İçeriği kontrol et ve özel karakterleri doğru işlediğinden emin ol
    List<String> lines = analysisResult.split('\n');
    String formattedContent = '';
    for (String line in lines) {
      if (line.contains('|')) {
        List<String> parts = line.split('|');
        if (parts.length > 1) {
          formattedContent += '${parts[0].trim()}: ${parts[1].trim()}\n';
        }
      } else {
        formattedContent += line.trim() + '\n';
      }
    }
    return formattedContent;
  }

  Map<String, dynamic> _parseOcrResults(String ocrResult) {
    // OCR sonucunu belirli alanlara ayırma
    List<String> lines = ocrResult.split('\n');
    Map<String, dynamic> parsedData = {};

    for (String line in lines) {
      if (line.contains('Şirket Adı')) {
        parsedData['companyName'] = _extractValue(line);
      } else if (line.contains('Adres')) {
        parsedData['address'] = _extractValue(line);
      } else if (line.contains('Vergi Dairesi')) {
        parsedData['taxOffice'] = _extractValue(line);
      } else if (line.contains('Vergi Numarası')) {
        parsedData['taxNumber'] = _extractValue(line);
      } else if (line.contains('Fiş Tarihi')) {
        parsedData['receiptDate'] = _extractValue(line);
      } else if (line.contains('Saat')) {
        parsedData['receiptTime'] = _extractValue(line);
      } else if (line.contains('Fiş No')) {
        parsedData['receiptNumber'] = _extractValue(line);
      } else if (line.contains('KDV Oranı')) {
        parsedData['vatRate'] = _extractValue(line);
      } else if (line.contains('KDV Tutarı')) {
        parsedData['vatAmount'] = _extractValue(line);
      } else if (line.contains('Toplam Tutar')) {
        parsedData['totalAmount'] = _extractValue(line);
      } else if (line.contains('Ödeme Yöntemi')) {
        parsedData['paymentMethod'] = _extractValue(line);
      } else if (line.contains('Satın Alınan Ürünler')) {
        parsedData['purchasedItems'] = _parsePurchasedItems(lines);
      }
    }

    return parsedData;
  }

  String _extractValue(String line) {
    // Satırın değerini çıkarmak için yardımcı bir fonksiyon
    return line.split(':')[1].trim();
  }

  List<Map<String, dynamic>> _parsePurchasedItems(List<String> lines) {
    List<Map<String, dynamic>> items = [];
    bool isItemSection = false;

    for (String line in lines) {
      if (line.contains('Satın Alınan Ürünler')) {
        isItemSection = true;
        continue;
      }
      if (isItemSection) {
        if (line.isEmpty) {
          break; // Son itemi bulduktan sonra çık
        }
        List<String> itemDetails = line.split(',');
        if (itemDetails.length >= 3) {
          items.add({
            'itemName': itemDetails[0].trim(),
            'itemVatRate': itemDetails[1].trim(),
            'itemAmount': itemDetails[2].trim(),
          });
        }
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF162dd4),
        elevation: 0,
        toolbarHeight: 100,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF162dd4), size: 30),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
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
      body: Column(
        children: [
          SizedBox(height: 8),
          Expanded(
            child: invoices.isNotEmpty
                ? ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Card(
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              titles.isNotEmpty && index < titles.length
                                  ? titles[index]
                                  : 'Invoice ${index + 1}',
                              style: TextStyle(
                                  color: Color(0xFF162dd4),
                                  fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FaturaDetayPage(
                                    invoiceData: {},
                                    imagePath: '',
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
                : Center(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFloatingMenu(context),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF162dd4),
        elevation: 4,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 20,
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 30),
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
