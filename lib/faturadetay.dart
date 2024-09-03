import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  late List<TextEditingController> controllers;
  late List<bool> isEditing;

  @override
  void initState() {
    super.initState();
    invoiceLines = _parseGPTOutput(widget.analysisResult);
    controllers =
        invoiceLines.map((line) => TextEditingController(text: line)).toList();
    isEditing = List<bool>.filled(invoiceLines.length, false);
  }

  List<String> _parseGPTOutput(String gptOutput) {
    return gptOutput.split('\n');
  }

  Future<void> _sendDataToApi() async {
    try {
      final Map<String, dynamic> data = _prepareJsonData();

      final response = await http.post(
        Uri.parse('https://masrafapi.aifdigital.com.tr/api/Masraf/create'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Başarıyla kaydedildi')),
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${errorResponse['title']}')),
        );
      }
    } catch (e) {
      print('Error sending data to API: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu')),
      );
    }
  }

  Map<String, dynamic> _prepareJsonData() {
    final Map<String, dynamic> data = {
      'masraf': 'Masraf Adı', // Bu alanı uygun bir değerle doldurun
      'sirketAdi': controllers[0].text,
      'adres': controllers[1].text,
      'vergiDairesi': controllers[2].text,
      'vergiNumarasi': controllers[3].text,
      'fisTarihi': _formatDate(controllers[4].text), // Tarih formatı düzenlendi
      'saat': _formatTime(controllers[5].text), // Saat formatı düzenlendi
      'fisNo': controllers[6].text,
      'kdvOrani': controllers[7].text,
      'kdvTutari': controllers[8].text,
      'toplamTutar': controllers[9].text,
      'odemeYontemi': controllers[10].text,
      'urunler': _prepareProductList(),
    };
    return data;
  }

  List<Map<String, dynamic>> _prepareProductList() {
    final List<Map<String, dynamic>> products = [];
    for (int i = 11; i < controllers.length; i += 2) {
      products.add({
        'urunAdi': controllers[i].text,
        'tutar': controllers[i + 1].text,
      });
    }
    return products;
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return parsedDate.toIso8601String();
    } catch (e) {
      print('Invalid date format: $date');
      return '';
    }
  }

  String _formatTime(String time) {
    try {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        return '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}:00';
      } else if (timeParts.length == 3) {
        return '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}:${timeParts[2].padLeft(2, '0')}';
      }
    } catch (e) {
      print('Invalid time format: $time');
    }
    return '00:00:00';
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

  Widget _buildInvoiceInfoTable() {
    List<TableRow> rows = [];
    for (int i = 0; i < invoiceLines.length; i++) {
      final parts = invoiceLines[i].split('|');
      if (parts.length >= 2) {
        rows.add(_buildEditableTableRow(i, parts[1].trim(), parts[2].trim()));
      } else {
        rows.add(_buildEditableTableRow(i, '', invoiceLines[i].trim()));
      }
    }

    rows.add(_buildEditableTableRow(-1, 'Toplam Tutar', _extractTotalAmount()));

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(7),
        1: FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  TableRow _buildEditableTableRow(int index, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildEditableCell(index == -1 ? null : index, label,
              isLabel: true),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildEditableCell(index == -1 ? null : index, value),
        ),
      ],
    );
  }

  Widget _buildEditableCell(int? index, String text, {bool isLabel = false}) {
    if (index == null) {
      return Text(text, style: TextStyle(fontWeight: FontWeight.bold));
    }

    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          isEditing[index] = true;
        });
      },
      child: isEditing[index]
          ? TextFormField(
              controller: controllers[index],
              onFieldSubmitted: (newValue) {
                setState(() {
                  invoiceLines[index] = newValue;
                  controllers[index].text = newValue;
                  isEditing[index] = false;
                });
              },
              onEditingComplete: () {
                setState(() {
                  isEditing[index] = false;
                });
              },
              autofocus: true,
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          : Text(text.isNotEmpty ? text : '-',
              style: TextStyle(fontWeight: isLabel ? FontWeight.bold : null)),
    );
  }

  String _extractTotalAmount() {
    for (String line in invoiceLines) {
      if (line.contains('Toplam Tutar')) {
        final parts = line.split('|');
        if (parts.length >= 3) {
          return parts[2].trim();
        }
      }
    }
    return '0.00';
  }

  Widget _buildProductsTable() {
    List<TableRow> rows = [];
    bool foundProducts = false;

    for (int i = 0; i < invoiceLines.length; i++) {
      final line = invoiceLines[i];
      if (foundProducts) {
        final parts = line.split('|');
        if (parts.length >= 4) {
          rows.add(
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildEditableCell(i, parts[1].trim()), // Ürün adı
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildEditableCell(i, parts[3].trim()), // Tutar
                ),
              ],
            ),
          );
        }
      } else if (line.contains('SATIN ALINAN ÜRÜNLER')) {
        foundProducts = true;
      }
    }

    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(7),
        1: FlexColumnWidth(3),
      },
      children: [
        _buildProductsTableHeaderRow(),
        ...rows,
      ],
    );
  }

  TableRow _buildProductsTableHeaderRow() {
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
            'Tutar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
