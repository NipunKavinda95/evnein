import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/bill_model.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceService {
  static const PdfColor _brand = PdfColor.fromInt(0xFF0F766E); // teal
  static const PdfColor _brandDark = PdfColor.fromInt(0xFF134E4A);

  static Future<File> generateInvoice(BillModel bill) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header band
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                color: _brand,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EVNEIN',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 3,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Shop Management',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _brandDark,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '#${bill.id.substring(0, 8).toUpperCase()}',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Date / Customer row
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        if (bill.customerName != null ||
                            bill.customerPhone != null)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'BILLED TO',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey500,
                                  letterSpacing: 1,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              if (bill.customerName != null)
                                pw.Text(
                                  bill.customerName!,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              if (bill.customerPhone != null)
                                pw.Text(
                                  bill.customerPhone!,
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                            ],
                          )
                        else
                          pw.SizedBox(),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'DATE',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey500,
                                letterSpacing: 1,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              _formatDate(bill.createdAt),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              _formatTime(bill.createdAt),
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 18),

                    // Items table
                    pw.Table(
                      border: pw.TableBorder(
                        horizontalInside: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                      ),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(4),
                        1: pw.FlexColumnWidth(1.2),
                        2: pw.FlexColumnWidth(1.6),
                        3: pw.FlexColumnWidth(1.6),
                      },
                      children: [
                        // Header row
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: _brand,
                          ),
                          children: [
                            _headerCell('ITEM', pw.TextAlign.left),
                            _headerCell('QTY', pw.TextAlign.center),
                            _headerCell('PRICE', pw.TextAlign.right),
                            _headerCell('TOTAL', pw.TextAlign.right),
                          ],
                        ),
                        // Item rows
                        ...bill.items.map(
                          (item) => pw.TableRow(
                            children: [
                              _cell(item.productName, pw.TextAlign.left,
                                  bold: true),
                              _cell('${item.quantity}', pw.TextAlign.center),
                              _cell('Rs ${item.price.toStringAsFixed(0)}',
                                  pw.TextAlign.right),
                              _cell('Rs ${item.total.toStringAsFixed(0)}',
                                  pw.TextAlign.right),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 16),

                    // Totals box
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        width: 200,
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey50,
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _totalRow('Subtotal',
                                'Rs ${bill.subtotal.toStringAsFixed(0)}'),
                            if (bill.discount > 0) ...[
                              pw.SizedBox(height: 4),
                              _totalRow(
                                'Discount',
                                '-Rs ${bill.discount.toStringAsFixed(0)}',
                                valueColor: PdfColors.red700,
                              ),
                            ],
                            pw.SizedBox(height: 8),
                            pw.Divider(color: PdfColors.grey400, height: 1),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _brandDark,
                                  ),
                                ),
                                pw.Text(
                                  'Rs ${bill.grandTotal.toStringAsFixed(0)}',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _brandDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 14),

                    // Payment method badge
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'PAID VIA ${bill.paymentMethod.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 24),
                    pw.Divider(color: PdfColors.grey300, height: 1),
                    pw.SizedBox(height: 12),

                    // Footer
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Thank you for your purchase!',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: _brandDark,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Visit us again soon',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save to temp file
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/invoice_${bill.id.substring(0, 8).toUpperCase()}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _headerCell(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, pw.TextAlign align, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value,
      {PdfColor? valueColor}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Share via WhatsApp
  static Future<void> shareOnWhatsApp({
    required BillModel bill,
    required File pdfFile,
  }) async {
    final phone = bill.customerPhone;

    if (phone != null && phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final whatsappUrl = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(
          'Hi! Your invoice from EVNEIN is attached.\n'
          'Bill: #${bill.id.substring(0, 8).toUpperCase()}\n'
          'Total: Rs.${bill.grandTotal.toStringAsFixed(0)}\n'
          'Payment: ${bill.paymentMethod.toUpperCase()}\n'
          'Thank you for visiting us! 🙏',
        )}',
      );

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      // After the WhatsApp message opens, offer the PDF separately
      // so the user can manually pick the contact and attach it.
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Hi! Your invoice from EVNEIN.\n'
            'Bill: #${bill.id.substring(0, 8).toUpperCase()}\n'
            'Total: Rs ${bill.grandTotal.toStringAsFixed(0)}\n'
            'Payment: ${bill.paymentMethod.toUpperCase()}\n'
            'Thank you for visiting us! 🙏',
      );
    } else {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'EVNEIN Invoice #${bill.id.substring(0, 8).toUpperCase()}\n'
            'Total: Rs.${bill.grandTotal.toStringAsFixed(0)}',
      );
    }
  }

  // Print invoice
  static Future<void> printInvoice(BillModel bill) async {
    final file = await generateInvoice(bill);
    await Printing.layoutPdf(
      onLayout: (_) async => file.readAsBytes(),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
