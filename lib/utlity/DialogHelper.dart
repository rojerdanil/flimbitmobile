import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class DialogHelper {
  static void showErrorDialog(BuildContext context, String message) {
    // For web: show a simple SnackBar (non-blocking, works reliably)
    if (kIsWeb) {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        debugPrint("⚠️ ScaffoldMessenger not found. Message: $message");
      }
      return;
    }

    // For mobile/native: show proper dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}
