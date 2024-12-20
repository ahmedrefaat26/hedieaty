import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database/usersmodel.dart';
import 'home_page.dart';

Future<void> updateUserFCMToken(String newToken) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': newToken,
    });
  }
}

class SignupPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[50],

        title: Text('Sign Up',style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent),
              onPressed: () async {
                if (passwordController.text == confirmPasswordController.text) {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailController.text,
                      password: passwordController.text,
                    );
                    userCredential.user?.updateDisplayName(nameController.text);
                    // Add user to Firestore
                    await addUserToFirestore(userCredential.user);
                    final fcmToken = await FirebaseMessaging.instance.getToken();
                    if(fcmToken != null) {
                      await updateUserFCMToken(fcmToken);
                    }
                    FirebaseMessaging.instance.onTokenRefresh.listen(updateUserFCMToken);

                    // Add user to local database
                    await addUserToLocalDatabase(userCredential.user);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Passwords do not match")),
                  );
                }
              },
              child: Text('Sign Up', style: TextStyle(color: Colors.black),),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context); // Go back to the previous screen (likely the login page)
              },
              child: Text('Already have an account? Log in' , style: TextStyle(color: Colors.black),),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> addUserToFirestore(User? user) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text, // Add the name
        'email': user.email,
        'uid': user.uid,
      });
    }
  }

  Future<void> addUserToLocalDatabase(User? user) async {
    if (user != null) {
      await UserModel.insert(UserModel(
        name: nameController.text, // Use the name from the text field
        email: user.email!,
        firestoreId: user.uid,
      ));
      print("insert succcccccc");
    }
  }
}
