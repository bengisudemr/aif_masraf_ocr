import 'dart:convert'; // JSON dönüşümü için
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP istekleri için

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
  late List<String> invoiceLines;
  late List<Map<String, String>> productDetails;

  @override
  void initState() {
    super.initState();
    invoiceLines = _parseGPTOutput(widget.analysisResult);
    productDetails = _parseProducts(invoiceLines);
  }

  List<String> _parseGPTOutput(String gptOutput) {
    return gptOutput.split('\n');
  }

  List<Map<String, String>> _parseProducts(List<String> lines) {
    List<Map<String, String>> products = [];
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

  Future<void> _saveInvoice() async {
    // Örnek JSON verisi
    final Map<String, dynamic> data = {
      "sirketAdi": widget.invoiceData["sirketAdi"],
      "adres": widget.invoiceData["adres"],
      "vergiDairesi": widget.invoiceData["vergiDairesi"],
      "vergiNumarasi": widget.invoiceData["vergiNumarasi"],
      "fisTarihi": widget.invoiceData["fisTarihi"],
      "fisNo": widget.invoiceData["fisNo"],
    };

    try {
      final response = await http.post(
        Uri.parse('https://masrafapi.aifdigital.com.tr/api/Masraf/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // Başarılı kaydetme işlemi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fatura başarıyla kaydedildi.')),
        );
      } else {
        // Hata durumunda
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Fatura kaydedilemedi. Hata: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Ağ hatası vb.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fatura kaydedilemedi. Hata: $e')),
      );
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
              onPressed: _saveInvoice,
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
      children: [
        _buildTableRow("Şirket Adı", widget.invoiceData["sirketAdi"]),
        _buildTableRow("Adres", widget.invoiceData["adres"]),
        _buildTableRow("Vergi Dairesi", widget.invoiceData["vergiDairesi"]),
        _buildTableRow("Vergi Numarası", widget.invoiceData["vergiNumarasi"]),
        _buildTableRow("Fiş Tarihi", widget.invoiceData["fisTarihi"]),
        _buildTableRow("Saat", widget.invoiceData["saat"]),
        _buildTableRow("Fiş No", widget.invoiceData["fisNo"]),
        _buildTableRow("KDV Oranı", widget.invoiceData["kdvOrani"]),
        _buildTableRow("KDV Tutarı", widget.invoiceData["kdvTutari"]),
        _buildTableRow("Toplam Tutar", widget.invoiceData["toplamTutar"]),
        _buildTableRow("Ödeme Yöntemi", widget.invoiceData["odemeYontemi"]),
      ],
    );
  }

  TableRow _buildTableRow(String label, String? value) {
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
          child: Text(value ?? '-'),
        ),
      ],
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
