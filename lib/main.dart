// ignore_for_file: unused_import

import 'package:crud_alarm/provider/alarm_provider.dart';
import 'package:crud_alarm/provider/uiprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'screen/homepage.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/data/latest_all.dart' as tz;


FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
   WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await AlarmProvider.initialize(); 

  // Initialize time zones for notifications
  tz.initializeTimeZones();

  // Request notification permissions
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!
      .requestNotificationsPermission();

 // Preserve splash screen
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      await Future.delayed(const Duration(milliseconds: 2));
      FlutterNativeSplash.remove();

  runApp(
    // Wrap MaterialApp with ChangeNotifierProvider to provide the UiProvider instance
    ChangeNotifierProvider(
      create: (BuildContext context) => UiProvider()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Consumer widget to access the UiProvider and retrieve the dark mode settings
    return Consumer<UiProvider>(
      builder: (context, UiProvider notifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Alarm Buddy',
          // Set theme mode based on dark mode settings
          themeMode: notifier.isDark ? ThemeMode.dark : ThemeMode.light,
          // Apply custom dark and light themes
          darkTheme: notifier.darkTheme,
          theme: notifier.lightTheme,
          home: const HomePage(),
        );
      },
    );
  }
}