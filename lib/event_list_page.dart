import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'FriendGiftList.dart';

class EventListPage extends StatefulWidget {
  final String friendId;

  EventListPage({required this.friendId});

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Map<String, dynamic>> events = [];
  String friendName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
    fetchEvents();
  }

  Future<void> fetchUserName() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendId)
          .get();

      if (snapshot.exists) {
        setState(() {
          friendName = snapshot.data()?['name'] ?? 'Unknown User';
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  Future<void> fetchEvents() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('user_id', isEqualTo: widget.friendId)
          .get();

      List<Map<String, dynamic>> fetchedEvents = snapshot.docs.map((doc) {
        DateTime date = (doc.data()['date'] as Timestamp).toDate();
        String formattedDate = DateFormat('yyyy-MM-dd').format(
            date); // Adjust the format as needed

        return {
          'id': doc.id,
          'name': doc.data()['name'],
          'description': doc.data()['description'],
          'date': formattedDate,
          // Now 'date' is a formatted string
          'location': doc.data()['location'],
          // Assuming there's a 'location' field
        };
      }).toList();

      setState(() {
        events = fetchedEvents;
      });
    } catch (e) {
      print("Error fetching events: $e");
    }
  }
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sort by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Name'),
                onTap: () {
                  Navigator.pop(context);
                  _sortEvents('name');
                },
              ),
              ListTile(
                title: Text('Date'),
                onTap: () {
                  Navigator.pop(context);
                  _sortEvents('date');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sortEvents(String criteria) {
    setState(() {
      if (criteria == 'name') {
        events.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (criteria == 'status') {
        // Ensure that 'status' is a field you are tracking; otherwise, adjust accordingly
        events.sort((a, b) => a['status'].compareTo(b['status']));
      } else if (criteria == 'date') {
        events.sort((a, b) {
          DateTime dateA = DateTime.parse(a['date']);
          DateTime dateB = DateTime.parse(b['date']);
          return dateA.compareTo(dateB);
        });
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName.isEmpty ? 'Loading...' : 'Events for $friendName'),
        backgroundColor: Colors.blue,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),

      body: events.isEmpty
          ? Center(child: Text("No events found for this user."))
          : ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            color: Colors.lightBlue[50],
            elevation: 4.0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(event['name'] ?? 'No Event Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "Description: ${event['description'] ??
                      'No Description'}\nDate: ${event['date']}\nLocation: ${event['location']}"
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendGiftList(eventId: event['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}