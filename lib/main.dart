import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:aif_masraf_ocr/loginpage.dart';
import 'package:aif_masraf_ocr/faturadetay.dart';

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
        _addInvoice(ocrResult, filePath);
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
        _addInvoice(ocrResult, file.path!);
      } else {
        print('File path is null.');
      }
    } else {
      print('No file selected.');
    }
  }

  Future<String> _sendToGoogleVisionApi(String filePath) async {
    final apiKey =
        'YOUR_GOOGLE_CLOUD_VISION_API_KEY'; // Update your API key here
    final url =
        'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s'; // Update your API key here

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
      final ocrText = textAnnotation?['text'] ?? 'OCR sonucu bulunamadı.';
      return ocrText;
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to get OCR result.');
    }
  }

  void _addInvoice(String ocrResult, String filePath) {
    final firstLine = ocrResult.split('\n').first;
    setState(() {
      invoices.add(ocrResult);
      titles.add(firstLine);
    });
  }

  void _navigateToFaturaDetayPage(
      BuildContext context, String ocrResult, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaturaDetayPage(
          ocrResult: ocrResult,
          imagePath: imagePath,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ToggleButtons(
                  borderRadius: BorderRadius.circular(20),
                  selectedBorderColor: Color(0xFF162dd4),
                  fillColor: Color(0xFF162dd4).withOpacity(0.2),
                  selectedColor: Color(0xFF162dd4),
                  color: Colors.grey,
                  constraints: BoxConstraints(minWidth: 100, minHeight: 36),
                  children: [
                    Text("Açık"),
                    Text("Tamamlandı"),
                  ],
                  isSelected: [true, false],
                  onPressed: (index) {},
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: Color(0xFF162dd4)),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_alt_outlined,
                          color: Color(0xFF162dd4)),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.sort, color: Color(0xFF162dd4)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(titles[index]), // Display title
                    subtitle: Text(invoices[index]),
                    onTap: () => _navigateToFaturaDetayPage(
                        context,
                        invoices[index],
                        'path_to_image_if_any'), // Update with actual image path
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF162dd4),
        child: Icon(Icons.add),
        onPressed: () => _showFloatingMenu(context),
      ),
    );
  }
}
