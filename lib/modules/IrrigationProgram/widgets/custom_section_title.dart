import 'package:flutter/material.dart';

Widget buildSectionTitle({required String title, required BuildContext context}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10, top: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF5B21B6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
    ),
  );
}
