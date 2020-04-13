import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';

class AppState extends ChangeNotifier {
  static Future<void> onBackgroundMessage(Map<String, dynamic> json) async {
    //
    print('fbMessaging::@background-message -> $json');
  }

  AppState() {
    qiscus.enableDebugMode(enable: true);
    fbMessaging.configure(
      onBackgroundMessage: AppState.onBackgroundMessage,
      onMessage: (Map<String, dynamic> json) async {
        print('fbMessaging@message -> $json');
      },
    );
    fbMessaging.requestNotificationPermissions();
  }

  final fbMessaging = FirebaseMessaging();
  final qiscus = QiscusSDK();

  String token;
  QAccount _account;

  set account(QAccount account) {
    _account = account;
    notifyListeners();
  }

  QAccount get account => _account;

  bool get isLoggedIn => account != null;

  String get userId => account?.id;

  Future<void> setup(String appId) {
    var completer = Completer<void>();
    qiscus.setup(appId, callback: (err) {
      if (err != null) return completer.completeError(err);

      completer.complete();
    });
    return completer.future;
  }

  Future<QAccount> setUser(String userId, String userKey) {
    var completer = Completer<QAccount>();
    qiscus.setUser(
      userId: userId,
      userKey: userKey,
      callback: (account, error) async {
        if (error != null) return completer.completeError(error);
        this.account = account;

        var token = await fbMessaging.getToken();
        this.token = token;
        qiscus.registerDeviceToken(
          token: token,
          isDevelopment: true,
          callback: (isChanged, error) {
            if (error != null) return completer.completeError(error);

            return completer.complete(account);
          },
        );
      },
    );
    return completer.future;
  }

  @override
  void dispose() {
    if (this.token != null) {
      qiscus.removeDeviceToken(
        token: this.token,
        callback: (_isChanged, _err) {
          //
        },
      );
    }
    qiscus.clearUser(callback: (err) {
      print('error while clearing user data');
    });
    super.dispose();
  }
}
