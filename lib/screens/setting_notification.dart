import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool pushNotifications = true;
  bool transactionUpdates = true;
  bool movieUpdates = true;
  bool offersRewards = true;
  bool systemAlerts = true;

  Future<void> fetchUserSetting() async {
    final response = await ApiService.get(ApiEndpoints.user_setting_read);
    if (response != null) {
      final data = Map<String, dynamic>.from(response);
      setState(() {
        pushNotifications = data['pushNotifications'] ?? true;
        transactionUpdates = data['transactionUpdates'] ?? true;
        movieUpdates = data['movieUpdates'] ?? true;
        offersRewards = data['offersRewards'] ?? true;
        systemAlerts = data['systemAlerts'] ?? true;
      });
    }
  }

  Future<void> updateUserSetting() async {
    final data = {
      "pushNotifications": pushNotifications,
      "transactionUpdates": transactionUpdates,
      "movieUpdates": movieUpdates,
      "offersRewards": offersRewards,
      "systemAlerts": systemAlerts,
    };

    final response = await ApiService.post(
      ApiEndpoints.user_setting_update,
      body: data,
    );

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update settings")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserSetting();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final double padding = media.width * 0.04;
    final double buttonHeight = media.height * 0.065;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: media.height * 0.02,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                boxShadow: [
                  BoxShadow(color: AppTheme.shadowColor, blurRadius: 4),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppTheme.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Notifications",
                      textAlign: TextAlign.center,
                      style: AppTheme.headline1,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: 16,
                ),
                children: [
                  // GENERAL
                  Text(
                    "GENERAL",
                    style: AppTheme.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CustomCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: "Push Notifications",
                          icon: Icons.notifications_active,
                          color: AppTheme.primaryColor,
                          value: pushNotifications,
                          onChanged: (val) =>
                              setState(() => pushNotifications = val),
                        ),
                        _divider(),
                        _buildSwitchTile(
                          title: "System Alerts",
                          icon: Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          value: systemAlerts,
                          onChanged: (val) =>
                              setState(() => systemAlerts = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // UPDATES
                  const SizedBox(height: 8),
                  _CustomCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: "Transaction Updates",
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                          value: transactionUpdates,
                          onChanged: (val) =>
                              setState(() => transactionUpdates = val),
                        ),
                        _divider(),
                        _buildSwitchTile(
                          title: "Movie Updates",
                          icon: Icons.movie_creation_outlined,
                          color: Colors.blue,
                          value: movieUpdates,
                          onChanged: (val) =>
                              setState(() => movieUpdates = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // PROMOTIONS
                  Text(
                    "PROMOTIONS",
                    style: AppTheme.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CustomCard(
                    child: _buildSwitchTile(
                      title: "Offers & Rewards",
                      icon: Icons.card_giftcard,
                      color: Colors.purple,
                      value: offersRewards,
                      onChanged: (val) => setState(() => offersRewards = val),
                    ),
                  ),

                  SizedBox(height: media.height * 0.03),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.secondaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      onPressed: updateUserSetting,
                      child: Text("Update", style: AppTheme.headline2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(color: AppTheme.shadowColor, height: 1);
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Animated icon background
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: value
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Text(title, style: AppTheme.headline2),
            ],
          ),
          // Switch always visible
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.4),
            inactiveThumbColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _CustomCard extends StatelessWidget {
  final Widget child;

  const _CustomCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}
