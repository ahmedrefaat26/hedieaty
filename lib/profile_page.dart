import 'package:flutter/material.dart';
import 'EditProfilePage.dart';
import 'splash_screen.dart'; // Ensure this is the correct path to your SplashScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, String> userInfo = {};

  @override
  void initState() {
    super.initState();
    if (user != null) {
      fetchUserInfo();
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        userInfo['name'] = data['name'];
        userInfo['email'] = data['email'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user data: $e')),
      );
    }
  }

  void navigateAndDisplayEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditProfilePage(currentUserInfo: userInfo)),
    );

    if (result != null) {
      setState(() {
        userInfo = Map<String, String>.from(result);
      });
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
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150'), // Placeholder for profile image
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
        ],
      ),
    );
  }
}
