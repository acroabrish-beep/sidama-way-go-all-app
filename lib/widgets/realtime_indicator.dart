import 'package:flutter/material.dart';

import '../services/realtime_service.dart';

class RealtimeIndicator extends StatelessWidget {
  const RealtimeIndicator({super.key, required this.status});

  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    if (status != RealtimeStatus.reconnecting) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Reconnecting…',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
