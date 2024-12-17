import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventListPage extends StatefulWidget {
  final String friendId;  // Accept friendId from HomePage

  EventListPage({required this.friendId});  // Constructor to receive friendId

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Map<String, dynamic>> events = [];  // Store events
  String friendName = '';  // Store the friend's name

  @override
  void initState() {
    super.initState();
    fetchUserName();  // Fetch friend's name when the page is loaded
    fetchEvents();     // Fetch events when the page is loaded
  }

  // Fetch the user's name from Firestore using friendId
  Future<void> fetchUserName() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')  // Assuming user data is stored in 'users' collection
          .doc(widget.friendId)  // Get the document by friendId
          .get();

      if (snapshot.exists) {
        setState(() {
          friendName = snapshot.data()?['name'] ?? 'Unknown User';  // Set the friend's name
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  // Fetch events from Firestore based on the friendId
  Future<void> fetchEvents() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('user_id', isEqualTo: widget.friendId)  // Use friendId to filter events
          .get();

      List<Map<String, dynamic>> fetchedEvents = snapshot.docs.map((doc) {
        return {
          'name': doc.data()['name'],
          'description': doc.data()['description'],
          'date': doc.data()['date'],
        };
      }).toList();

      setState(() {
        events = fetchedEvents;  // Update the state with the fetched events
      });
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName.isEmpty ? 'Loading...' : 'Events for $friendName'),  // Show the friend's name
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
              // Handle event tap (optional)
            },
          );
        },
      ),
    );
  }
}
