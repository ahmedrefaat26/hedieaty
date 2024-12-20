import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';  // For date formatting

class MyPledgedGiftsPage extends StatefulWidget {
  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> pledgedGifts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPledgedGifts();
  }

  Future<void> fetchPledgedGifts() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No authenticated user found!')),
      );
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('pledgedBy', isEqualTo: user?.uid)
          .get();

      List<Future> giftsDetails = snapshot.docs.map((doc) async {
        var eventSnapshot = await FirebaseFirestore.instance
            .collection('events')
            .doc(doc['event_id'])
            .get();

        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(eventSnapshot['user_id'])
            .get();

        return {
          'name': doc['name'],
          'friendName': userSnapshot['name'],
          'date': DateFormat('yyyy-MM-dd').format((eventSnapshot['date'] as Timestamp).toDate()),
          'price': doc['price'].toString(),
        };
      }).toList();

      var results = await Future.wait(giftsDetails);
      setState(() {
        pledgedGifts = List<Map<String, dynamic>>.from(results);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching pledged gifts: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('My Pledged Gifts'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pledgedGifts.isEmpty
          ? Center(child: Text('No pledged gifts found.'))
          : ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          return Card(
            color: Colors.lightBlue[50],
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(gift['name'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Friend: ${gift['friendName']}\nDate: ${gift['date']}\nPrice: \$${gift['price']}'),
              trailing: Icon(Icons.card_giftcard, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
