import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:aif_masraf_ocr/loginpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(), // MainPage, ana sayfanızın sınıfı olmalıdır.
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
      ),
      initialRoute: '/', // Başlangıç rotası
      routes: {
        '/': (context) => const Loginpage(), // Giriş sayfası
        '/home': (context) => const MyHomePage(), // Ana sayfa
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _buttonEnabled = false;
  List<String> _selectedFiles = [];
  String _ocrResult = '';

  void _toggleButton() {
    setState(() {
      _buttonEnabled = !_buttonEnabled;
    });
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Fotoğraf Arşivi'),
                onTap: () async {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Fotoğraf Çek'),
                onTap: () async {
                  Navigator.pop(context);
                  await _requestCameraPermission();
                  _takeMultiplePhotos();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Dosyaları Seçin'),
                onTap: () async {
                  Navigator.pop(context);
                  _pickFiles();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni verilmedi.')),
        );
      }
    }
  }

  void _pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        _selectedFiles = result.files.map((file) => file.path!).toList();
        _buttonEnabled = true;
      });
    }
  }

  void _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _selectedFiles = pickedFiles.map((file) => file.path).toList();
        _buttonEnabled = true;
      });
    }
  }

  void _takeMultiplePhotos() async {
    final ImagePicker picker = ImagePicker();
    List<XFile> photos = [];

    // Kullanıcıdan fotoğraf çekmesi istenir
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      photos.add(photo);
      setState(() {
        _selectedFiles.add(photo.path);
        _buttonEnabled = true;
      });
    }
  }

  Future<void> _performOCR() async {
    if (_selectedFiles.isEmpty) return;

    String apiKey = 'YOUR_API_KEY';
    String url =
        'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s';

    List<Map<String, dynamic>> requests = _selectedFiles.map((file) {
      String base64Image = base64Encode(File(file).readAsBytesSync());
      return {
        "image": {
          "content": base64Image,
        },
        "features": [
          {
            "type": "TEXT_DETECTION",
            "maxResults": 1,
          }
        ],
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"requests": requests}),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final textAnnotations = jsonResponse['responses']
            .map((res) => res['textAnnotations'] != null &&
                    res['textAnnotations'].isNotEmpty
                ? res['textAnnotations'][0]['description']
                : 'No text detected')
            .join('\n\n');

        setState(() {
          _ocrResult = textAnnotations;
        });
      } else {
        setState(() {
          _ocrResult = 'OCR başarısız oldu. Durum Kodu: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _ocrResult = 'OCR işlemi sırasında bir hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Image.asset('images/logo.png'),
        ),
        title: const Text(
          'AIF MASRAF OCR',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: const Color(0xFF162dd4),
        toolbarHeight: 80.0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF162dd4),
            padding: const EdgeInsets.all(16.0),
            child: const Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoşgeldin, Murat Yenişen',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Let\'s Have Fun with AIF MASRAF!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Masraf fişlerinizi sisteme yükleyiniz!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.0),
                  topRight: Radius.circular(18.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4FFEE),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AIF GPT OCR MODEL V1',
                          style: TextStyle(
                            fontSize: 24,
                            height: 30 / 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Yeni AIF GPT modeli ile tanışın.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _showPickerOptions,
                          child: Container(
                            height: 60.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFFD6),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.upload_file),
                                const SizedBox(width: 8),
                                const Text(
                                  'Dosya Seçin',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF007C11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  GestureDetector(
                    onTap: _buttonEnabled ? _performOCR : null,
                    child: Container(
                      height: 60.0,
                      decoration: BoxDecoration(
                        color: _buttonEnabled
                            ? const Color(0xFF162dd4)
                            : Colors.grey,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10.0),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_upload, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Yükle ve Analiz Et',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          _ocrResult,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
