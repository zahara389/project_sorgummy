// lib/features/chat_ai/widgets/ai_status_card.dart
// Custom widget AIStatusCard menampilkan status AI (Online/Thinking/Ready).
// Menggunakan animasi Lottie saat status 'thinking'.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum AIStatus { ready, thinking, offline }

class AIStatusCard extends StatelessWidget {
  final AIStatus status;
  final String? modeName;

  const AIStatusCard({
    Key? key,
    required this.status,
    this.modeName,
  }) : super(key: key);

  String get _statusLabel {
    switch (status) {
      case AIStatus.thinking:
        return 'Memproses...';
      case AIStatus.offline:
        return 'Offline';
      case AIStatus.ready:
        return 'Siap membantu';
    }
  }

  Color get _statusColor {
    switch (status) {
      case AIStatus.thinking:
        return const Color(0xFF2196F3);
      case AIStatus.offline:
        return const Color(0xFF9E9E9E);
      case AIStatus.ready:
        return const Color(0xFF65B713);
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case AIStatus.thinking:
        return Icons.pending_rounded;
      case AIStatus.offline:
        return Icons.cloud_off_rounded;
      case AIStatus.ready:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie hanya saat thinking, icon biasa untuk status lain
          SizedBox(
            width: 28,
            height: 28,
            child: status == AIStatus.thinking
                ? Lottie.asset(
                    'assets/lottie/ai_thinking.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  )
                : Icon(_statusIcon, color: _statusColor, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sorgummi AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
              Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: _statusColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          if (modeName != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                modeName!,
                style: TextStyle(
                  fontSize: 10,
                  color: _statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
