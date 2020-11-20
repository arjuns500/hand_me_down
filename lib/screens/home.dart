import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selIndex = 0;

  final CollectionReference requests =
      FirebaseFirestore.instance.collection("requests");

  String itemRequested = "";

  void _onBottomNavTapped(int i) {
    setState(() {
      _selIndex = i;
    });
  }

  final List<Widget> _children = [
    Column(
      children: <Widget>[
        // ListView.builder(
        //   itemBuilder: (context, int i) {
        //     return Card(
        //       child: Column(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           ListTile(
        //             title: Text(),
        //           ),
        //         ],
        //       ),
        //     );
        //   },
        // )
      ],
    ),
    Text("TBD"),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String itemWanted = "";
          await showDialog(
            context: context,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (String value) {
                      itemWanted = value;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Item you need",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      requests.add({
                        'objectWanted': itemWanted,
                        'interested': null,
                        'requestedBy': FirebaseAuth.instance.currentUser.email,
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Submit"),
                  ),
                ],
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _children[_selIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Your requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: "Fullfill request",
          )
        ],
        currentIndex: _selIndex,
        selectedItemColor: Colors.yellow[800],
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
