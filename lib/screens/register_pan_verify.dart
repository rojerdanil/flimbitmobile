import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/register_terms_and_conditrion.dart';
import '../MainScreen/topVisualSection.dart'; // <-- Import TopVisualSection

class PanVerificationScreen extends StatefulWidget {
  const PanVerificationScreen({super.key});

  @override
  State<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends State<PanVerificationScreen> {
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool isButtonEnabled = false;

  void _checkFields() {
    setState(() {
      isButtonEnabled =
          _panController.text.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _dobController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _panController.addListener(_checkFields);
    _nameController.addListener(_checkFields);
    _dobController.addListener(_checkFields);
  }

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onVerify() {
    String pan = _panController.text.trim();
    String name = _nameController.text.trim();
    String dob = _dobController.text.trim();

    print("PAN: $pan, Name: $name, DOB: $dob");

    // TODO: Navigate to next screen
  }

  void _onSkip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TermsConditionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ------------------ TOP VISUAL SECTION ------------------
            TopVisualSection(height: h * 0.45),

            // ------------------ INPUT SECTION ------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          "Unverified",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "₹50,000/year limit. PAN verify now, Video KYC later for unlimited.",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // PAN Number
                    TextField(
                      controller: _panController,
                      decoration: InputDecoration(
                        hintText: "PAN Number",
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name as per PAN
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Name as per PAN Card",
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    TextField(
                      controller: _dobController,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        hintText: "Date of Birth: DD/MM/YYYY",
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
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

                    // Skip button
                    TextButton(onPressed: _onSkip, child: const Text("Skip")),
                    const SizedBox(height: 20),

                    // Security info
                    const Text(
                      "Your details are secure and used only as per government KYC guidelines.",
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
