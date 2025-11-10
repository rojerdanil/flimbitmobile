import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> userNotifications = [];
  List<Map<String, dynamic>> announcementNotifications = [];
  bool isLoadingUser = true;
  bool isLoadingAnnouncement = false;
  bool announcementLoaded = false;
  int announcementOffset = 0;
  final int announcementLimit = 3;
  bool hasMoreAnnouncements = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    _fetchUserNotifications();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !announcementLoaded) {
      _fetchAnnouncementNotifications();
    }
    setState(() {});
  }

  // ====================== Fetch Notifications ======================
  Future<void> _fetchUserNotifications() async {
    setState(() => isLoadingUser = true);
    try {
      final result = await ApiService.get(ApiEndpoints.userSpecificRemainder);
      if (result is List && result.isNotEmpty) {
        userNotifications = result.map<Map<String, dynamic>>((e) {
          return {
            'id': e['id'],
            'title': e['title'] ?? '',
            'description': e['message'] ?? '',
            'time': DateTime.parse(e['timestamp']),
            'isNew': e['read_at'] == null, // ✅ unread if no timestamp
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching user notifications: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user notifications')),
      );
    }
    setState(() => isLoadingUser = false);
  }

  Future<void> _fetchAnnouncementNotifications({bool loadMore = false}) async {
    if (!hasMoreAnnouncements && loadMore) return;

    setState(() => isLoadingAnnouncement = true);

    try {
      final Map<String, dynamic> payload = {
        "offset": announcementOffset.toString(),
        "limit": announcementLimit.toString(),
      };
      final result = await ApiService.post(
        ApiEndpoints.userMoiveRemainder,
        body: payload,
      );

      if (result is List && result.isNotEmpty) {
        List<Map<String, dynamic>> newAnnouncements = result
            .map<Map<String, dynamic>>((e) {
              return {
                'id': e['id'],
                'title': e['title'] ?? '',
                'description': e['message'] ?? '',
                'time': DateTime.parse(e['timestamp']),
                'isNew': e['new'] ?? false,
              };
            })
            .toList();

        setState(() {
          if (loadMore) {
            announcementNotifications.addAll(newAnnouncements);
          } else {
            announcementNotifications = newAnnouncements;
          }

          announcementOffset += newAnnouncements.length;
          hasMoreAnnouncements = newAnnouncements.length == announcementLimit;
        });
      } else {
        setState(() => hasMoreAnnouncements = false);
      }

      announcementLoaded = true;
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load announcements')),
      );
    }

    setState(() => isLoadingAnnouncement = false);
  }

  // ====================== Mark as Read ======================
  Future<void> _markNotificationRead(
    Map<String, dynamic> notification,
    bool isUser,
  ) async {
    if (notification['isNew'] != true) return; // already read
    try {
      final apiEndpoint = isUser
          ? ApiEndpoints.markUserNotificationRead
          : ApiEndpoints.markAnnouncementRead;
      await ApiService.post(
        apiEndpoint,
        body: {
          "notificationIds": [notification['id']],
        },
      );
      setState(() {
        notification['isNew'] = false;
      });
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
  }

  Future<void> _markAllRead() async {
    try {
      // Determine which tab is active
      final bool isUserTab = _tabController.index == 0;

      // Collect all unread IDs from the active tab
      final ids = (isUserTab ? userNotifications : announcementNotifications)
          .map((n) => n['id'])
          .toList();

      // Skip API call if there are no unread notifications
      if (ids.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications already read')),
        );
        return;
      }

      // Choose API endpoint based on active tab
      final apiEndpoint = isUserTab
          ? ApiEndpoints.markUserNotificationRead
          : ApiEndpoints.markAnnouncementRead;

      // Call API to mark all as read
      await ApiService.post(apiEndpoint, body: {"notificationIds": ids});

      // Update local state instantly
      setState(() {
        if (isUserTab) {
          for (var n in userNotifications) n['isNew'] = false;
        } else {
          for (var n in announcementNotifications) n['isNew'] = false;
        }
      });
    } catch (e) {
      debugPrint("Error marking all read: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark all as read')),
      );
    }
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: AppTheme.primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _markAllRead,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor:
                Colors.white, // underline indicator instead of background
            labelColor: Colors.white, // active tab text color
            unselectedLabelColor: Colors.black54, // inactive tab text color
            indicatorWeight: 3, // underline thickness
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'User Specific'),
              Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            isLoadingUser
                ? const Center(child: CircularProgressIndicator())
                : _buildNotificationList(
                    userNotifications,
                    Colors.blue[50]!,
                    true,
                  ),
            isLoadingAnnouncement
                ? const Center(child: CircularProgressIndicator())
                : _buildNotificationList(
                    announcementNotifications,
                    Colors.orange[50]!,
                    false,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    List<Map<String, dynamic>> notifications,
    Color cardColor,
    bool isUser,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              "No notifications yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (isUser) {
          await _fetchUserNotifications();
        } else {
          announcementOffset = 0;
          hasMoreAnnouncements = true;
          await _fetchAnnouncementNotifications();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Dismissible(
            key: Key(notif['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() {
                notifications.removeAt(index);
              });
            },
            child: Card(
              color: cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: notif['isNew'] == true
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                title: Text(
                  notif['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif['description'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo(notif['time']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => _markNotificationRead(notif, isUser),
                      child: const Text(
                        "Mark as Read",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                onTap: () => _markNotificationRead(notif, isUser),
              ),
            ),
          );
        },
      ),
    );
  }
}
