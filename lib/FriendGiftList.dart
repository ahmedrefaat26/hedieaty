import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendGiftList extends StatefulWidget {
  final String eventId;

  FriendGiftList({required this.eventId});

  @override
  _FriendGiftListState createState() => _FriendGiftListState();
}

class _FriendGiftListState extends State<FriendGiftList> {
  List<Map<String, dynamic>> gifts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGifts();
  }

  void fetchGifts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('eventId', isEqualTo: widget.eventId)
          .get();

      List<Map<String, dynamic>> fetchedGifts = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      setState(() {
        gifts = fetchedGifts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching gifts: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts for Event'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : gifts.isEmpty
          ? Center(child: Text('No gifts found for this event.'))
          : ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> gift = gifts[index];
          return ListTile(
            title: Text(gift['name']),
            subtitle: Text(gift['description'] ?? 'No description provided.'),
            trailing: Text('\$${gift['price'].toString()}'),
          );
        },
      ),
    );
  }
}
