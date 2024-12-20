import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hedieaty/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _onFCMBackgroundMessage(RemoteMessage message) async {
  print(
      "Notification in background: ${message.notification?.title} - ${message
          .notification?.body}");
}

void _showNotification(RemoteMessage message) {
  BuildContext? context = navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Notification'),
            content: Text(
                'Notification in background: ${message.notification
                    ?.title} - ${message.notification?.body}'),
          ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure plugins are initialized
  await Firebase.initializeApp(); // Initialize Firebase

  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("Token is: $fcmToken");

  FirebaseMessaging.onBackgroundMessage(_onFCMBackgroundMessage);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
        'Notification in foreground: ${message.notification?.title} - ${message
            .notification?.body}');
    _showNotification(message);
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  Future<void> requestNotificationPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    requestNotificationPermissions();
    return MaterialApp(
      title: 'Hedieaty App',
      debugShowCheckedModeBanner: false, // Disable the debug banner
      home: SplashScreen(),
      navigatorKey: navigatorKey,
    );
  }
}