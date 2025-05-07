import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Builder(
        builder: (context) {
          final notifications = []; // Replace with actual notifications
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when they arrive',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return const ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Notification Title'),
                  subtitle: Text('Notification details go here'),
                  trailing: Text('2h ago'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
