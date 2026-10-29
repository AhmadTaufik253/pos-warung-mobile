import 'package:flutter/material.dart';

class AppConstants {
  // Ganti ke IP LAN laptop Anda (cth: http://192.168.1.10:8000/api/v1) jika menggunakan device HP fisik via WiFi.
  // Gunakan 10.0.2.2 untuk Android Emulator bawaan Android Studio.
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  // static const String baseUrl = 'http://192.168.1.9:8000/api/v1';
  // Catatan:
  // - Android Emulator : http://10.0.2.2:8000/api/v1
  // - Chrome / Windows : http://127.0.0.1:8000/api/v1
  // - HP Fisik Android : http://[IP-Komputer-Anda]:8000/api/v1 (misal: 192.168.1.15)

  // Tema Warna Brand Sembako
  static const Color primaryGreen = Color(0xFF065F46); // Emerald 800
  static const Color accentGreen = Color(0xFF059669);  // Emerald 600
  static const Color lightGreen = Color(0xFFECFDF5);   // Emerald 50
  static const Color amberWarning = Color(0xFFD97706); // Amber 600
  static const Color bgLight = Color(0xFFF8FAFC);      // Slate 50
  static const Color borderGrey = Color(0xFFE2E8F0);   // Slate 200
  static const Color textDark = Color(0xFF1E293B);     // Slate 800
  static const Color textMuted = Color(0xFF64748B);    // Slate 500
}