import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaturaDetayPage extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> invoiceData; // JSON verisi

  FaturaDetayPage({
    required this.imagePath,
    required this.invoiceData,
    required String analysisResult,
  });

  @override
  _FaturaDetayPageState createState() => _FaturaDetayPageState();
}

class _FaturaDetayPageState extends State<FaturaDetayPage> {
  late TextEditingController sirketAdiController;
  late TextEditingController adresController;
  late TextEditingController vergiDairesiController;
  late TextEditingController vergiNumarasiController;
  late TextEditingController fisNoController;
  late TextEditingController kdvTutariController;
  late TextEditingController toplamTutarController;

  List<dynamic> productList = []; // Ürün listesi

  @override
  void initState() {
    super.initState();

    // JSON verisini TextEditingController'lara atıyoruz
    Map<String, dynamic> invoiceData = widget.invoiceData;

    sirketAdiController =
        TextEditingController(text: invoiceData['sirketAdi'] ?? "Veri yok");
    adresController =
        TextEditingController(text: invoiceData['adres'] ?? "Veri yok");
    vergiDairesiController =
        TextEditingController(text: invoiceData['vergiDairesi'] ?? "Veri yok");
    vergiNumarasiController =
        TextEditingController(text: invoiceData['vergiNumarasi'] ?? "Veri yok");
    fisNoController =
        TextEditingController(text: invoiceData['fisNo'] ?? "Veri yok");
    kdvTutariController =
        TextEditingController(text: invoiceData['kdvTutari'] ?? "0.00");
    toplamTutarController =
        TextEditingController(text: invoiceData['toplamTutar'] ?? "0.00");

    // Eğer ürün listesi varsa, productList'i doldur
    if (invoiceData.containsKey('urunler')) {
      productList = invoiceData['urunler'];
    }
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
            _buildReceiptInfoTable(), // Fatura bilgileri tablosu
            SizedBox(height: 20),
            if (productList.isNotEmpty) // Ürün bilgileri varsa göster
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satın Alınan Ürünler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildProductTable(), // Ürün bilgileri tablosu
                  SizedBox(height: 20),
                ],
              ),
            Center(
              child: ElevatedButton(
                onPressed: _sendDataToApi,
                child: Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fatura bilgilerini tabloya yerleştirme
  Widget _buildReceiptInfoTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(7),
      },
      children: [
        _buildTableRow('Şirket Adı', sirketAdiController.text),
        _buildTableRow('Adres', adresController.text),
        _buildTableRow('Vergi Dairesi', vergiDairesiController.text),
        _buildTableRow('Vergi Numarası', vergiNumarasiController.text),
        _buildTableRow('Fiş No', fisNoController.text),
        _buildTableRow('KDV Tutarı', kdvTutariController.text),
        _buildTableRow('Toplam Tutar', toplamTutarController.text),
      ],
    );
  }

  // Tablo satırı oluşturma
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }

  // Ürün tablosu
  Widget _buildProductTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(6),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        _buildProductTableHeader(),
        // Her ürün için tablo satırı oluştur
        for (var product in productList)
          _buildProductTableRow(
            product['urunAdi'] ?? 'Ürün adı yok',
            product['kdvOrani'] ?? '0%',
            product['tutar'] ?? '0.00',
          ),
      ],
    );
  }

  TableRow _buildProductTableHeader() {
    return TableRow(
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
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Tutar',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  TableRow _buildProductTableRow(
      String productName, String taxRate, String amount) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(productName),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            taxRate,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            amount,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _sendDataToApi() async {
    try {
      // API'ye gönderilecek verileri hazırlıyoruz
      final Map<String, dynamic> data = {
        'id': 0, // Varsayılan id
        'sirketAdi': sirketAdiController.text.isNotEmpty
            ? sirketAdiController.text
            : "Bilinmeyen Şirket",
        'adres': adresController.text.isNotEmpty
            ? adresController.text
            : "Adres mevcut değil",
        'vergiDairesi': vergiDairesiController.text.isNotEmpty
            ? vergiDairesiController.text
            : "Vergi Dairesi bilinmiyor",
        'vergiNumarasi': vergiNumarasiController.text.isNotEmpty
            ? vergiNumarasiController.text
            : "Vergi numarası eksik",
        'fisNo': fisNoController.text.isNotEmpty
            ? fisNoController.text
            : "Fiş numarası eksik",
        'kdvTutari':
            double.tryParse(kdvTutariController.text) ?? 0.0, // KDV Tutarı
        'toplamTutar':
            double.tryParse(toplamTutarController.text) ?? 0.0, // Toplam Tutar
        'faturaDurumu': 0 // Sabit fatura durumu
      };

      final response = await http.post(
        Uri.parse('https://masrafapi.aifdigital.com.tr/api/Masraf/create'),
        headers: {
          HttpHeaders.acceptHeader: 'text/plain',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(data), // JSON verisini dönüştürüp gönderiyoruz
      );

      // API yanıtına göre kullanıcıya bilgi ver
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fatura başarıyla kaydedildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme başarısız: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Hata durumunda hata mesajını göster
      print('Error sending data to API: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }
}
