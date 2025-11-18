import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/register_pan_verify.dart';
import '../MainScreen/topVisualSection.dart'; // <-- Import TopVisualSection

class EnterEmailOtpScreen extends StatefulWidget {
  const EnterEmailOtpScreen({super.key});

  @override
  State<EnterEmailOtpScreen> createState() => _EnterEmailOtpScreenState();
}

class _EnterEmailOtpScreenState extends State<EnterEmailOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool isButtonEnabled = false;

  void _checkOtpFilled() {
    String otp = _controllers.map((c) => c.text).join();
    setState(() {
      isButtonEnabled = otp.length == 6;
    });
  }

  @override
  void initState() {
    super.initState();
    for (var controller in _controllers) {
      controller.addListener(_checkOtpFilled);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onVerify() {
    String otp = _controllers.map((c) => c.text).join();
    print("OTP: $otp");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PanVerificationScreen()),
    );
  }

  void _onSkip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PanVerificationScreen()),
    );
  }

  void _onResend() {
    print("Resend OTP triggered");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("OTP resent to your email")));
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ------------------ TOP VISUAL SECTION ------------------
            TopVisualSection(height: screenHeight * 0.35, logoHeight: 90),

            // ------------------ OTP INPUT SECTION ------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const Text(
                      "Enter the OTP sent to your email",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Please check your inbox and enter the 6-digit code we sent.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _buildOtpBox(index),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled ? _onVerify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text("Verify"),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: _onResend,
                      child: const Text("Resend OTP"),
                    ),
                    TextButton(onPressed: _onSkip, child: const Text("Skip")),
                    const SizedBox(height: 20),

                    const Text(
                      "By continuing you agree to our Terms and Privacy Policy.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
