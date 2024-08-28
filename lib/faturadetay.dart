import 'package:flutter/material.dart';

void main() {
  runApp(MasrafDetayPage());
}

class MasrafDetayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Geri butonuna basıldığında yapılacak işlemi buraya ekleyebilirsiniz.
            },
          ),
          title: Text(
            "Masraf Detayı",
            style: TextStyle(
              fontSize: 18, // Yazı boyutunu küçültüyoruz
            ),
          ),
          centerTitle: true, // Yazıyı ortalıyoruz
          actions: [
            TextButton(
              onPressed: () {},
              child: Text("Tahsis"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text("Kaydet"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fiş Resmi
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/receipt.jpg', // Bu yolda resim dosyasını ekleyin.
                  height: 300,
                ),
              ),
              SizedBox(height: 20),
              // Kategori Alanı
              _buildDropdownRow("Kategori", "Diğer"),
              Divider(),
              // Masraf Merkezi Alanı
              _buildDropdownRow("Masraf Merkezi", "Seçim Yapınız"),
              Divider(),
              // Toplam Tutar Alanı
              _buildTextRow("Toplam Tutarı", "15,00"),
              Divider(),
              // KDV Oranı Alanı
              _buildDropdownRow("KDV Oranı", "% 0"),
              Divider(),
              // KDV Tutarı Alanı
              _buildTextRow("KDV Tutarı", "0,00"),
              Divider(),
              // Para Birimi Alanı
              _buildDropdownRow("Para Birimi", "TL"),
              Divider(),
              // Kurum Adı Alanı
              _buildTextRow("Kurum Adı", "HUGIN YAZILIM TEKNOLOJILERI"),
              Divider(),
              // Tarih Alanı
              _buildTextRow("Tarih", "24/07/2024"),
              Divider(),
              // Belge No Alanı
              _buildTextRow("Belge No", "0010"),
              Divider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0), // Satırlara 12 birim padding ekliyoruz
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Row(
            children: [
              Text(value, style: TextStyle(fontSize: 16)),
              Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0), // Satırlara 12 birim padding ekliyoruz
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
