import 'package:flutter/material.dart';

class MasrafDetayPage extends StatelessWidget {
  final Map<String, dynamic> gptData;

  MasrafDetayPage({required this.gptData, required String ocrText});

  @override
  Widget build(BuildContext context) {
    print(gptData);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Masraf Detayı",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                // Tahsis butonuna tıklama işlevi
              },
              child: Text("Tahsis"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            TextButton(
              onPressed: () {
                // Kaydet butonuna tıklama işlevi
              },
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
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/receipt.jpg',
                  height: 300,
                ),
              ),
              SizedBox(height: 20),
              _buildTextRow("Şirket Adı", gptData['Şirket Adı'] ?? 'N/A'),
              Divider(),
              _buildTextRow("Adres", gptData['Adres'] ?? 'N/A'),
              Divider(),
              _buildTextRow("Vergi Dairesi", gptData['Vergi Dairesi'] ?? 'N/A'),
              Divider(),
              _buildTextRow(
                  "Vergi Numarası", gptData['Vergi Numarası'] ?? 'N/A'),
              Divider(),
              _buildTextRow("Fiş Tarihi", gptData['Fiş Tarihi'] ?? 'N/A'),
              Divider(),
              _buildTextRow("Saat", gptData['Saat'] ?? 'N/A'),
              Divider(),
              _buildTextRow("Fiş No", gptData['Fiş No'] ?? 'N/A'),
              Divider(),
              _buildTextRow("KDV Oranı", gptData['KDV Oranı'] ?? 'N/A'),
              Divider(),
              _buildTextRow("KDV Tutarı", gptData['KDV Tutarı'] ?? 'N/A'),
              Divider(),
              _buildTextRow("Toplam Tutar", gptData['Toplam Tutar'] ?? 'N/A'),
              Divider(),
              _buildTextRow("Ödeme Yöntemi", gptData['Ödeme Yöntemi'] ?? 'N/A'),
              Divider(),
              if (gptData['Satın Alınan Ürünler'] != null)
                ...gptData['Satın Alınan Ürünler'].map<Widget>((item) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextRow("Ürün Adı", item['Ürün Adı'] ?? 'N/A'),
                      _buildTextRow("KDV Oranı", item['KDV Oranı'] ?? 'N/A'),
                      _buildTextRow("Tutar", item['Tutar'] ?? 'N/A'),
                      Divider(),
                    ],
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
