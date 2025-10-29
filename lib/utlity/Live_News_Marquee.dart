import 'package:flutter/material.dart';
import '../utlity/MultiScrollMarquee.dart'; // adjust path if needed

class LiveNewsMarquee extends StatelessWidget {
  final List<String> messages = [
    "Leo 150 crore collected",
    "Jailer 120 crore collected",
    "Vikram 200 crore collected",
  ];

  LiveNewsMarquee({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      color: const Color(0xFF1E3A8A),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white),
            ),
            child: const Text(
              "LIVE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MultiScrollMarquee(
              messages: messages,
              velocity: 60,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
