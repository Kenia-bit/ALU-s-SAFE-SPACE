import 'package:campus_incident_reporting_app/Screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_incident_reporting_app/Screens/themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

void main() async {
  // Tells flutter to make sure all native platform channels are ready before running code
  WidgetsFlutterBinding.ensureInitialized();

  // Connect app directly to cloud project
  await Firebase.initializeApp();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppThemeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppThemeProvider>(context);

    return MaterialApp(
      title: 'Campus Incident Reporter',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.isLightMode
          ? ThemeMode.light
          : ThemeMode.dark, // switches active mode
      home: const LoginScreen(),
    );
  }
}