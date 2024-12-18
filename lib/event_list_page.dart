import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        return {
          'id': doc.id,  // Store event ID to use for navigation
          'name': doc.data()['name'],
          'description': doc.data()['description'],
          'date': doc.data()['date'],
        };
      }).toList();

      setState(() {
        events = fetchedEvents;
      });
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName.isEmpty ? 'Loading...' : 'Events for $friendName'),
      ),
      body: events.isEmpty
          ? Center(child: Text("No events found for this user."))
          : ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(events[index]['name'] ?? 'No Event Name'),
            subtitle: Text(events[index]['description'] ?? 'No Description'),
            onTap: () {
              // Navigate to the FriendGiftList page when an event is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendGiftList(eventId: events[index]['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
