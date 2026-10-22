import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import 'station_ui.dart';
import 'verification_result_card.dart';

class TicketQrScannerScreen extends StatefulWidget {
  const TicketQrScannerScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleLabel,
  });

  final String vehicleId;
  final String vehicleLabel;

  @override
  State<TicketQrScannerScreen> createState() => _TicketQrScannerScreenState();
}

class _TicketQrScannerScreenState extends State<TicketQrScannerScreen> {
  late final MobileScannerController _controller;
  final StationTicketApiService _api = StationTicketApiService();
  bool _processing = false;
  VerificationOutcome? _outcome;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_processing || _outcome != null) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    await _verify(value);
  }

  Future<void> _verify(String token) async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      await _controller.stop();
      final outcome = await _api.verifyQr(
        qrToken: token,
        vehicleId: widget.vehicleId,
      );
      if (!mounted) return;
      setState(() => _outcome = outcome);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      AppLogger.error('QR verification failed', error: error);
      if (!mounted) return;
      setState(() => _error = 'Unable to verify the ticket.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _scanNext() async {
    setState(() {
      _outcome = null;
      _error = null;
    });
    try {
      await _controller.start();
    } catch (error) {
      AppLogger.error('Could not restart the camera', error: error);
      if (!mounted) return;
      setState(() => _error = 'Could not start the camera.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Verify · ${widget.vehicleLabel}'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_outcome != null) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            VerificationResultCard(outcome: _outcome!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _scanNext,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan next ticket'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Container(
        color: Colors.white,
        child: StationErrorView(
          title: 'Verification failed',
          message: _error!,
          onRetry: _scanNext,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _handleCapture,
          errorBuilder: (context, error) {
            return Container(
              color: Colors.white,
              child: StationErrorView(
                title: 'Camera unavailable',
                message: error.errorDetails?.message ?? error.errorCode.name,
                onRetry: _scanNext,
              ),
            );
          },
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Point the camera at the passenger ticket QR. Verification is performed by the server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        if (_processing)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Verifying ticket…',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
