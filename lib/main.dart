import 'dart:convert';
import 'dart:io';
import 'package:aif_masraf_ocr/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

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

class MyHomePage extends StatelessWidget {
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

    if (result != null) {
      final file = result.files.single;
      if (file.path != null) {
        final ocrResult = await _sendToGoogleVisionApi(file.path!);
        _navigateToFaturaDetayPage(context, ocrResult);
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

    if (result != null) {
      final file = result.files.single;
      if (file.path != null) {
        final ocrResult = await _sendToGoogleVisionApi(file.path!);
        _navigateToFaturaDetayPage(context, ocrResult);
      } else {
        print('File path is null.');
      }
    } else {
      print('No file selected.');
    }
  }

  Future<String> _sendToGoogleVisionApi(String filePath) async {
    final apiKey = 'AIzaSyD5h3xkxwta5NbUJ7a0W7tKE-nbwytWo7s';
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
      final ocrText = jsonResponse['responses']?[0]['fullTextAnnotation']
              ?['text'] ??
          'OCR sonucu bulunamadı.';
      return ocrText;
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to get OCR result.');
    }
  }

  void _navigateToFaturaDetayPage(BuildContext context, String ocrResult) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaturaDetayPage(ocrResult: ocrResult),
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
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                Card(
                  child: ListTile(
                    leading: Image.network(
                      'https://via.placeholder.com/50',
                      width: 75,
                      height: 75,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masraf 1',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Tarih: 12/12/2024'),
                        Text('Miktar: \$100'),
                      ],
                    ),
                    trailing: Icon(Icons.more_vert),
                    onTap: () {},
                  ),
                ),
                // Add more ListTile or Widgets here
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF162dd4),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 37),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article, size: 37),
            label: 'Formlarım',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () => _showFloatingMenu(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF162dd4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.white, size: 37),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 37),
            label: 'Ara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 37),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class FaturaDetayPage extends StatelessWidget {
  final String ocrResult;

  FaturaDetayPage({required this.ocrResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF162dd4),
        title: Text('Fatura Detayları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OCR Sonuçları:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(ocrResult),
              // Add more widgets to display the OCR result details as needed
            ],
          ),
        ),
      ),
    );
  }
}
