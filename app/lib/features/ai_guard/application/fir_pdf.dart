import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const firDisclaimer = 'Draft only. Verify with the police station or a lawyer.';

/// Builds a formal A4 FIR draft: title, header block, body, signature line.
/// Uses the built-in Helvetica/Times fonts so it works fully offline.
Future<Uint8List> buildFirPdf({
  required String body,
  required String complainant,
  required DateTime date,
  String? place,
}) async {
  final doc = pw.Document(title: 'FIR draft', author: complainant.isEmpty ? 'Shakti' : complainant);
  final ink = PdfColor.fromInt(0xFF1E293B);
  final muted = PdfColor.fromInt(0xFF64748B);
  String two(int v) => v.toString().padLeft(2, '0');
  final dateStr = '${two(date.day)}-${two(date.month)}-${date.year}';

  pw.Widget row(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 110, child: pw.Text(k, style: pw.TextStyle(color: muted, fontSize: 10))),
          pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 10))),
        ]),
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 56, 56, 48),
      theme: pw.ThemeData.withFont(base: pw.Font.times(), bold: pw.Font.timesBold()),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(firDisclaimer, style: pw.TextStyle(fontSize: 8, color: muted)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: muted)),
        ],
      ),
      build: (ctx) => [
        pw.Center(
          child: pw.Text(
            'FIRST INFORMATION REPORT',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: ink, letterSpacing: 1),
          ),
        ),
        pw.Center(
          child: pw.Text('(Draft prepared under Section 173, BNSS 2023)', style: pw.TextStyle(fontSize: 10, color: muted)),
        ),
        pw.SizedBox(height: 18),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: muted, width: 0.6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            row('To', 'The Station House Officer'),
            row('Complainant', complainant.isEmpty ? '________________' : complainant),
            row('Date', dateStr),
            if (place != null && place.isNotEmpty) row('Place of incident', place),
          ]),
        ),
        pw.SizedBox(height: 16),
        for (final para in body.split(RegExp(r'\n\s*\n')))
          if (para.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(para.trim(), style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
            ),
        pw.SizedBox(height: 40),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(width: 180, height: 0.6, color: ink),
            pw.SizedBox(height: 4),
            pw.Text('Signature of complainant', style: const pw.TextStyle(fontSize: 10)),
            if (complainant.isNotEmpty) pw.Text(complainant, style: pw.TextStyle(fontSize: 10, color: muted)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(width: 140, height: 0.6, color: ink),
            pw.SizedBox(height: 4),
            pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
          ]),
        ]),
      ],
    ),
  );
  return doc.save();
}
