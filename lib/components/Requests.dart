import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Requests extends StatefulWidget {
  @override
  _RequestsState createState() => _RequestsState();
}

class _RequestsState extends State<Requests> {
  List listOfRequests;
  List requestsUserInterestedIn;

  final CollectionReference requests =
      FirebaseFirestore.instance.collection("requests");

  final CollectionReference notifications =
      FirebaseFirestore.instance.collection("notifications");

  final FirebaseAuth auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot> reqsSubscription;
  StreamSubscription<QuerySnapshot> interestedInSubscription;

  void _fetchRequests() {
    /// Here we fetch the requests a user has created.
    /// The subscription made is cancelled in the `dispose`
    /// method.

    Stream<QuerySnapshot> reqsSnapshot = requests
        .where("requestedBy", isEqualTo: auth.currentUser.email)
        .snapshots();

    reqsSubscription = reqsSnapshot.listen((snapshot) {
      List reqs =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      if (mounted)
        setState(() => listOfRequests = reqs);
      else
        listOfRequests = reqs;
    });

    /// This section fetches the requests a user is interested
    /// in donating.
    Stream<QuerySnapshot> interestedInSnapshot = requests
        .where("interested", isEqualTo: auth.currentUser.email)
        .snapshots();

    interestedInSubscription = interestedInSnapshot.listen((snapshot) {
      List reqsInterestedIn =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      if (mounted)
        setState(() {
          requestsUserInterestedIn = reqsInterestedIn;
        });
      else {
        requestsUserInterestedIn = reqsInterestedIn;
      }
    });
  }

  /// initState allows us to have a place to start a listener
  /// to fetch the requests the user makes.
  @override
  void initState() {
    _fetchRequests();
    super.initState();
  }

  @override
  void dispose() {
    /// Here we cancel the subscriptions made
    /// in the _fetchRequests method when the widget is destroyed.
    reqsSubscription.cancel();
    interestedInSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(20),
          child: Center(
            child: Text(
              "Your requests",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        if (listOfRequests == null)
          Title(color: Colors.white, child: Text("Loading..."))
        else if (listOfRequests.isEmpty)
          Title(color: Colors.white, child: Text("You have no requests"))
        else ...[
          Divider(
            color: Colors.black,
          ),
          Expanded(
            /// This list view builder builds a list of all the
            /// requests the user makes in the app.
            /// [Slideable] is used to allow for showing a
            /// delete button on slide.
            child: ListView.builder(
              itemCount: listOfRequests.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Slidable(
                    actionPane: SlidableDrawerActionPane(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(listOfRequests[index]['objectWanted']),
                          subtitle: Text(listOfRequests[index]['interested'] ??
                              "No one is interested"),
                        ),
                        if (listOfRequests[index]['interested'] != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PopupMenuButton(
                                onSelected: (String value) {
                                  /// Canceling doesnt seem to work in the onPressed method,
                                  /// So it is here instead.
                                  if (value == "cancel") {
                                    notifications.add({
                                      'from': auth.currentUser.email,
                                      'to': listOfRequests[index]['interested'],
                                      'subject':
                                          '${auth.currentUser.email} has canceled donating to ${listOfRequests[index]['requestedBy']}',
                                      'sentOn': FieldValue.serverTimestamp(),
                                      'type': 'premade'
                                    });
                                    requests
                                        .doc(listOfRequests[index]['id'])
                                        .update({
                                      'interested': null,
                                      'status': FieldValue.delete(),
                                    });
                                  }
                                  Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Canceled"),
                                      duration: new Duration(seconds: 3),
                                    ),
                                  );
                                },
                                itemBuilder: (menucontext) => [
                                  PopupMenuItem(
                                    value: "cancel",
                                    child: TextButton(
                                        child: Text("Cancel"),
                                        onPressed: () {
                                          Navigator.of(menucontext).pop();
                                        }),
                                  ),
                                  PopupMenuItem(
                                    value: "send_msg",
                                    child: TextButton(
                                        child: Text("Send Message"),
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
                                                      hintText: "Message"),
                                                ),
                                                actions: <Widget>[
                                                  new FlatButton(
                                                    child: new Text('Submit'),
                                                    onPressed: () {
                                                      notifications.add({
                                                        'from': auth
                                                            .currentUser.email,
                                                        'to': listOfRequests[
                                                                index]
                                                            ['interested'],
                                                        'subject':
                                                            _messageFieldController
                                                                .text,
                                                        'type': 'custom',
                                                        'sentOn': FieldValue
                                                            .serverTimestamp()
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          Navigator.of(menucontext).pop();
                                        }),
                                  ),
                                  PopupMenuItem(
                                    value: "product_recieved",
                                    child: TextButton(
                                      child: Text("Product Received"),
                                      onPressed: () {
                                        Navigator.of(menucontext).pop();
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(
                                                  'Are you sure you have received the item and are ready to close this request?'),
                                              actions: <Widget>[
                                                new FlatButton(
                                                  child: new Text('Submit'),
                                                  onPressed: () {
                                                    requests
                                                        .doc(
                                                          listOfRequests[index]
                                                              ['id'],
                                                        )
                                                        .delete();
                                                    notifications.add({
                                                      'to':
                                                          listOfRequests[index]
                                                              ['interested'],
                                                      'subject':
                                                          "${auth.currentUser.email} has received the item and closed the request for \"${requestsUserInterestedIn[index]['objectWanted']}\"",
                                                      'type': 'premade',
                                                      'sentOn': FieldValue
                                                          .serverTimestamp(),
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    secondaryActions: [
                      IconSlideAction(
                        caption: "Delete",
                        color: Colors.red,
                        icon: Icons.delete,
                        closeOnTap: true,
                        onTap: () {
                          requests.doc(listOfRequests[index]['id']).delete();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(
            color: Colors.black,
          ),
        ],

        /// This section shows all the requests the user has
        /// opted in to donate.
        Container(
          margin: EdgeInsets.all(20),
          child: Center(
            child: Text(
              "Requests you are interested in",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        if (requestsUserInterestedIn == null)
          Title(color: Colors.white, child: Text("Loading..."))
        else if (requestsUserInterestedIn.isEmpty)
          Title(color: Colors.white, child: Text("You have no requests"))
        else ...[
          Divider(
            color: Colors.black,
          ),
          Expanded(
            /// This list view builder builds a list of all the
            /// requests the user makes in the app.
            /// [Slideable] is used to allow for showing a
            /// delete button on slide.
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: requestsUserInterestedIn.length,
              itemBuilder: (listcontext, index) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                            requestsUserInterestedIn[index]['objectWanted']),
                        subtitle: Text("For: " +
                            requestsUserInterestedIn[index]['requestedBy']),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PopupMenuButton(
                            onSelected: (value) {
                              switch (value) {
                                case "cancel":
                                  notifications.add({
                                    'from': auth.currentUser.email,
                                    'to': requestsUserInterestedIn[index]
                                        ['requestedBy'],
                                    'subject':
                                        '${auth.currentUser.email} has canceled donating to ${requestsUserInterestedIn[index]['objectWanted']}',
                                    'sentOn': FieldValue.serverTimestamp(),
                                    'type': 'premade'
                                  });
                                  requests
                                      .doc(
                                          requestsUserInterestedIn[index]['id'])
                                      .update({
                                    'interested': null,
                                    'status': FieldValue.delete(),
                                  });
                                  Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Canceled"),
                                      duration: new Duration(seconds: 2),
                                    ),
                                  );
                                  break;
                                default:
                              }
                            },
                            itemBuilder: (menucontext) => [
                              PopupMenuItem(
                                value: "cancel",
                                child: TextButton(
                                  child: Text("Cancel"),
                                  onPressed: () =>
                                      Navigator.of(menucontext).pop(),
                                ),
                              ),
                              PopupMenuItem(
                                value: "send_msg",
                                child: TextButton(
                                  child: Text("Send Message"),
                                  onPressed: () {
                                    TextEditingController _textFieldController =
                                        TextEditingController();
                                    showDialog(
                                      context: menucontext,
                                      builder: (menucontext) {
                                        return AlertDialog(
                                          title: Text('Send a message'),
                                          content: TextField(
                                            controller: _textFieldController,
                                            decoration: InputDecoration(
                                                hintText: "Message"),
                                          ),
                                          actions: <Widget>[
                                            new FlatButton(
                                              child: new Text('Submit'),
                                              onPressed: () {
                                                if (auth.currentUser.email ==
                                                    requestsUserInterestedIn[
                                                        index]['requestedBy'])
                                                  notifications.add(
                                                    {
                                                      'type': 'custom',
                                                      'to':
                                                          requestsUserInterestedIn[
                                                                  index]
                                                              ['interested'],
                                                      'from':
                                                          requestsUserInterestedIn[
                                                                  index]
                                                              ['requestedBy'],
                                                      'subject':
                                                          _textFieldController
                                                              .text,
                                                      'sentOn': FieldValue
                                                          .serverTimestamp()
                                                    },
                                                  );
                                                else
                                                  notifications.add(
                                                    {
                                                      'type': 'custom',
                                                      'to':
                                                          requestsUserInterestedIn[
                                                                  index]
                                                              ['requestedBy'],
                                                      'from':
                                                          requestsUserInterestedIn[
                                                                  index]
                                                              ['interested'],
                                                      'subject':
                                                          _textFieldController
                                                              .text,
                                                      'sentOn': FieldValue
                                                          .serverTimestamp()
                                                    },
                                                  );
                                                Navigator.of(menucontext).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(
            color: Colors.black,
          ),
        ]
      ],
    );
  }
}
