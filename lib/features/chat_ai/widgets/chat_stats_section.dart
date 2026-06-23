// lib/features/chat_ai/widgets/chat_stats_section.dart
// Widget statistik chat: Total Percakapan, Total Pertanyaan, Total Favorit.
// Menggunakan AIStatusCard sebagai inspirasi desain.

import 'package:flutter/material.dart';

class ChatStatsSection extends StatelessWidget {
  final int totalConversations;
  final int totalQuestions;
  final int totalFavorites;

  const ChatStatsSection({
    Key? key,
    required this.totalConversations,
    required this.totalQuestions,
    required this.totalFavorites,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Percakapan',
              value: totalConversations,
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF65B713),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _StatCard(
              label: 'Pertanyaan',
              value: totalQuestions,
              icon: Icons.help_outline_rounded,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _StatCard(
              label: 'Favorit',
              value: totalFavorites,
              icon: Icons.star_outline_rounded,
              color: const Color(0xFFFFC107),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
