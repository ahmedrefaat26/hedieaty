import 'package:flutter/material.dart';
import 'package:hedieaty/gift_details_page.dart';

class GiftListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample data for gifts, you can replace this with real data from a database or API
    final List<String> gifts = [
      'Gift Card',
      'Book Set',
      'Chocolate Box',
      'Custom Mug',
      'Flower Bouquet'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Gift List'),
      ),
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(gifts[index]),
            onTap: () {
              // Navigate to GiftDetailsPage when a gift is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftDetailsPage(giftName: gifts[index]), // Passing the gift name to the details page
                ),
              );
            },
          );
        },
      ),
    );
  }
}
