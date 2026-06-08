import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/life_record.dart';

class ExportService {
  ExportService._();

  static Future<File> recordsToXlsx(
    String name,
    List<LifeRecord> records,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel[name.length > 25 ? name.substring(0, 25) : name];
    sheet.appendRow([
      TextCellValue('Module'),
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Status'),
      TextCellValue('Priority'),
      TextCellValue('Amount'),
      TextCellValue('Date'),
      TextCellValue('Due Date'),
      TextCellValue('Description'),
    ]);
    for (final record in records) {
      sheet.appendRow([
        TextCellValue(record.module),
        TextCellValue(record.title),
        TextCellValue(record.category),
        TextCellValue(record.status),
        TextCellValue(record.priority),
        DoubleCellValue(record.amount),
        TextCellValue(record.date.toIso8601String()),
        TextCellValue(record.dueDate.toIso8601String()),
        TextCellValue(record.description),
      ]);
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/$name-${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(excel.encode() ?? <int>[]);
    return file;
  }

  static Future<File> recordsToPdf(
    String name,
    List<LifeRecord> records,
  ) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Life Manager Pro - $name'),
          pw.TableHelper.fromTextArray(
            headers: ['Module', 'Title', 'Category', 'Status', 'Amount'],
            data: records
                .map(
                  (record) => [
                    record.module,
                    record.title,
                    record.category,
                    record.status,
                    record.amount.toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/$name-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await document.save());
    return file;
  }

  static Future<File> backupJson(
    List<LifeRecord> records,
    Map<String, dynamic>? profile,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/life-manager-backup-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': profile,
        'records': records.map((record) => record.toJson()).toList(),
      }),
    );
    return file;
  }
}
