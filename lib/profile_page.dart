import 'package:flutter/material.dart';
import 'EditProfilePage.dart';
import 'splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'FriendGiftList.dart';
import 'pledged_gifts_page.dart'; // Make sure you have this page created
import 'package:intl/intl.dart'; // Import intl to format dates

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, String> userInfo = {};
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    if (user != null) {
      fetchUserInfo();
      fetchEvents();
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          userInfo['name'] = data['name'];
          userInfo['email'] = data['email'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: $e')),
      );
    }
  }

  Future<void> fetchEvents() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('user_id', isEqualTo: user!.uid)
          .get();

      List<Future> eventDetails = snapshot.docs.map((event) async {
        var giftSnapshot = await FirebaseFirestore.instance
            .collection('gifts')
            .where('event_id', isEqualTo: event.id)
            .get();

        return {
          'id': event.id,
          'name': event['name'],
          'date': DateFormat('yyyy-MM-dd').format((event['date'] as Timestamp).toDate()),
          'giftCount': giftSnapshot.docs.length,
        };
      }).toList();

      var results = await Future.wait(eventDetails);
      setState(() {
        events = List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching events: $e')),
      );
    }
  }

  void navigateAndDisplayEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditProfilePage(currentUserInfo: userInfo)),
    );

    // Check if the result contains data indicating that the profile was updated
    if (result == true) {
      fetchUserInfo(); // Re-fetch user info to update the UI
    }
  }


  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Profile'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => navigateAndDisplayEditProfile(context),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                  ),
                ),
                ListTile(
                  title: Text('Name'),
                  subtitle: Text(userInfo['name'] ?? 'No Name Provided'),
                ),
                ListTile(
                  title: Text('Email'),
                  subtitle: Text(userInfo['email'] ?? 'No Email Provided'),
                ),
                ...events.map((event) => Card(
                  color: Colors.lightBlue[50],
                  child: ListTile(
                    title: Text(event['name']),
                    subtitle: Text('Date: ${event['date']} - Gifts: ${event['giftCount']}'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => FriendGiftList(eventId: event['id']),
                      ));
                    },
                  ),
                )).toList(),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 150), // Adjust the bottom padding to move the button up
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPledgedGiftsPage()),
                );
              },
              child: Text('My Pledged Gifts'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
              ),
            ),
          )

        ],
      ),
    );
  }
}
