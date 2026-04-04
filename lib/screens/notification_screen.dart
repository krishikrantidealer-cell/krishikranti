import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Notifications'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.bell_fill,
              size: 100,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text('Stay Updated', style: Theme.of(context).textTheme.headlineMedium),
            const Text('No new notifications at this time.'),
          ],
        ),
      ),
    );
  }
}
