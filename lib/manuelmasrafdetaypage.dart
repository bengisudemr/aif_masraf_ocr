import 'package:flutter/material.dart';

class ManuelMasrafFormPage extends StatefulWidget {
  @override
  _ManuelMasrafFormPageState createState() => _ManuelMasrafFormPageState();
}

class _ManuelMasrafFormPageState extends State<ManuelMasrafFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Form veri değişkenleri
  String? _companyName;
  String? _address;
  String? _taxOffice;
  String? _taxNumber;
  String? _receiptDate;
  String? _time;
  String? _receiptNumber;
  String? _vatRate;
  String? _vatAmount;
  String? _totalAmount;
  String? _paymentMethod;
  List<Map<String, String>> _products = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Manuel Masraf Girişi",
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
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState?.save();
                // Form verilerini işleyin veya bir sayfaya yönlendirin
                Navigator.pop(context);
              }
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
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/receipt.jpg', // Örnek resim
                  height: 300,
                ),
              ),
              SizedBox(height: 20),
              _buildTextFormField(
                label: 'Şirket Adı',
                onSaved: (value) => _companyName = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Adres',
                onSaved: (value) => _address = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Vergi Dairesi',
                onSaved: (value) => _taxOffice = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Vergi Numarası',
                onSaved: (value) => _taxNumber = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Fiş Tarihi',
                onSaved: (value) => _receiptDate = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Saat',
                onSaved: (value) => _time = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Fiş No',
                onSaved: (value) => _receiptNumber = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'KDV Oranı',
                onSaved: (value) => _vatRate = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'KDV Tutarı',
                onSaved: (value) => _vatAmount = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Toplam Tutar',
                onSaved: (value) => _totalAmount = value,
              ),
              Divider(),
              _buildTextFormField(
                label: 'Ödeme Yöntemi',
                onSaved: (value) => _paymentMethod = value,
              ),
              Divider(),
              _buildProductList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      {required String label, required FormFieldSetter<String> onSaved}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onSaved: onSaved,
        validator: (value) =>
            value?.isEmpty ?? true ? 'Bu alan boş bırakılamaz' : null,
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Satın Alınan Ürünler',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ..._products.map((product) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextRow("Ürün Adı", product['name'] ?? ''),
              _buildTextRow("KDV Oranı", product['vatRate'] ?? ''),
              _buildTextRow("Tutar", product['amount'] ?? ''),
              Divider(),
            ],
          );
        }).toList(),
      ],
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
