import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database/sqldb.dart'; // Ensure your local database helper is correctly imported

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
          .where('event_id', isEqualTo: widget.eventId)
          .get();

      List<Map<String, dynamic>> fetchedGifts = snapshot.docs.map((doc) {
        return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
      }).toList();

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

  void pledgeGift(String giftId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No authenticated user found!')),
      );
      return;
    }

    try {
      // Update Firestore to mark the gift as pledged and store the pledging user's UID
      await FirebaseFirestore.instance.collection('gifts').doc(giftId).update({
        'status': 'pledged',
        'pledgedBy': currentUser.uid // Store the user ID of who pledged the gift
      });

      // Optional: Update local SQLite database if you are synchronizing with local storage
      final db = await DatabaseHelper.instance.database;
      await db.update(
          'gifts',
          {'status': 'pledged'},
          where: 'firestore_Idgift = ?',
          whereArgs: [giftId]
      );

      fetchGifts(); // Refresh the list after updating
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift successfully pledged!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pledge gift: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts for Event'),
        backgroundColor: Colors.blue,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : gifts.isEmpty
          ? Center(child: Text('No gifts found for this event.'))
          : ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return Card(
            color: Colors.lightBlue[50],
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(gift['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description: ${gift['description']}'),
                  Text('Price: \$${gift['price']}'),
                  Text('Category: ${gift['category']}'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.card_giftcard),
                color: gift['status'] == 'pledged' ? Colors.red : Colors.green,
                onPressed: gift['status'] != 'pledged' ? () => pledgeGift(gift['id']) : null,
              ),
              onTap: () => showGiftDetailsDialog(context, gift),
            ),
          );
        },
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sort Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Name'),
                onTap: () {
                  Navigator.pop(context);
                  _sortGifts('name');
                },
              ),
              ListTile(
                title: Text('Category'),
                onTap: () {
                  Navigator.pop(context);
                  _sortGifts('category');
                },
              ),
              ListTile(
                title: Text('Price'),
                onTap: () {
                  Navigator.pop(context);
                  _sortGifts('price');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sortGifts(String sortBy) {
    setState(() {
      if (sortBy == 'name') {
        gifts.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (sortBy == 'category') {
        gifts.sort((a, b) => a['category'].compareTo(b['category']));
      } else if (sortBy == 'price') {
        gifts.sort((a, b) => a['price'].compareTo(b['price']));
      }
    });
  }

  void showGiftDetailsDialog(BuildContext context, Map<String, dynamic> gift) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Gift Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${gift['name']}'),
              Text('Description: ${gift['description']}'),
              Text('Price: \$${gift['price']}'),
              Text('Category: ${gift['category']}'),
              Text('Status: ${gift['status']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context). pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
