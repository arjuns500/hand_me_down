import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Notifications extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List notifications;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final CollectionReference notificationRef =
      FirebaseFirestore.instance.collection("notifications");

  StreamSubscription<QuerySnapshot> notifStream;

  /// Gets the notifications using the `.get` method.
  /// To refresh, simply calling this method again will do.
  /// This method also calls `setState` if mounted, otherwise
  /// simply sets the notifications property.
  void _getNotifs() {
    notifStream = notificationRef
        .where("to", isEqualTo: auth.currentUser.email)
        .orderBy("sentOn", descending: true)
        .snapshots()
        .listen((snapshot) {
      var notifData =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      if (mounted) {
        setState(() {
          notifications = notifData;
        });
      } else {
        notifications = notifData;
      }
    });
  }

  @override
  void initState() {
    _getNotifs();
    super.initState();
  }

  @override
  void dispose() {
    notifStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () {
              if (notifications != null) {
                for (var e in notifications) {
                  notificationRef.doc(e['id']).delete();
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 8),
            if (notifications == null)
              Text("Loading...")
            else if (notifications.isEmpty)
              Text("No new notifications")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return Slidable(
                      actionPane: SlidableDrawerActionPane(),
                      secondaryActions: [
                        IconSlideAction(
                          caption: "Delete",
                          icon: Icons.delete,
                          color: Colors.red,
                          closeOnTap: true,
                          onTap: () => notificationRef
                              .doc(notifications[index]['id'])
                              .delete(),
                        )
                      ],
                      child: Card(
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(notifications[index]['subject']),
                              subtitle: (notifications[index]['type'] ==
                                      "custom")
                                  ? Text(
                                      "Sent by ${notifications[index]['from']}")
                                  : null,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (notifications[index]['type'] == "custom")
                                  RaisedButton(
                                    child: Text("Reply"),
                                    onPressed: () {
                                      TextEditingController
                                          _messageFieldController =
                                          TextEditingController();
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text('Send a message'),
                                            content: TextField(
                                              controller:
                                                  _messageFieldController,
                                              decoration: InputDecoration(
                                                hintText: "Message",
                                              ),
                                            ),
                                            actions: <Widget>[
                                              new FlatButton(
                                                child: new Text('Submit'),
                                                onPressed: () {
                                                  notificationRef.add({
                                                    'from': notifications[index]
                                                        ['to'],
                                                    'to': notifications[index]
                                                        ['from'],
                                                    'subject':
                                                        _messageFieldController
                                                            .text,
                                                    'type': 'custom',
                                                    'sentOn': FieldValue
                                                        .serverTimestamp()
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                              )
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  )
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
