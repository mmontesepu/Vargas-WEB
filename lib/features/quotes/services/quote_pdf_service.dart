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

  static final PdfColor _gold = PdfColor.fromHex('#A87937');

  static final PdfColor _dark = PdfColor.fromHex('#242424');

  static Future<void> generate(Quote q) async {
    final doc = pw.Document();

    final logo = await rootBundle.load(
      'assets/images/logo.png',
    );

    final logoImage = pw.MemoryImage(
      logo.buffer.asUint8List(),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(
                logoImage,
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
                  pw.SizedBox(height: 5),
                  pw.Text(q.id),
                  pw.Text(
                    '${q.date.day.toString().padLeft(2, '0')}/'
                    '${q.date.month.toString().padLeft(2, '0')}/'
                    '${q.date.year}',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: _gold),
          pw.SizedBox(height: 16),
          _sectionTitle('CLIENTE'),
          pw.Text(q.client),
          if (q.email.trim().isNotEmpty) pw.Text(q.email),
          if (q.projectName.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('PROYECTO / OBRA'),
            pw.Text(q.projectName),
          ],
          if (q.address.trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Dirección de obra: ${q.address}',
            ),
          ],
          pw.SizedBox(height: 28),
          _sectionTitle('DETALLE DE LOS TRABAJOS'),
          pw.SizedBox(height: 12),
          ...q.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return pw.Container(
              margin: const pw.EdgeInsets.only(
                bottom: 13,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey300,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _dark,
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(5),
                        topRight: pw.Radius.circular(5),
                      ),
                    ),
                    child: pw.Text(
                      '${index + 1}. ${item.description}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  if (item.activities.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: item.activities.map(
                          (activity) {
                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                bottom: 7,
                              ),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '• ',
                                    style: pw.TextStyle(
                                      color: _gold,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      activity,
                                      style: const pw.TextStyle(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _amountRow(
                  'Neto general',
                  _money(q.net),
                ),
                pw.SizedBox(height: 8),
                _amountRow(
                  'IVA (19 %)',
                  _money(q.vat),
                ),
                pw.Divider(),
                _amountRow(
                  'TOTAL COTIZACIÓN',
                  _money(q.total),
                  highlighted: true,
                ),
              ],
            ),
          ),
          if (q.payment.trim().isNotEmpty) ...[
            pw.SizedBox(height: 28),
            _sectionTitle('FORMA DE PAGO'),
            pw.SizedBox(height: 5),
            pw.Text(q.payment),
          ],
          if (q.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('OBSERVACIONES'),
            pw.SizedBox(height: 5),
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

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _gold,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _amountRow(
    String label,
    String value, {
    bool highlighted = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: highlighted ? 13 : 10,
            fontWeight: highlighted ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: highlighted ? 17 : 11,
            fontWeight: pw.FontWeight.bold,
            color: highlighted ? _gold : PdfColors.black,
          ),
        ),
      ],
    );
  }
}
