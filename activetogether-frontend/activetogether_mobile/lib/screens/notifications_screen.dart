import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<NotificationProvider>().refreshList();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Notifikacije'),
        backgroundColor: const Color(0xFFF4F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (provider.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () =>
                  context.read<NotificationProvider>().markAllAsRead(),
              child: const Text('Označi sve'),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.notifications.isEmpty
            ? const Center(child: Text('Nemaš notifikacija.'))
            : RefreshIndicator(
                onRefresh: () =>
                    context.read<NotificationProvider>().refreshList(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final AppNotification n = provider.notifications[index];
                    final dateLabel = DateFormat(
                      'dd.MM.yyyy. HH:mm',
                    ).format(n.createdAt);

                    return Card(
                      color: n.isRead ? Colors.white : const Color(0xFFE8EEFB),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(
                          n.isRead
                              ? Icons.notifications_none
                              : Icons.notifications,
                          color: n.isRead
                              ? Colors.grey
                              : const Color(0xFF1E3A8A),
                        ),
                        title: Text(
                          n.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.text),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!n.isRead) {
                            context.read<NotificationProvider>().markAsRead(
                              n.id,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
