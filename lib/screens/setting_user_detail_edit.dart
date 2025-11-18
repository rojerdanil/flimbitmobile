import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; //

class UserEditScreen extends StatefulWidget {
  const UserEditScreen({super.key});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final ImagePicker _picker = ImagePicker();

  final _emailFormKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController panNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  Map<String, dynamic>? user;
  Map<String, dynamic>? userPanCard;

  bool isEditingPan = false; // Track if user is editing an existing PAN
  final TextEditingController otpController = TextEditingController();
  bool showOtpField = false;
  bool isSendingOtp = false; // Track if OTP is being sent
  File? profileImage; // Already saved profile image from backend
  File? tempProfileImage; // Temporary image selected by user
  Uint8List? tempProfileBytes; // for web image preview

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Select profile image
  // Select profile image
  Future<void> pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 500,
      maxWidth: 500,
      imageQuality: 80,
    );

    if (image != null) {
      if (kIsWeb) {
        tempProfileBytes = await image.readAsBytes(); // Web
      } else {
        tempProfileImage = File(image.path); // Mobile
      }
      setState(() {});
    }
  }

  // Save profile image permanently
  Future<void> saveProfileImage() async {
    if (tempProfileImage == null && tempProfileBytes == null) return;

    try {
      if (kIsWeb && tempProfileBytes != null) {
        // Web upload
        final response = await ApiService.uploadFileBytes(
          ApiEndpoints.uploadProfileImage,
          tempProfileBytes!,
          fileName: "profile_pic.png",
          fieldName: "profilePic",
        );

        if (response?['status'] == 'success') {
          setState(() {
            tempProfileBytes = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile image updated successfully!"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? "Failed to save image"),
            ),
          );
        }
      } else if (!kIsWeb && tempProfileImage != null) {
        // Mobile upload
        final response = await ApiService.uploadFile(
          ApiEndpoints.uploadProfileImage,
          tempProfileImage!,
          fieldName: "profilePic",
        );

        if (response?['status'] == 'success') {
          setState(() {
            profileImage = tempProfileImage;
            tempProfileImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile image updated successfully!"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? "Failed to save image"),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error uploading profile image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading image. Try again.")),
      );
    }
  }

  // Cancel temporary selection
  void cancelProfileImageSelection() {
    setState(() {
      tempProfileImage = null; // mobile
      tempProfileBytes = null; // web
    });
  }

  // 🚀 API call to inactivate PAN
  Future<void> callInactivatePanApi() async {
    try {
      final response = await ApiService.get(
        ApiEndpoints.inactivateUserPan,
        context: context,
        isFullBody: true, // your endpoint
      );

      // Success block
      if (response != null && response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PAN set to inactive. You can now edit."),
          ),
        );
        setState(() {
          panController.clear();
          panNameController.clear();
          dobController.clear();
          isEditingPan = true;
          userPanCard = null;
        });
      } else if (response != null && response['message'] != null) {
        // Backend returned failure message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Unknown error occurred")));
      }
    } catch (e) {
      debugPrint("Error inactivating PAN: $e");

      // Extract and show message from the thrown exception
      final errorMsg = e.toString().replaceAll("Exception:", "").trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg.isNotEmpty ? errorMsg : "Error contacting server",
          ),
        ),
      );
    }
  }

  Future<void> callInactivateEmailApi() async {
    try {
      final response = await ApiService.get(
        ApiEndpoints.inactivateUserEmail,
        context: context,
        isFullBody: true,
      );

      if (response != null && response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email set to inactive. You can now edit."),
          ),
        );

        setState(() {
          emailController.clear();
          user?['email'] = null;
          user?['emailVerified'] = false;
        });
      } else if (response != null && response['message'] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Unknown error occurred")));
      }
    } catch (e) {
      debugPrint("Error inactivating email: $e");
      final msg = e.toString().replaceAll("Exception:", "").trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : "Error contacting server"),
        ),
      );
    }
  }

  void confirmEditEmail() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Existing Email?"),
        content: const Text(
          "If you change your email, your current verified email will be deactivated until reverified.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showEmailInactivationLoading();
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  void showEmailInactivationLoading() {
    bool cancelled = false;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () async {
          if (!cancelled) {
            Navigator.pop(context);
            await callInactivateEmailApi();
          }
        });

        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text("Deactivating your email..."),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Action cancelled")),
                    );
                  },
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🚀 Verify PAN via API
  Future<void> verifyAndSavePAN() async {
    final pan = panController.text.trim().toUpperCase();
    final name = panNameController.text.trim();
    final dob = dobController.text.trim();

    // ✅ Validate PAN number format (e.g., ABCDE1234F)
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
    if (!panRegex.hasMatch(pan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid 10-character PAN (e.g., ABCDE1234F)"),
        ),
      );
      return;
    }

    // ✅ Validate name
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your name as per PAN")),
      );
      return;
    }

    // ✅ Validate DOB (DD/MM/YYYY)
    final dobRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dobRegex.hasMatch(dob)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid DOB in DD/MM/YYYY format")),
      );
      return;
    }

    // ✅ Create request body
    final requestBody = {
      "panNumber": pan,
      "nameAsPerPan": name,
      "dateOfBirth": dob,
    };

    // 🌀 Show loading indicator
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.post(
        ApiEndpoints.verifyAndSavePan,
        body: requestBody,
      );

      Navigator.pop(context); // close loading dialog

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PAN verified and saved successfully!")),
        );

        setState(() {
          isEditingPan = false;
          userPanCard = {
            "panId": pan,
            "name": name,
            "dob": dob,
            "status": "PENDING",
            "vcVerified": false,
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Failed to verify PAN"),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint("Error verifying PAN: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
  }

  // ✅ Format date to DD/MM/YYYY
  String formatDob(String dobString) {
    try {
      if (dobString.contains('-')) {
        final parts = dobString.split('-');
        if (parts.length == 3) {
          return "${parts[2]}/${parts[1]}/${parts[0]}";
        }
      }
      return dobString;
    } catch (_) {
      return dobString;
    }
  }

  // Fetch user data from API
  Future<void> fetchUserData() async {
    try {
      final response = await ApiService.get(ApiEndpoints.userProfileData);
      if (response != null && response['user'] != null) {
        setState(() {
          user = response['user'];
          userPanCard = response['userPanCard'];

          emailController.text = user?['email'] ?? '';
          panController.text = userPanCard?['panId'] ?? '';
          panNameController.text = (userPanCard?['name'] ?? '').trim();

          final rawDob = userPanCard?['dob'] ?? '';
          dobController.text = formatDob(rawDob);
          isEditingPan =
              !(userPanCard != null &&
                  (userPanCard?['panId']?.isNotEmpty ?? false));
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // Save email
  Future<void> saveEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your email")));
      return;
    }

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email")),
      );
      return;
    }

    setState(() {
      isSendingOtp = true; // disable button
    });

    try {
      final response = await ApiService.post(
        ApiEndpoints.sendEmailOtp,
        body: {"email": email},
      );

      if (response != null && response['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("OTP sent to your email")));

        setState(() {
          showOtpField = true; // show OTP input
          user?['email'] = email;
          user?['emailVerified'] = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to send OTP")),
        );
      }
    } catch (e) {
      debugPrint("Error sending OTP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error sending OTP. Try again.")),
      );
    } finally {
      setState(() {
        isSendingOtp = false; // re-enable button if needed
      });
    }
  }

  // Verify and save PAN
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter the OTP")));
      return;
    }

    try {
      final response = await ApiService.get(
        "${ApiEndpoints.verifyEmailOtp}$otp", // correct string interpolation
        context: context,
        isFullBody: true,
      );

      if (response != null && response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email verified successfully!")),
        );

        setState(() {
          user?['emailVerified'] = true;
          showOtpField = false;
          otpController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Invalid OTP")),
        );
      }
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error verifying OTP. Try again.")),
      );
    }
  }

  // Confirm before editing existing PAN
  void confirmEditPan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Existing PAN?"),
        content: const Text(
          "If you edit your existing PAN details, your current verified PAN will become inactive until re-verified.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ❌ just close the dialog
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close this alert
              showPanInactivationLoading(); // ✅ show loading popup
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPan =
        userPanCard != null && (userPanCard?['panId']?.isNotEmpty ?? false);

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
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: kIsWeb
                            ? (tempProfileBytes != null
                                  ? MemoryImage(tempProfileBytes!)
                                        as ImageProvider
                                  : (user?['profilePicUrl'] != null &&
                                        user!['profilePicUrl']
                                            .toString()
                                            .isNotEmpty)
                                  ? NetworkImage(user!['profilePicUrl'])
                                        as ImageProvider
                                  : const AssetImage('assets/default_user.png'))
                            : (tempProfileImage != null
                                  ? FileImage(tempProfileImage!)
                                        as ImageProvider
                                  : (profileImage != null
                                        ? FileImage(profileImage!)
                                              as ImageProvider
                                        : (user?['profilePicUrl'] != null &&
                                              user!['profilePicUrl']
                                                  .toString()
                                                  .isNotEmpty)
                                        ? NetworkImage(user!['profilePicUrl'])
                                              as ImageProvider
                                        : const AssetImage(
                                            'assets/default_user.png',
                                          ))),
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

                  // Show Save/Cancel buttons only when tempProfileImage exists
                  // Show Save/Cancel buttons only when temp image exists (web or mobile)
                  if ((kIsWeb && tempProfileBytes != null) ||
                      (!kIsWeb && tempProfileImage != null)) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: saveProfileImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow.shade700,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Save",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: cancelProfileImageSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Email
            // ---------------- EMAIL SECTION ----------------
            // ---------------- EMAIL SECTION ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (user?['email'] != null &&
                        user!['email'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: user!['emailVerified'] == true
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user!['emailVerified'] == true
                              ? "VERIFIED"
                              : "PENDING",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: user!['emailVerified'] == true
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
                if (user?['email'] != null &&
                    user!['email'].toString().isNotEmpty)
                  TextButton(
                    onPressed: confirmEditEmail,
                    child: const Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              enabled: !(user?['emailVerified'] ?? false),
              decoration: InputDecoration(
                hintText: "Enter your email",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (showOtpField && !(user?['emailVerified'] ?? false))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Enter OTP",
                      hintText: "OTP sent to your email",
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
                    onPressed: verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "Verify OTP",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),
            if (!(user?['emailVerified'] == true || showOtpField))
              ElevatedButton(
                onPressed: isSendingOtp ? null : saveEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSendingOtp
                      ? Colors.grey
                      : Colors.yellow.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Send OTP",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // PAN Card Section Header with Edit button
            // PAN Card Section Header with Status + Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      "PAN Card",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ✅ PAN Status Badge
                    if (userPanCard != null && userPanCard?['status'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: userPanCard!['status'] == 'VERIFIED'
                              ? Colors.green.shade100
                              : userPanCard!['status'] == 'PENDING'
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userPanCard!['status'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: userPanCard!['status'] == 'VERIFIED'
                                ? Colors.green.shade800
                                : userPanCard!['status'] == 'PENDING'
                                ? Colors.orange.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(width: 6),

                    // 🎥 VC Verified Badge
                    if (userPanCard != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: userPanCard!['vcVerified'] == true
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              userPanCard!['vcVerified'] == true
                                  ? Icons.verified
                                  : Icons.videocam_off,
                              size: 14,
                              color: userPanCard!['vcVerified'] == true
                                  ? Colors.green.shade800
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userPanCard!['vcVerified'] == true
                                  ? "VC Verified"
                                  : "VC Not Done",
                              style: TextStyle(
                                fontSize: 12,
                                color: userPanCard!['vcVerified'] == true
                                    ? Colors.green.shade800
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // ✏️ Edit Button
                if (hasPan && !isEditingPan)
                  TextButton(
                    onPressed: confirmEditPan,
                    child: const Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // PAN Number
            TextField(
              controller: panController,
              enabled: !hasPan || isEditingPan,
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

            // Editable Name
            TextField(
              controller: panNameController,
              enabled: !hasPan || isEditingPan,
              decoration: InputDecoration(
                labelText: "Name as per PAN",
                hintText: "Enter your name as per PAN",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Editable DOB
            TextField(
              controller: dobController,
              enabled: !hasPan || isEditingPan,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: "Date of Birth (DD/MM/YYYY)",
                hintText: "DD/MM/YYYY",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Verify Button
            // Verify Button
            if (isEditingPan) // <-- hide button when PAN edit is enabled
              ElevatedButton(
                onPressed: verifyAndSavePAN,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    hasPan ? "PAN Verified" : "Verify & Save PAN",
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 🌀 Show Loading Popup before calling API
  void showPanInactivationLoading() {
    bool isCancelled = false;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        // Start a delayed task to call API after few seconds
        Future.delayed(const Duration(seconds: 3), () async {
          if (!isCancelled) {
            Navigator.pop(context); // close loading popup
            await callInactivatePanApi(); // call API
          }
        });

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    "Deactivating your current PAN...",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      isCancelled = true;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Action cancelled")),
                      );
                    },
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
