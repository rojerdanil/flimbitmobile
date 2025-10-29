import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final double padding = media.width * 0.04;
    final double fontSize = media.width * 0.042;
    final double titleSize = media.width * 0.048;
    final double buttonHeight = media.height * 0.065;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: media.height * 0.02,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Notifications",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: titleSize,
                      ),
                    ),
                  ),
                  SizedBox(width: 48), // balance symmetry
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CustomCard(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: "Push Notifications",
                          icon: Icons.notifications_active,
                          color: Colors.amber,
                          value: pushNotifications,
                          onChanged: (val) =>
                              setState(() => pushNotifications = val),
                          fontSize: fontSize,
                        ),
                        _divider(),
                        _buildSwitchTile(
                          title: "System Alerts",
                          icon: Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          value: systemAlerts,
                          onChanged: (val) =>
                              setState(() => systemAlerts = val),
                          fontSize: fontSize,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // UPDATES
                  Text(
                    "UPDATES",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
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
                          fontSize: fontSize,
                        ),
                        _divider(),
                        _buildSwitchTile(
                          title: "Movie Updates",
                          icon: Icons.movie_creation_outlined,
                          color: Colors.blue,
                          value: movieUpdates,
                          onChanged: (val) =>
                              setState(() => movieUpdates = val),
                          fontSize: fontSize,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // PROMOTIONS
                  Text(
                    "PROMOTIONS",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black54,
                      letterSpacing: 0.5,
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
                      fontSize: fontSize,
                    ),
                  ),

                  SizedBox(height: media.height * 0.03),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Settings updated")),
                        );
                      },
                      child: Text(
                        "Update",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize + 2,
                        ),
                      ),
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
    return Divider(color: Colors.grey.shade300, height: 1);
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required Color color,
    required bool value,
    required Function(bool) onChanged,
    required double fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(fontSize: fontSize, color: Colors.black87),
              ),
            ],
          ),
          Switch(value: value, onChanged: onChanged, activeColor: color),
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
