// ui.dart
import 'package:flutter/material.dart';

class Ui {
  static const dark = Color(0xFF1F1F1F);
  static const orange = Color(0xFFD68500);

  static TextStyle get h2 => const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);

  static Widget statTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  static Widget emptyCard(String text) => Container(
    height: 140,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );
}
