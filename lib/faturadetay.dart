import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaturaDetayPage extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> invoiceData;

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

  List<dynamic> productList = [];
  bool _isLoading = false;
  String? kullaniciId; // Kullanici ID

  @override
  void initState() {
    super.initState();
    _loadKullaniciId(); // KullaniciId'yi yükle
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

    if (invoiceData.containsKey('urunler')) {
      productList = invoiceData['urunler'];
    }
  }

  Future<void> _loadKullaniciId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      kullaniciId = prefs.getString('kullaniciId'); // KullaniciId'yi al
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura Detayı'),
        backgroundColor: Color(0xFF162dd4),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                _buildReceiptInfoTable(),
                SizedBox(height: 20),
                if (productList.isNotEmpty)
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
                      _buildProductTable(),
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/save.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.fill,
                ),
              ),
            ),
        ],
      ),
    );
  }

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
      children: const [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Ürün Adı',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'KDV Oranı',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
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
    if (kullaniciId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Kullanıcı ID bulunamadı. Lütfen tekrar deneyin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://mobilapi.aifdigital.com.tr/api/Masraf/create'),
      );

      if (widget.imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'MasrafFoto',
          widget.imagePath,
        ));
      }

      request.fields['id'] = '0';
      request.fields['kullaniciId'] = kullaniciId ?? '0'; // Kullanıcı ID
      request.fields['sirketAdi'] = sirketAdiController.text.isNotEmpty
          ? sirketAdiController.text
          : "Bilinmeyen Şirket";
      request.fields['adres'] = adresController.text.isNotEmpty
          ? adresController.text
          : "Adres mevcut değil";
      request.fields['vergiDairesi'] = vergiDairesiController.text.isNotEmpty
          ? vergiDairesiController.text
          : "Vergi Dairesi bilinmiyor";
      request.fields['vergiNumarasi'] = vergiNumarasiController.text.isNotEmpty
          ? vergiNumarasiController.text
          : "Vergi numarası eksik";
      request.fields['fisNo'] = fisNoController.text.isNotEmpty
          ? fisNoController.text
          : "Fiş numarası eksik";
      request.fields['kdvTutari'] =
          double.tryParse(kdvTutariController.text)?.toString() ?? "0.0";
      request.fields['toplamTutar'] =
          double.tryParse(toplamTutarController.text)?.toString() ?? "0.0";
      request.fields['faturaDurumu'] = '0';
      request.fields['masrafPath'] = widget.imagePath;

      request.fields['kullanici[id]'] = kullaniciId ?? '0';
      request.fields['kullanici[kullaniciAdi]'] = 'string';
      request.fields['kullanici[ad]'] = 'string';
      request.fields['kullanici[soyad]'] = 'string';
      request.fields['kullanici[sifre]'] = 'string';
      request.fields['kullanici[masraflar][0]'] = 'string';

      for (int i = 0; i < productList.length; i++) {
        var product = productList[i];
        request.fields['urunler[$i][urunId]'] = '0';
        request.fields['urunler[$i][urunAdi]'] =
            product['urunAdi'] ?? 'Ürün adı yok';
        request.fields['urunler[$i][kdvOrani]'] =
            double.tryParse(product['kdvOrani'])?.toString() ?? "0.0";
        request.fields['urunler[$i][toplamTutar]'] =
            double.tryParse(product['tutar'])?.toString() ?? "0.0";
        request.fields['urunler[$i][masrafId]'] = '0';
        request.fields['urunler[$i][masraf]'] = 'string';
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
