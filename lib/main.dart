import 'package:flutter/material.dart';
import 'package:aif_masraf_ocr/loginpage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF162dd4), // Arka plan rengi
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF162dd4)), // Genel yazı rengi
          bodyMedium: TextStyle(color: Color(0xFF162dd4)), // Genel yazı rengi
          displayLarge: TextStyle(color: Color(0xFF162dd4), fontWeight: FontWeight.bold), // Başlık rengi
          displayMedium: TextStyle(color: Color(0xFF162dd4), fontWeight: FontWeight.bold),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFF162dd4), // Buton arka plan rengi
          textTheme: ButtonTextTheme.primary, // Buton yazı rengi
        ),
        cardTheme: CardTheme(
          color: Color(0xFF162dd4).withOpacity(0.1), // Kart arka plan rengi
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ), colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Color(0xFF162dd4), // Vurgu renkleri
        ).copyWith(secondary: Color(0xFF162dd4)).copyWith(background: Colors.grey[100]),
      ),
      home: Loginpage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
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
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w300),
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
                      icon: Icon(Icons.filter_alt_outlined, color: Color(0xFF162dd4)),
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
                        Text('01/01/2001', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text('Diğer', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HUGIN YAZILIM T...'),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 21, 174, 93),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Hazır', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('15,00 TL', style: TextStyle(color: Color(0xFF162dd4), fontSize: 16)),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Color(0xFF162dd4),
        unselectedItemColor: Colors.grey,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 37),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article, size: 37),
            label: 'Formlarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 68, color: Color(0xFF162dd4)),
            label: 'Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline, size: 37),
            label: 'Onaylar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 37),
            label: 'Ayarlar',
          ),
        ],
        type: BottomNavigationBarType.fixed, // İkonları düzgün yerleştirir
      ),
    );
  }
}
