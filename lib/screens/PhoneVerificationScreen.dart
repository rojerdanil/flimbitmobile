import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- needed for input formatter
import '../theme/AppTheme.dart';
import '../utlity/ProgressLoader.dart';
import '../screens/verify_otp_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController phoneController = TextEditingController();
  String errorMessage = ''; // Message shown above text field

  // Simulated "already verified" numbers (in real app, check backend)
  final List<String> verifiedNumbers = ['9876543210', '9123456789'];

  void verifyPhone() {
    // ProgressLoader.show(context, message: "Verifying...");
    //    ProgressLoader.hide(context);

    String phone = phoneController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyOtpScreen(phoneNumber: phone),
      ),
    );

    // Validate: numeric and 10 digits
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() {
        errorMessage = 'Please enter a valid 10-digit phone number';
      });
      return;
    }

    // Check if number is already verified on another device
    if (verifiedNumbers.contains(phone)) {
      setState(() {
        errorMessage = 'Phone number is already verified with another device';
      });
      return;
    }

    // Else: proceed to send OTP
    setState(() {
      errorMessage = ''; // clear error
    });

    print('OTP sent to: $phone');
    // TODO: Trigger backend OTP logic
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.4;
    double textFieldWidth = screenWidth * 0.8;
    double buttonWidth = screenWidth * 0.8;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Company Logo
              Image.asset(
                'assets/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20),

              // Title / Instructions
              Text(
                'Enter your phone number',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

              // Error Message (above TextField)
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              // Phone number input
              SizedBox(
                width: textFieldWidth,
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // only numbers
                    LengthLimitingTextInputFormatter(10), // max 10 digits
                  ],
                  decoration: InputDecoration(
                    counterText: '', // hide counter
                    hintText: 'e.g. 9876543210',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: (value) {
                    if (errorMessage.isNotEmpty) {
                      setState(() {
                        errorMessage = ''; // clear error when typing
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: 24),

              // Verify Button
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  onPressed: verifyPhone,
                  child: Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Always visible info text
              Text(
                'By continuing you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
