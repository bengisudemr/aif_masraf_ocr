import 'package:aif_masraf_ocr/faturadetay.dart';
import 'package:aif_masraf_ocr/loginpage.dart';
import 'package:aif_masraf_ocr/manuelmasrafdetaypage.dart';
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
                  ();
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

  Future<String> _sendToGoogleVisionApi(String filePath) async {
    final apiKey =
        'AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s'; // Replace with your API key
    final url =
        'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s';

    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final textAnnotation =
          jsonResponse['responses']?[0]['fullTextAnnotation'];
      final ocrText = textAnnotation?['text'] ?? 'OCR result not found.';
      return ocrText;
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to get OCR result.');
    }
  }

  Future<void> _analyzeWithGPTAndNavigate(
      String ocrResult, String filePath) async {
    try {
      final analysisResult = await fetchGPTAnalysis(ocrResult);
      final formattedResult = _formatAnalysisResult(analysisResult);

      // İlk satırı başlık olarak ayırın
      final firstLine = ocrResult.split('\n').first;

      // OCR sonucunu listeye ekleyin
      setState(() {
        invoices.add(formattedResult);
        titles.add(firstLine); // Başlık için ilk satırı kullanın
      });
    } catch (e) {
      print('Error analyzing with GPT: $e');
    }
  }

  Future<Map<String, dynamic>> fetchGPTAnalysis(String ocrText) async {
    const apiKey =
        'Bearer sk-VBF6lqNYL4XFrGEd4tY6_uCe1zJzEnGHwi9SKRIEKwT3BlbkFJl2lZhAGmPo9VxnQ6cMQZEETSlWF5ufmBF95ksS9r8A'; // API anahtarınızı buraya ekleyin
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

  String _formatAnalysisResult(Map<String, dynamic> analysisResult) {
    // Extract and format the analysis result from GPT API
    return analysisResult['choices'][0]['message']['content'];
  }

  void _navigateToMasrafDetayPage(
      BuildContext context, String analysisResult, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MasrafDetayPage(
          ocrText: analysisResult,
          gptData: {},
        ),
      ),
    );
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
                                  builder: (context) => MasrafDetayPage(
                                    ocrText: invoices[index],
                                    gptData: {},
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
          child: Row(
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
