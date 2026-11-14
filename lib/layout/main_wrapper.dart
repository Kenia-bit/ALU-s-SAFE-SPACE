import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_incident_reporting_app/Screens/themes.dart';
import 'package:campus_incident_reporting_app/Screens/home_dashboard.dart';
import 'package:campus_incident_reporting_app/Screens/reports_feed_screen.dart';
import 'package:campus_incident_reporting_app/Screens/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  final String userRole; // Receives 'student' or 'staff' dynamically
  const MainWrapper({super.key, required this.userRole});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // Variable to track the tab that is currently selected
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userRole == 'staff' ? "ALU Staff Panel" : "ALU Student Hub",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isLightMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeDashboard(userRole: widget.userRole),
          ReportsFeedScreen(userRole: widget.userRole),
          ProfileScreen(userRole: widget.userRole, showAppBar: false),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
