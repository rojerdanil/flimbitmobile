import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/AppTheme.dart';
import '../screens/PhoneVerificationScreen.dart';
import '../screens/register_userName.dart';
import '../MainScreen/topVisualSection.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String sessionId;

  VerifyOtpScreen({required this.phoneNumber, required this.sessionId});

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
  bool isLoading = false; // 🔥 ADDED loading flag

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
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _checkOtpFilled() {
    setState(() {
      isButtonEnabled = _controllers.every((c) => c.text.isNotEmpty);
    });
  }

  // 🔥🔥 MAKE OTP VERIFY API CALL HERE
  Future<void> verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();

    setState(() => isLoading = true);

    try {
      final payload = {
        "phoneNumber": widget.phoneNumber,
        "sessionId": widget.sessionId,
        "otp": otp,
      };

      final response = await ApiService.post(
        ApiEndpoints.registerVerifyOtp, // <--- Add correct endpoint here
        body: payload,
        isFullBody: true,
      );

      setState(() => isLoading = false);

      if (response["status"] == "success" && response['result'] != null) {
        final data = response['result'];

        if (data["status"] == "success") {
          String accessToken = data["message"]; // 🔥 Extract token

          // 🔥 NAVIGATE TO NEXT SCREEN WITH phone + token
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnterNameScreen(
                phoneNumber: widget.phoneNumber,
                accessToken: accessToken,
              ),
            ),
          );
        } else {
          showError("Invalid OTP");
        }
      } else {
        showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showError("Something went wrong");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopVisualSection(height: h * 0.45),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        const Text(
                          "Enter 6-digit code sent to",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "+91 ${widget.phoneNumber}",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        SizedBox(height: 24),

                        // OTP BOXES
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
                                  contentPadding: EdgeInsets.all(8),
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

                        SizedBox(height: 20),

                        // RESEND
                        _secondsRemaining > 0
                            ? Text(
                                "Didn't receive OTP? Resend in $_secondsRemaining s",
                                style: TextStyle(color: Colors.grey),
                              )
                            : GestureDetector(
                                onTap: startTimer,
                                child: Text(
                                  "Resend OTP",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                        SizedBox(height: 30),

                        // VERIFY BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isButtonEnabled ? verifyOtp : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text("Verify"),
                          ),
                        ),

                        SizedBox(height: 16),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhoneVerificationScreen(),
                              ),
                            );
                          },
                          child: Text(
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
              ],
            ),

            // 🔥 LOADING OVERLAY
            if (isLoading)
              Container(
                color: Colors.black45,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
