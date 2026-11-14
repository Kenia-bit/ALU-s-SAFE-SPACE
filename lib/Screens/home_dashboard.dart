import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_incident_reporting_app/Screens/profile_screen.dart';
import 'package:campus_incident_reporting_app/Screens/report_form_screen.dart';

class HomeDashboard extends StatelessWidget {
  final String userRole;

  const HomeDashboard({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName?.trim();
    final emailName = user?.email?.split('@').first.replaceAll('.', ' ');
    final name = fullName?.isNotEmpty == true
        ? fullName!
        : (emailName?.isNotEmpty == true ? emailName! : 'there');
    final firstName = name.split(RegExp(r'\s+')).first;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final isStaff = userRole == 'staff';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reports = FirebaseFirestore.instance.collection('reports');
    final reportStream = isStaff
        ? reports.snapshots()
        : user == null
        ? null
        : reports.where('reporterUid', isEqualTo: user.uid).snapshots();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $firstName',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isStaff
                            ? 'Supporting a safer campus'
                            : 'Your campus, your community',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Campus updates',
                  onPressed: () =>
                      _showNotifications(context, reportStream, isStaff),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileScreen(userRole: userRole),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _CampusCard(isDark: isDark),
            const SizedBox(height: 28),
            Text(
              isStaff ? 'Staff tools' : 'Quick action',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              isStaff: isStaff,
              onPressed: isStaff
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportFormScreen(),
                      ),
                    ),
            ),
            const SizedBox(height: 28),
            Text(
              isStaff ? 'New reports' : 'Report status updates',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _NotificationsList(
              stream: reportStream,
              isStaff: isStaff,
              showEmptyMessage: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(
    BuildContext context,
    Stream<QuerySnapshot<Map<String, dynamic>>>? stream,
    bool isStaff,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _NotificationsList(
                stream: stream,
                isStaff: isStaff,
                showEmptyMessage: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/alu_home_card.jpeg', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: isDark ? 0.82 : 0.72),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALU Kigali Campus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Bumbogo Innovation City, Rwanda',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.isStaff, required this.onPressed});

  final bool isStaff;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  child: Icon(
                    isStaff
                        ? Icons.rule_folder_outlined
                        : Icons.add_a_photo_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isStaff ? 'Review campus reports' : 'Report an issue',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isStaff
                  ? 'Open the reports tab to review and follow up on concerns.'
                  : 'Tell us what needs attention. Add a photo to help explain the issue.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!isStaff) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create a report'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeNotification {
  const _HomeNotification({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.stream,
    required this.isStaff,
    this.showEmptyMessage = false,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>>? stream;
  final bool isStaff;
  final bool showEmptyMessage;

  @override
  Widget build(BuildContext context) {
    final reportStream = stream;
    if (reportStream == null) {
      return const Text('Sign in to see report notifications.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reportStream.timeout(
        const Duration(seconds: 10),
        onTimeout: (sink) => sink.addError(
          TimeoutException(
            'Notifications did not load. Check your connection and Firestore access.',
          ),
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final message = snapshot.error is TimeoutException
              ? 'Notifications are taking too long to load. Check your internet connection and Firestore rules.'
              : 'Could not load notifications: ${snapshot.error}';
          return Text(message);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data?.docs.toList() ?? [];
        reports.removeWhere((report) {
          final data = report.data();
          return !isStaff && data['statusUpdatedAt'] is! Timestamp;
        });
        reports.sort((first, second) {
          final firstDate = _notificationDate(first.data(), isStaff);
          final secondDate = _notificationDate(second.data(), isStaff);
          return secondDate.compareTo(firstDate);
        });

        if (reports.isEmpty) {
          return showEmptyMessage
              ? const Text('No report notifications yet.')
              : const SizedBox.shrink();
        }

        return Column(
          children: [
            for (final report in reports.take(8))
              _NotificationTile(
                notification: _notificationFor(report.data(), isStaff),
              ),
          ],
        );
      },
    );
  }

  DateTime _notificationDate(Map<String, dynamic> data, bool isStaff) {
    final value = data[isStaff ? 'createdAt' : 'statusUpdatedAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  _HomeNotification _notificationFor(Map<String, dynamic> data, bool isStaff) {
    final title = data['title'] as String? ?? 'Untitled report';
    if (isStaff) {
      final reporter =
          data['reporterName'] as String? ??
          data['reporterEmail'] as String? ??
          'A student';
      return _HomeNotification(
        icon: Icons.assignment_outlined,
        title: 'Student report submitted',
        message: '$reporter submitted: $title',
        color: const Color(0xFFD97706),
      );
    }

    final status = data['status'] as String? ?? 'Waiting';
    return _HomeNotification(
      icon: Icons.sync_outlined,
      title: 'Report status changed',
      message: '$title is now $status.',
      color: status == 'Completed'
          ? const Color(0xFF059669)
          : const Color(0xFF2563EB),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final _HomeNotification notification;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.color.withValues(alpha: 0.12),
          foregroundColor: notification.color,
          child: Icon(notification.icon),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(notification.message),
      ),
    );
  }
}
