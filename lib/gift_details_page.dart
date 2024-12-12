import 'package:flutter/material.dart';

class GiftDetailsPage extends StatelessWidget {
  final String giftName;

  // Constructor to receive gift name
  GiftDetailsPage({required this.giftName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gift Details'),
      ),
      body: Center(
        child: Text('Details of $giftName',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
