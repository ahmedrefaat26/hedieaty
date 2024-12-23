import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database/sqldb.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, String> currentUserInfo;

  EditProfilePage({Key? key, required this.currentUserInfo}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentUserInfo['name']);
    emailController = TextEditingController(text: widget.currentUserInfo['email']);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No authenticated user found!'))
      );
      return;
    }

    try {
      // Update the user's own record in the 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': nameController.text,
        'email': emailController.text,
      });

      // Update the user's name in all friend references where they are listed
      var batch = FirebaseFirestore.instance.batch();

      var friendsQuery = await FirebaseFirestore.instance
          .collection('friends')
          .where('friend_id', isEqualTo: user.uid)  // Assuming 'friend_id' is the field that holds the user ID
          .get();

      for (var doc in friendsQuery.docs) {
        batch.update(doc.reference, {'name': nameController.text});
      }

      await batch.commit();

      // Update local database
      await DatabaseHelper.instance.updateUser({
        'firestore_id': user.uid,
        'name': nameController.text,
        'email': emailController.text,
      });

      // Signal that the profile was updated successfully
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'))
      );
      // Return false if the update fails
      Navigator.pop(context, false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: saveProfile,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(20.0),
        children: <Widget>[
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }
}
