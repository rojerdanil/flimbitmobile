import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/AppTheme.dart';
import '../screens/PhoneVerificationScreen.dart';
import '../screens/register_userName.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String phoneNumber; // pass phone number from previous screen

  const VerifyOtpScreen({super.key, required this.phoneNumber});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  int _secondsRemaining = 50;
  Timer? _timer;
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    for (var controller in _controllers) {
      controller.addListener(_checkOtpFilled);
    }
  }

  void startTimer() {
    _timer?.cancel();
    _secondsRemaining = 50;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _checkOtpFilled() {
    setState(() {
      isButtonEnabled = _controllers.every(
        (controller) => controller.text.isNotEmpty,
      );
    });
  }

  void verifyOtp() {
    String otp = _controllers.map((c) => c.text).join();
    print("Entered OTP: $otp");
    // TODO: call backend for OTP verification

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EnterNameScreen()),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.3;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Enter 6-digit code sent to",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                "+91 ${widget.phoneNumber}",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _controllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Resend OTP text
              _secondsRemaining > 0
                  ? Text(
                      "Didn't receive OTP? Resend in $_secondsRemaining s",
                      style: const TextStyle(color: Colors.grey),
                    )
                  : GestureDetector(
                      onTap: startTimer,
                      child: const Text(
                        "Resend OTP",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 30),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isButtonEnabled ? verifyOtp : null,
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
              const SizedBox(height: 16),

              // Wrong number? Edit
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhoneVerificationScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Wrong number? Edit",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
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
