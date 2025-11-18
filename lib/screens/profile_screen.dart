import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import 'Change_Password_Screen.dart';
import 'setting_notification.dart';
import 'setting_wallet.dart';
import 'setting_user_detail_edit.dart';
import '../screens/my_rewards_screen.dart';
import '../screens/user_share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/PhoneVerificationScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  String walletBalance = "0.00";
  Map<String, dynamic>? investment;
  bool isLoading = true;
  Map<String, dynamic>? userPanCard;
  Map<String, String>? companyContact;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchCompanyContact() async {
    try {
      final response = await ApiService.get(ApiEndpoints.companyContact);
      if (response != null) {
        setState(() {
          companyContact = {
            "email": response['companyEmail'] ?? "",
            "phone": response['companyPhoneNumber'] ?? "",
          };
        });
      }
    } catch (e) {
      debugPrint("Error fetching company contact: $e");
    }
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchUserData(),
      fetchWalletBalance(),
      fetchInvestmentSummary(),
      fetchCompanyContact(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> fetchUserData() async {
    try {
      final response = await ApiService.get(ApiEndpoints.userProfileData);
      if (response != null) {
        setState(() {
          user = response['user'];
          userPanCard = response['userPanCard']; // new
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      final response = await ApiService.get(ApiEndpoints.userWalletBalance);
      if (response != null) {
        setState(() {
          walletBalance = response['value'] ?? "0.00";
        });
      }
    } catch (e) {
      debugPrint("Error fetching wallet balance: $e");
    }
  }

  Future<void> fetchInvestmentSummary() async {
    try {
      final response = await ApiService.get(ApiEndpoints.userInvestmentSummary);
      if (response != null) {
        setState(() {
          investment = response;
        });
      }
    } catch (e) {
      debugPrint("Error fetching investment summary: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserEditScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("Edit"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber[800],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),

                    // Profile Info
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(
                              user?['profilePicUrl'] ?? 'assets/poster1.jpg',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${user?['firstName'] ?? ""} ${user?['lastName'] ?? ""}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user?['phoneNumber'] ?? ""} | ${user?['email']?.isNotEmpty == true ? user!['email'] : "Email Not Verified"}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: user?['email']?.isNotEmpty == true
                                  ? Colors.black54
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 💡 PAN Limit Hint (Always show)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                  height: 1.3,
                                                ),
                                                children: [
                                                  if (userPanCard != null &&
                                                      userPanCard?['vcVerified'] ==
                                                          true) ...[
                                                    const TextSpan(
                                                      text:
                                                          "✅ PAN Verified: You can invest up to ",
                                                    ),
                                                    TextSpan(
                                                      text: "Unlimited amount",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    const TextSpan(text: "."),
                                                  ] else ...[
                                                    const TextSpan(
                                                      text:
                                                          "⚠️ PAN Not Verified: Investment limited to ",
                                                    ),
                                                    TextSpan(
                                                      text: "₹50,000",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    const TextSpan(text: ". "),
                                                    WidgetSpan(
                                                      alignment:
                                                          PlaceholderAlignment
                                                              .middle,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const UserEditScreen(),
                                                            ),
                                                          );
                                                        },
                                                        child: const Text(
                                                          "Click to add / verify PAN",
                                                          style: TextStyle(
                                                            color: Colors.blue,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // 🧾 PAN Details — only if available
                                if (userPanCard != null) ...[
                                  Text(
                                    "PAN ID: ${userPanCard?['panId'] ?? '-'}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      // PAN Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (userPanCard?['status'] ==
                                                  'approved')
                                              ? Colors.green[100]
                                              : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          userPanCard?['status']
                                                  ?.toUpperCase() ??
                                              "UNKNOWN",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                (userPanCard?['status'] ==
                                                    'approved')
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // VC Verified badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (userPanCard?['vcVerified'] ==
                                                  true)
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          (userPanCard?['vcVerified'] == true)
                                              ? "VC VERIFIED"
                                              : "VC NOT VERIFIED",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                (userPanCard?['vcVerified'] ==
                                                    true)
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Wallet Balance
                    _CustomCard(
                      child: Column(
                        children: [
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹$walletBalance',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const WalletScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text('Add Money'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const WalletScreen(
                                              activeTab: "withdraw",
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade100,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text('Withdraw'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Investment Summary
                    _CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Investment Summary",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Total Invested',
                            value:
                                '₹ ${investment?['totalInvested']?.toStringAsFixed(2) ?? "0.00"}',
                          ),
                          _SummaryRow(
                            label: 'Total Returns',
                            value:
                                '₹ ${investment?['totalReturns']?.toStringAsFixed(2) ?? "0.00"}',
                          ),
                          _SummaryRow(
                            label: 'Projects Invested',
                            value: '${investment?['projectsInvest'] ?? "0"}',
                          ),
                          _SummaryRow(
                            label: 'Ongoing Projects',
                            value: '${investment?['ongoingProjects'] ?? "0"}',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Links
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quick Links",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            QuickLinkButton(
                              label: "My Investments",
                              icon: Icons.movie,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserShareScreen(showAppBar: true),
                                  ),
                                );
                              },
                            ),
                            QuickLinkButton(
                              label: "My Rewards",
                              icon: Icons.card_giftcard,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MyRewardsScreen(),
                                  ),
                                );
                              },
                            ),

                            // ❌ Do NOT add const here (because of onTap)
                            QuickLinkButton(
                              label: "Wallet Transaction",
                              icon: Icons.account_balance_wallet,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WalletScreen(activeTab: "transactions"),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Help Center
                    // Help Center
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Help Center",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "If you need any assistance, feel free to reach us:",
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Phone: ${companyContact?['phone'] ?? '+91 123 456 7890'}",
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Email: ${companyContact?['email'] ?? 'support@filmBit.com'}",
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Settings
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Settings",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsTile(
                          icon: Icons.lock,
                          title: "Change Password",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.notifications,
                          title: "Notifications",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.logout,
                          title: "Logout",
                          onTap: () {
                            showLogoutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Logout Dialog
void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Logout"),
      content: const Text("Are you sure you want to logout?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(); // close dialog
            await performLogout(context); // call backend and clear prefs
          },
          child: const Text("Logout", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

Future<void> performLogout(BuildContext context) async {
  try {
    // Call logout API
    final response = await ApiService.get(ApiEndpoints.logOut);

    if (response != null) {
      // Clear all saved preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.remove("auth_token");

      // clears all keys including auth_token, phoneNumber, deviceId, deviceType

      // Show confirmation
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logged out successfully")));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneVerificationScreen(),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logout failed, try again")));
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error during logout: $e")));
  }
}

// Custom Card
class _CustomCard extends StatelessWidget {
  final Widget child;
  const _CustomCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

// Summary Row
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Quick Link Button
class QuickLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;
  final double spacing;
  final TextStyle? textStyle;

  const QuickLinkButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.iconSize = 28,
    this.spacing = 6,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.yellow.shade700, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: Colors.yellow.shade800),
            SizedBox(height: spacing),
            Text(
              label,
              style:
                  textStyle ??
                  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow.shade800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Settings Tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.amber[800]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.black54,
      ),
      onTap: onTap,
    );
  }
}
