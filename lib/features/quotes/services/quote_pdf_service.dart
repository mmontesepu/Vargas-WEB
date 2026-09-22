import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/quote.dart';

String _money(num value) => '\$${value.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}';

class QuotePdfService {
  QuotePdfService._();

  static Future<void> generate(Quote q) async {
    final doc = pw.Document();

    final logo = await rootBundle.load('assets/images/logo.png');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(
                pw.MemoryImage(logo.buffer.asUint8List()),
                width: 100,
                height: 100,
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'COTIZACIÓN',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(q.id),
                  pw.Text(
                    '${q.date.day}/${q.date.month}/${q.date.year}',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            'CLIENTE',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#A87937'),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(q.client),
          if (q.email.isNotEmpty) pw.Text(q.email),
          if (q.address.isNotEmpty) pw.Text(q.address),
          pw.SizedBox(height: 28),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Descripción',
              'Unidad',
              'Cant.',
              'P. unitario',
              'Total',
            ],
            data: q.items
                .map(
                  (item) => [
                    item.description,
                    item.unit,
                    item.quantity.toString(),
                    _money(item.price),
                    _money(item.total),
                  ],
                )
                .toList(),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#242424'),
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellPadding: const pw.EdgeInsets.all(9),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Neto: ${_money(q.net)}'),
                pw.Text('IVA 19%: ${_money(q.vat)}'),
                pw.SizedBox(height: 8),
                pw.Text(
                  'TOTAL: ${_money(q.total)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#A87937'),
                  ),
                ),
              ],
            ),
          ),
          if (q.payment.isNotEmpty) ...[
            pw.SizedBox(height: 32),
            pw.Text(
              'FORMA DE PAGO',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(q.payment),
          ],
          if (q.notes.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            pw.Text(
              'OBSERVACIONES',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(q.notes),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${q.id}.pdf',
    );
  }
}
