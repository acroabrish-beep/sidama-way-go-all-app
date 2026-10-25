import 'package:flutter/material.dart';

import 'station_ui.dart';

class DriverStationScreen extends StatelessWidget {
  const DriverStationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Driver Station'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          StationPhase5Notice(
            title: 'Smart queue check-in/out is scheduled for Phase 5',
            message:
                'The Next.js /api/queue endpoints have been removed. Queue '
                'check-in, queue status and vehicle assignment will move to '
                'authenticated Supabase server functions in Phase 5.',
          ),
          SizedBox(height: 12),
          StationSectionCard(
            title: 'Why the queue is paused',
            icon: Icons.lock_outline,
            child: Text(
              'The existing queue functions require the service role and take '
              'the driver identity as a parameter. Exposing them to the app '
              'would let a client choose whose queue entry it changes. Phase 5 '
              'adds functions that derive the driver from the verified Firebase '
              'token instead.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          StationSectionCard(
            title: 'Ticket verification',
            icon: Icons.qr_code_scanner,
            child: Text(
              'Ticket verification is already enforced server-side by the '
              'verify-ticket Edge Function, including the driver-to-vehicle '
              'assignment check. It returns to this screen once the vehicle '
              'lookup moves to Supabase in Phase 5.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
