import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserEditScreen extends StatefulWidget {
  const UserEditScreen({super.key});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  File? profileImage;
  final ImagePicker _picker = ImagePicker();

  final _emailFormKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController panController = TextEditingController();
  final TextEditingController panNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  // Select profile image
  Future<void> pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile picture updated")));
    }
  }

  // Save email with validation
  void saveEmail() {
    if (_emailFormKey.currentState!.validate()) {
      final email = emailController.text.trim();
      // Call API to save email here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email $email saved successfully")),
      );
    }
  }

  // Verify and save PAN
  void verifyAndSavePAN() {
    final pan = panController.text.trim().toUpperCase();
    if (pan.length != 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid 10-digit PAN")));
      return;
    }

    // Call PAN verification API here
    // For demo, populate dummy name and DOB
    setState(() {
      panNameController.text = "John Doe";
      dobController.text = "01-Jan-1990";
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("PAN verified and saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.yellow.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage != null
                        ? FileImage(profileImage!)
                        : const AssetImage('assets/poster1.jpg')
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email Section with Validation
            const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Form(
              key: _emailFormKey,
              child: TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Email is required";
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return "Enter a valid email address";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: saveEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  "Save Email",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // PAN Section
            const Text(
              "PAN Card",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: panController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "PAN Number",
                hintText: "Enter your PAN",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: panNameController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Name as per PAN",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dobController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Date of Birth",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: verifyAndSavePAN,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  "Verify & Save PAN",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
