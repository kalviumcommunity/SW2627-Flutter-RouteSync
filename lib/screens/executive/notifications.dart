import 'package:flutter/material.dart';
import 'executive_repository.dart';

class NotificationsScreen extends StatelessWidget { final ExecutiveSnapshot? snapshot; const NotificationsScreen({super.key, required this.snapshot}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifications')), body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(snapshot?.notificationsSupported == true ? 'No new notifications.' : 'Notifications are not available until the notification service is connected.', textAlign: TextAlign.center)))); }