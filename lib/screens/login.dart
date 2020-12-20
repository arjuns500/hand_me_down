import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A screen for the user to login. Uses `google_sign_in` package to sign in
/// with google auth. After signing in, starts a listener for auth
/// changes, and navigates to the home screen.
class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    /// Signs a user in with a Google OAuth popup.
    Future<UserCredential> signIn() async {
      // Initiate the login
      final GoogleSignInAccount user = await GoogleSignIn().signIn();
      if (user == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await user.authentication;
      final GoogleAuthCredential cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(cred);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () {
            signIn().then((user) {
              if (user != null)
                Navigator.pushReplacementNamed(context, '/home');
              else
                print("Sign in Cancelled");
            }).catchError((e) {
              // show the dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Error"),
                    content: Text("An unexpected error was encountered.\n\n$e"),
                    actions: [
                      FlatButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  );
                },
              );

              print(e);
            });
          },
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}
