import 'package:flutter/material.dart';

class ProgressLoader {
  static bool _isShowing = false;

  static void show(BuildContext context, {String? message}) {
    if (_isShowing) return; // prevent multiple dialogs
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false, // cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // disable back button
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Text(message, style: const TextStyle(color: Colors.white)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (_isShowing) {
      _isShowing = false;
      Navigator.of(context, rootNavigator: true).pop(); // close dialog
    }
  }
}
