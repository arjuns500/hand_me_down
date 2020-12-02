import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hand_me_down/screens/Notifications.dart';
import 'package:hand_me_down/screens/home.dart';
import 'package:hand_me_down/screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // var user = await FirebaseAuth.instance.authStateChanges().first;
  // if (user != null)
  //   runApp(App(
  //     initialRoute: '/home',
  //   ));
  // else
  //   runApp(App(
  //     initialRoute: '/',
  //   ));
  runApp(App());
}

class App extends StatelessWidget {
  /// This materialApp routes to the Login, Home, and Notification pages.
  /// The home page containes a bottom tab navigator,
  /// which is not really a navigator as it just renders children depending
  /// on the selected widgets, stored in a array.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => Login(),
        '/home': (context) => Home(),
        '/notifs': (context) => Notifications(),
      },
      initialRoute: '/',
    );
  }
}
