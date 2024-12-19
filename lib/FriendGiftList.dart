import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database/sqldb.dart'; // Import your local database helper if used

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
    setState(() {
      isLoading = true; // Show loading indicator during the operation
    });

    try {
      // Update Firestore
      await FirebaseFirestore.instance.collection('gifts').doc(giftId).update({
        'status': 'pledged'
      });

      // Update local SQLite database
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
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator after operation
      });
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
          :ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return ListTile(
            title: Text(gift['name']),
            subtitle: Text(gift['description'] ?? 'No description provided.'),
            trailing: Wrap(
              spacing: 12, // space between two icons
              children: <Widget>[
                Text('\$${gift['price'].toString()}'),
                IconButton(
                  icon: Icon(Icons.card_giftcard),
                  color: gift['status'] == 'pledged' ? Colors.red : Colors.green,
                  onPressed: () {
                    if (gift['status'] != 'pledged') {
                      pledgeGift(gift['id']);
                    }
                  },
                ),
              ],
            ),
            onTap: () => showGiftDetailsDialog(context, gift),
          );
        },
      ),
    );
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
