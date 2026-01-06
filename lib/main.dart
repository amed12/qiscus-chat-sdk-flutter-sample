import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qiscus_chat_flutter_sample/providers/auth_provider.dart';
import 'package:qiscus_chat_flutter_sample/providers/chat_provider.dart';
import 'package:qiscus_chat_flutter_sample/screens/splash_screen.dart';
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(_firebaseMessagingOnMessageHandler);

  // Initialize Qiscus SDK
  await QiscusService.instance.initialize();

  debugPrint('Firebase initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Qiscus Chat SDK Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('got background message');

  var payload = message.data['payload'];
  var json = jsonDecode(payload ?? "{}") as Map<String, dynamic>;

  debugPrint('data: $json');
}

void _firebaseMessagingOnMessageHandler(RemoteMessage event) {
  debugPrint('got foreground message');
  var payload = event.data['payload'];
  var json = jsonDecode(payload ?? "{}") as Map<String, dynamic>;
  debugPrint('data: $json');
}
