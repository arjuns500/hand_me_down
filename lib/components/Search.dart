import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class Search extends StatefulWidget {
  final GeoFirePoint position;

  const Search({Key key, @required this.position}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final CollectionReference requests =
      FirebaseFirestore.instance.collection("requests");

  final CollectionReference notifications =
      FirebaseFirestore.instance.collection("notifications");

  final FirebaseAuth auth = FirebaseAuth.instance;
  final geo = Geoflutterfire();
  final TextEditingController _searchController = TextEditingController();

  double _radius = 1;

  void _searchRequests(String query) async {
    if (query == "") {
      setState(() => searchResults = null);
    } else {
      geo
          .collection(collectionRef: requests)
          .within(
            center: widget.position,
            radius: _radius,
            field: 'position',
          )
          .first
          .then((docs) {
        var results = docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        var filteredResults = results
            .where((element) =>
                element['objectWanted']
                    .toLowerCase()
                    .contains(query.toLowerCase()) &&
                (element['interested'] == null))
            .toList();
        mounted
            ? setState(() => searchResults = filteredResults)
            : searchResults = filteredResults;
      });
    }
  }

  /// Results of the search that are set by the [_searchRequests] function
  List searchResults;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: _searchController,
          onSubmitted: (text) => _searchRequests(text),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(left: 20),
          ),
        ),
        Slider(
          value: _radius,
          min: 1,
          max: 100,
          divisions: 20,
          label: _radius.round().toString() + "km",
          onChanged: (value) => setState(() => _radius = value),
          onChangeEnd: (_) => _searchRequests(_searchController.text),
        ),
        if (searchResults == null)
          Title(color: Colors.white, child: Text("Search for a item"))
        else if (searchResults.isEmpty)
          Title(color: Colors.white, child: Text("No such item"))
        else
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(searchResults[index]['objectWanted']),
                        subtitle: Text(
                          searchResults[index]['interested'] ??
                              "No one is interested",
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          RaisedButton(
                            child: Text("Donate"),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                        "Are you sure you want to do this? This involves sharing your email address."),
                                    actions: [
                                      RaisedButton(
                                          child: Text("Yes"),
                                          onPressed: () {
                                            requests
                                                .doc(searchResults[index]['id'])
                                                .update({
                                              'interested':
                                                  auth.currentUser.email,
                                              'status': 'interested'
                                            });
                                            notifications.add({
                                              'to': searchResults[index]
                                                  ['requestedBy'],
                                              'subject':
                                                  "${auth.currentUser.email} is interested in donating \"${searchResults[index]['objectWanted']}\"",
                                              'type': 'premade',
                                              'sentOn':
                                                  FieldValue.serverTimestamp()
                                            });
                                            Navigator.of(context).pop();
                                            _searchRequests("");
                                          }),
                                      RaisedButton(
                                          child: Text("No"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          })
                                    ],
                                  );
                                },
                              );
                              requests.doc(searchResults[index]['id']).update({
                                'interested': auth.currentUser.email,
                                'status': "interested"
                              });
                            },
                          ),
                          SizedBox(
                            width: 8,
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
