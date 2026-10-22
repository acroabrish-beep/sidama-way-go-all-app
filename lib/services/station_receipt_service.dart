import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/station_ticket_models.dart';

class StationReceiptService {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  Future<Uint8List> buildReceipt(TicketDetail detail) async {
    final document = pw.Document(
      title: 'Station ticket ${detail.ticket.code}',
      author: 'Sidama Way Go',
    );
    final ticket = detail.ticket;
    final route = detail.route;
    final tariff = detail.tariff;
    final payment = detail.payment ?? ticket.payment;
    final isReceipt = ticket.status == 'paid' || ticket.status == 'used';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Sidama Way Go',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
              pw.Text(
                'Station ticket receipt',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColors.grey400),
          if (!isReceipt) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.orange100,
              child: pw.Text(
                'NOT A PAYMENT RECEIPT - ticket status is ${ticket.status}. '
                'This document does not prove payment.',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
          ],
          _row('Ticket code', ticket.code),
          _row('Route', route?.label ?? 'Route details unavailable'),
          _row('Vehicle type', ticket.vehicleType.label),
          _row('Fare', 'ETB ${_money(ticket.fareEtb)}'),
          _row('Tariff', tariff?.label ?? 'Tariff record unavailable'),
          if (tariff?.sourceReference != null)
            _row('Source reference', tariff!.sourceReference!),
          if (tariff?.approvedBy != null)
            _row('Approved by', tariff!.approvedBy!),
          if (tariff != null)
            _row(
              'Tariff effective',
              '${_dateFormat.format(tariff.effectiveFrom)}'
                  '${tariff.effectiveTo == null ? '' : ' - ${_dateFormat.format(tariff.effectiveTo!)}'}',
            ),
          _row('Issued', _dateFormat.format(ticket.issuedAt)),
          _row('Valid until', _dateFormat.format(ticket.expiresAt)),
          if (ticket.usedAt != null)
            _row('Boarded', _dateFormat.format(ticket.usedAt!)),
          if (ticket.verifiedVehicleId != null)
            _row('Verified vehicle', ticket.verifiedVehicleId!),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          if (payment?.provider == 'dev') ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.orange100,
              child: pw.Text(
                'DEV PAYMENT - no real money was charged. This receipt was produced '
                'with the development payment provider.',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Text(
            'Payment',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          if (payment == null)
            pw.Text(
              'No payment record is attached to this ticket.',
              style: const pw.TextStyle(fontSize: 9),
            )
          else ...[
            _row(
              'Provider',
              payment.provider == 'dev'
                  ? 'dev - DEV PAYMENT'
                  : payment.provider,
            ),
            if (payment.providerRef != null)
              _row('Provider reference', payment.providerRef!),
            if (payment.amountEtb != null)
              _row('Amount', 'ETB ${_money(payment.amountEtb!)}'),
            if (payment.status != null) _row('Payment status', payment.status!),
            if (payment.verifiedAt != null)
              _row('Verified', _dateFormat.format(payment.verifiedAt!)),
          ],
          if (detail.qrToken != null) ...[
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: detail.qrToken!,
                width: 110,
                height: 110,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Present this QR to the driver or assistant at boarding.',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Text(
            'This receipt was generated from the station ticket record stored on the server. '
            'Only a verified payment webhook can mark a ticket as paid.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> shareReceipt(TicketDetail detail) async {
    final bytes = await buildReceipt(detail);
    final fileName = 'sidama-way-go-${detail.ticket.code}.pdf';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName),
        ],
        fileNameOverrides: [fileName],
        subject: 'Sidama Way Go station ticket ${detail.ticket.code}',
      ),
    );
  }

  pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 118,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }
}
