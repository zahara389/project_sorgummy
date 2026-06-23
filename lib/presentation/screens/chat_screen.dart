// lib/presentation/screens/chat_screen.dart
// File ini adalah REDIRECT ke implementasi Chat AI Assessment 3.
// Dibuat agar main_navigation.dart dan routing lain TIDAK perlu diubah.
// Semua logika ada di lib/features/chat_ai/screens/chat_ai_screen.dart

import '../../features/chat_ai/screens/chat_ai_screen.dart';
export '../../features/chat_ai/screens/chat_ai_screen.dart';

// Alias agar ChatScreen tetap tersedia (digunakan di main_navigation.dart)
typedef ChatScreen = ChatAiScreen;
