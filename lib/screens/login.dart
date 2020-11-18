import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  /// Key for the form, which allows us to
  /// verify and sign in with the credentials
  final _formKey = GlobalKey<FormState>();

  /// Instance of [FirebaseFirestore]
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    /// Reference for the `users` collection,
    /// So we can add users and sign them in.
    CollectionReference users = _db.collection("users");

    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                validator: (val) {
                  if (val.isEmpty) {
                    return "Field is empty";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
              TextFormField(
                validator: (val) {
                  if (val.isEmpty) {
                    return "Field is empty";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {}
                },
                child: Text('Submit'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
