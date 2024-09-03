import 'dart:convert'; // JSON dönüşümü için
import 'dart:io';
import 'package:aif_masraf_ocr/manuelmasrafdetaypage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // HTTP istekleri için

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> invoices = [];
  List<String> titles = []; // OCR sonuçlarından başlıkları depolamak için liste

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
    const apiKey = 'YOUR_GOOGLE_VISION_API_KEY';
    const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

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

    await _analyzeWithGPTAndNavigate(filePath, jsonPart1, jsonPart2);
  }

  Future<void> _analyzeWithGPTAndNavigate(
      String filePath, String jsonPart1, String jsonPart2) async {
    try {
      final analysisResultPart1 = await fetchGPTAnalysisPart1(jsonPart1);
      final analysisResultPart2 = await fetchGPTAnalysisPart2(jsonPart2);

      final combinedResult = '$analysisResultPart1\n\n$analysisResultPart2';

      // Sayfaya yönlendirme
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaturaDetayPage(
            imagePath: filePath,
            analysisResult: combinedResult,
            invoiceData: _extractInvoiceData(combinedResult),
          ),
        ),
      );
    } catch (e) {
      print('Error analyzing with GPT: $e');
    }
  }

  Future<String> fetchGPTAnalysisPart1(String jsonPart1) async {
    const apiKey = 'YOUR_OPENAI_API_KEY';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
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
            Aşağıdaki fiş bilgilerini analiz et ve tablo olarak ver:
            $jsonPart1
            
            ŞİRKET ADI:
            ADRES:
            VERGİ DAİRESİ:
            VERGİ NUMARASI:
            FİŞ TARİHİ:
            SAAT:
            FİŞ NO:
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
    const apiKey = 'YOUR_OPENAI_API_KEY';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
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
            Aşağıdaki fiş bilgilerini analiz et ve tablo olarak ver:
            $jsonPart2
            
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
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Failed to fetch data from GPT');
    }
  }

  Map<String, dynamic> _extractInvoiceData(String combinedResult) {
    final lines = combinedResult.split('\n');
    final Map<String, dynamic> invoiceData = {};

    for (final line in lines) {
      if (line.contains('ŞİRKET ADI:')) {
        invoiceData['sirketAdi'] = line.split(':')[1].trim();
      } else if (line.contains('ADRES:')) {
        invoiceData['adres'] = line.split(':')[1].trim();
      } else if (line.contains('VERGİ DAİRESİ:')) {
        invoiceData['vergiDairesi'] = line.split(':')[1].trim();
      } else if (line.contains('VERGİ NUMARASI:')) {
        invoiceData['vergiNumarasi'] = line.split(':')[1].trim();
      } else if (line.contains('FİŞ TARİHİ:')) {
        invoiceData['fisTarihi'] = line.split(':')[1].trim();
      } else if (line.contains('FİŞ NO:')) {
        invoiceData['fisNo'] = line.split(':')[1].trim();
      } else if (line.contains('KDV ORANI:')) {
        invoiceData['kdvOrani'] = line.split(':')[1].trim();
      } else if (line.contains('KDV TUTARI:')) {
        invoiceData['kdvTutari'] = line.split(':')[1].trim();
      } else if (line.contains('TOPLAM TUTAR:')) {
        invoiceData['toplamTutar'] = line.split(':')[1].trim();
      } else if (line.contains('ÖDEME YÖNTEMİ:')) {
        invoiceData['odemeYontemi'] = line.split(':')[1].trim();
      }
    }

    return invoiceData;
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
      body: Column(
        children: [
          const SizedBox(height: 8),
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
                              style: const TextStyle(
                                  color: Color(0xFF162dd4),
                                  fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FaturaDetayPage(
                                    imagePath: '',
                                    analysisResult: '',
                                    invoiceData: {},
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
}

class FaturaDetayPage extends StatefulWidget {
  final String imagePath;
  final String analysisResult;
  final Map<String, dynamic> invoiceData;

  FaturaDetayPage({
    required this.imagePath,
    required this.analysisResult,
    required this.invoiceData,
  });

  @override
  _FaturaDetayPageState createState() => _FaturaDetayPageState();
}

class _FaturaDetayPageState extends State<FaturaDetayPage> {
  late Map<String, String> invoiceDetails;
  late List<Map<String, String>> productDetails;

  @override
  void initState() {
    super.initState();
    invoiceDetails = _extractInvoiceDetails(widget.invoiceData);
    productDetails = _extractProductDetails(widget.analysisResult);
  }

  Map<String, String> _extractInvoiceDetails(Map<String, dynamic> invoiceData) {
    return {
      "Şirket Adı": invoiceData["sirketAdi"] ?? "-",
      "Adres": invoiceData["adres"] ?? "-",
      "Vergi Dairesi": invoiceData["vergiDairesi"] ?? "-",
      "Vergi Numarası": invoiceData["vergiNumarasi"] ?? "-",
      "Fiş Tarihi": invoiceData["fisTarihi"] ?? "-",
      "Saat": invoiceData["saat"] ?? "-",
      "Fiş No": invoiceData["fisNo"] ?? "-",
      "KDV Oranı": invoiceData["kdvOrani"] ?? "-",
      "KDV Tutarı": invoiceData["kdvTutari"] ?? "-",
      "Toplam Tutar": invoiceData["toplamTutar"] ?? "-",
      "Ödeme Yöntemi": invoiceData["odemeYontemi"] ?? "-",
    };
  }

  List<Map<String, String>> _extractProductDetails(String analysisResult) {
    final lines = analysisResult.split('\n');
    final List<Map<String, String>> products = [];
    bool foundProducts = false;

    for (var line in lines) {
      if (foundProducts) {
        final parts = line.split('|');
        if (parts.length >= 3) {
          products.add({
            'urunAdi': parts[0].trim(),
            'kdvOrani': parts[1].trim(),
            'tutar': parts[2].trim(),
          });
        }
      } else if (line.contains('SATIN ALINAN ÜRÜNLER')) {
        foundProducts = true;
      }
    }

    return products;
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
            if (widget.imagePath.isNotEmpty)
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
            _buildInvoiceInfoTable(),
            SizedBox(height: 20),
            Text(
              'Satın Alınan Ürünler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            _buildProductsTable(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Kaydetme işlemi
              },
              child: Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceInfoTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(6),
      },
      children: invoiceDetails.entries.map((entry) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.key,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(entry.value),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProductsTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(7),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[300]),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ürün Adı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'KDV Oranı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Tutar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ...productDetails.map((product) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(product['urunAdi'] ?? '-'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(product['kdvOrani'] ?? '-'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(product['tutar'] ?? '-'),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
