import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 for Haptic Feedback
import '../theme/AppTheme.dart';
import '../services/api_service.dart'; // make sure this has post() method or similar
import '../constants/api_endpoints.dart';

Future<String> showPinVerificationDialog(BuildContext context) async {
  final List<int> _enteredDigits = [];

  // 🔹 Now returns a String (token or empty string)
  return await showGeneralDialog<String>(
        context: context,
        barrierDismissible: false,
        barrierLabel: "PIN Dialog",
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const SizedBox(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(curved),
              child: _PinDialogContent(enteredDigits: _enteredDigits),
            ),
          );
        },
      ) ??
      ''; // if cancelled or null → return empty string
}

class _PinDialogContent extends StatefulWidget {
  final List<int> enteredDigits;
  const _PinDialogContent({required this.enteredDigits});

  @override
  State<_PinDialogContent> createState() => _PinDialogContentState();
}

Future<Map<String, dynamic>> verifyPinApi(String pin) async {
  final requestBody = {"pin": pin};

  final response = await ApiService.post(
    ApiEndpoints.verifyPin,
    body: requestBody,
  );

  if (response != null) {
    return response;
  } else {
    throw Exception("Server error: ${response.statusCode}");
  }
}

class _PinDialogContentState extends State<_PinDialogContent> {
  bool _wrongPin = false; // 🔴 track wrong pin visually

  void handleKeyTap(int number) async {
    HapticFeedback.lightImpact();
    if (widget.enteredDigits.length < 6) {
      widget.enteredDigits.add(number);
      setState(() {}); // update dots

      if (widget.enteredDigits.length == 6) {
        await Future.delayed(const Duration(milliseconds: 200));
        final pin = widget.enteredDigits.join();

        try {
          final response = await verifyPinApi(pin);

          if (response['valid'] == true) {
            final token = response['token'];
            Navigator.pop(context, token);
          } else {
            throw Exception("Invalid PIN");
          }
        } catch (e) {
          // ❌ Wrong PIN feedback like GPay
          HapticFeedback.vibrate();
          setState(() => _wrongPin = true);

          await Future.delayed(const Duration(milliseconds: 600));
          widget.enteredDigits.clear();
          setState(() => _wrongPin = false);
        }
      }
    }
  }

  void handleBackspace() {
    HapticFeedback.selectionClick();
    if (widget.enteredDigits.isNotEmpty) {
      widget.enteredDigits.removeLast();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keySize = screenWidth * 0.15;
    const double keySpacing = 14.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "🔒 Verify Security PIN",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your 6-digit PIN to confirm this transaction",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  bool filled = index < widget.enteredDigits.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _wrongPin
                          ? Colors
                                .redAccent // 🔴 turns red if wrong
                          : (filled
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              if (_wrongPin)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: const Text(
                    "Wrong PIN. Try again.",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 25),
              for (var row in [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
                ['empty', 0, 'back'],
              ])
                Padding(
                  padding: EdgeInsets.symmetric(vertical: keySpacing / 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map<Widget>((item) {
                      Widget child;
                      if (item is int) {
                        child = _AnimatedKeyButton(
                          number: item,
                          onTap: handleKeyTap,
                          keySize: keySize,
                        );
                      } else if (item == 'back') {
                        child = _AnimatedIconButton(
                          icon: Icons.backspace_rounded,
                          onTap: handleBackspace,
                          keySize: keySize,
                        );
                      } else {
                        child = SizedBox(width: keySize, height: keySize);
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: keySpacing / 2,
                        ),
                        child: child,
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Animated Key Button
class _AnimatedKeyButton extends StatefulWidget {
  final int number;
  final void Function(int) onTap;
  final double keySize;

  const _AnimatedKeyButton({
    required this.number,
    required this.onTap,
    required this.keySize,
  });

  @override
  State<_AnimatedKeyButton> createState() => _AnimatedKeyButtonState();
}

class _AnimatedKeyButtonState extends State<_AnimatedKeyButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _pressed = false);
    widget.onTap(widget.number);
  }

  void _handleTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.keySize,
          height: widget.keySize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "${widget.number}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🔹 Animated Backspace Button
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double keySize;

  const _AnimatedIconButton({
    required this.icon,
    required this.onTap,
    required this.keySize,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _pressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.keySize,
          height: widget.keySize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.black54, size: 20),
        ),
      ),
    );
  }
}
