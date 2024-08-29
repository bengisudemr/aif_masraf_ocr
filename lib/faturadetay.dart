import 'dart:io';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class FaturaDetayPage extends StatelessWidget {
  final String analysisResult;
  final String imagePath;

  FaturaDetayPage(
      {required this.analysisResult,
      required this.imagePath,
      required Map invoiceData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura Detayı'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the uploaded image with error handling
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  height: 300,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                        child: Text('Görsel yüklenirken bir hata oluştu',
                            textAlign: TextAlign.center));
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            ..._parseHtmlTable(analysisResult),
          ],
        ),
      ),
    );
  }

  List<Widget> _parseHtmlTable(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final List<Widget> widgets = [];

    final tables = document.getElementsByTagName('table');
    if (tables.isEmpty) {
      widgets.add(Center(child: Text('HTML içeriğinde tablo bulunamadı')));
      return widgets;
    }

    for (var table in tables) {
      final rows = _parseTableRows(table);
      if (rows.isNotEmpty) {
        widgets.add(
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey),
              children: rows,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<TableRow> _parseTableRows(html_dom.Element table) {
    final rows = <TableRow>[];
    final headerRows = table.getElementsByTagName('tr');

    if (headerRows.isNotEmpty) {
      final headerCells = headerRows.first.getElementsByTagName('th');
      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          children: headerCells.map((th) {
            return TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  th.text,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            );
          }).toList(),
        ),
      );

      final columnCount = headerCells.length;

      final bodyRows = headerRows.skip(1);
      for (var row in bodyRows) {
        final cells = row.getElementsByTagName('td');
        // Ensure that the number of cells matches the header count
        if (cells.length != columnCount) {
          // If the number of cells is different, pad with empty cells
          rows.add(
            TableRow(
              children: List.generate(columnCount, (index) {
                return TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      index < cells.length ? cells[index].text : '',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
              }),
            ),
          );
        } else {
          rows.add(
            TableRow(
              children: cells.map((td) {
                return TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(td.text),
                  ),
                );
              }).toList(),
            ),
          );
        }
      }
    }

    return rows;
  }
}
