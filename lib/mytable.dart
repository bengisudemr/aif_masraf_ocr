import 'package:flutter/material.dart';

class DynamicTablePage extends StatelessWidget {
  final List<List<String>> data = [
    ['Header 1', 'Header 2'],
    ['Row 1 Col 1', 'Row 1 Col 2'],
    ['Row 2 Col 1', 'Row 2 Col 2'],
    // Ensure all rows have the same number of columns
  ];

  DynamicTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Table Example'),
      ),
      body: Center(
        child: Table(
          border: TableBorder.all(),
          children: data.map((row) {
            return TableRow(
              children: row.map((cell) {
                return TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(cell),
                ));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
