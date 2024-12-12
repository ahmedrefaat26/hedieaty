import 'package:flutter/material.dart';
import 'FriendGiftList.dart'; // Make sure this import is correct for your gift list page

class EventListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
      ),
      body: ListView.builder(
        itemCount: 10, // Number of events
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Event ${index + 1}'), // Each list item is titled "Event 1", "Event 2", etc.
            onTap: () {
              // When you tap on an event, navigate to the FriendGiftListPage for that event
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendGiftListPage(), // Pass event details if necessary
                ),
              );
            },
          );
        },
      ),
    );
  }
}
