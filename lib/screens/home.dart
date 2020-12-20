import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart';
import 'package:hand_me_down/components/Requests.dart';
import 'package:hand_me_down/components/Search.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selIndex = 0;

  final CollectionReference requests =
      FirebaseFirestore.instance.collection("requests");

  final CollectionReference notifications =
      FirebaseFirestore.instance.collection("all_notifications");

  final auth = FirebaseAuth.instance;

  final geo = Geoflutterfire();

  String itemRequested = "";
  List listOfRequests;
  List searchResults;
  GeoFirePoint position;

  void _onBottomNavTapped(int i) {
    setState(() {
      _selIndex = i;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Location location = new Location();

      bool _serviceEnabled;
      PermissionStatus _permissionGranted;

      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Location Permission"),
                  content: Text(
                      "Location is needed to use this app. Please reconsider allowing this permission"),
                  actions: [
                    FlatButton(
                      child: Text("Allow"),
                      onPressed: () async {
                        _permissionGranted = await location.requestPermission();
                        if (_permissionGranted != PermissionStatus.granted)
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (route) => false);
                      },
                    ),
                    FlatButton(
                      child: Text("Cancel"),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false),
                    ),
                  ],
                );
              });
        }
      }
      var pos = await location.getLocation();
      GeoFirePoint point =
          geo.point(latitude: pos.latitude, longitude: pos.longitude);
      setState(() => position = point);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// List of widgets
    /// The bottom tab navigator uses this list
    /// to navigate between the [Requests] and [Search] screens.
    final List<Widget> _children = [
      Requests(),
      Search(position: position),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                String itemWanted = "";
                await showDialog(
                  context: context,
                  child: AlertDialog(
                    title: Text("Request object"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          onChanged: (String value) {
                            itemWanted = value;
                          },
                          decoration:
                              InputDecoration(labelText: "Item you need"),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          /// Here an object is added to the database
                          /// `interested` is set to null by default
                          /// so it is easy to query for requests
                          /// that haven't been donated to yet
                          requests.add({
                            'objectWanted': itemWanted,
                            'interested': null,
                            'requestedBy': auth.currentUser?.email,
                            'position': position.data,
                          });
                          Navigator.pop(context);
                        },
                        child: Text("Submit"),
                      ),
                    ],
                  ),
                );
              }),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifs');
            },
          ),
        ],
      ),
      body: _children[_selIndex],
      bottomNavigationBar: BottomNavigationBar(
        /// The bottom navigation bar
        /// shows the options of creating requests
        /// and fullfilling them.
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
