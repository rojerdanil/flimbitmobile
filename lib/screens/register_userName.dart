import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/register_language.dart';
import '../MainScreen/topVisualSection.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class EnterNameScreen extends StatefulWidget {
  final String phoneNumber;
  final String accessToken;
  const EnterNameScreen({required this.phoneNumber, required this.accessToken});

  @override
  State<EnterNameScreen> createState() => _EnterNameScreenState();
}

class _EnterNameScreenState extends State<EnterNameScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool isButtonEnabled = false;

  List<dynamic> languages = []; // from API
  dynamic selectedLanguage; // full object

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_checkFields);
    _lastNameController.addListener(_checkFields);

    _fetchLanguages();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // 🔥 CALL BACKEND FOR LANGUAGES
  Future<void> _fetchLanguages() async {
    setState(() => isLoading = true);

    final response = await ApiService.get(
      ApiEndpoints.registerAllLanguage, // <-- replace with correct endpoint
      isFullBody: true,
    );

    setState(() => isLoading = false);

    if (response["status"] == "success" && response["result"] != null) {
      setState(() {
        languages = response["result"];
      });
    }
  }

  // 💡 VALIDATION LOGIC
  void _checkFields() {
    setState(() {
      final f = _firstNameController.text.trim();
      final l = _lastNameController.text.trim();

      isButtonEnabled =
          f.length >= 3 && l.length >= 3 && selectedLanguage != null;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  bool _validateFields() {
    String f = _firstNameController.text.trim();
    String l = _lastNameController.text.trim();

    if (f.length < 3) {
      _showError("First name must be at least 3 characters");
      return false;
    }
    if (l.length < 3) {
      _showError("Last name must be at least 3 characters");
      return false;
    }
    if (selectedLanguage == null) {
      _showError("Please select a language");
      return false;
    }

    return true;
  }

  void _onNext() {
    if (!_validateFields()) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LanguageSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopVisualSection(height: h * 0.45),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Tell us your name",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // FIRST NAME FIELD
                          TextField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              hintText: "First name",
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
                          if (_firstNameController.text.trim().length < 3 &&
                              _firstNameController.text.trim().isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                "First name must be at least 3 characters",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // LAST NAME FIELD
                          TextField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              hintText: "Last name",
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
                          if (_lastNameController.text.trim().length < 3 &&
                              _lastNameController.text.trim().isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                "Last name must be at least 3 characters",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // LANGUAGE TITLE
                          const Text(
                            "Please select preferred movie language",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // LANGUAGE DROPDOWN
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButton<dynamic>(
                              value: selectedLanguage,
                              isExpanded: true,
                              underline: SizedBox(),
                              hint: const Text("Select language"),
                              items: languages.map((lang) {
                                return DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang["name"]),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedLanguage = value;
                                });
                                _checkFields();
                              },
                            ),
                          ),

                          const SizedBox(height: 30),

                          // NEXT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isButtonEnabled ? _onNext : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text("Next"),
                            ),
                          ),

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
