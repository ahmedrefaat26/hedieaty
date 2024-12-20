import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database/sqldb.dart';

class GiftListPage extends StatefulWidget {
  final String eventId;

  GiftListPage({required this.eventId});

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Map<String, dynamic>> giftList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGifts();
  }

  void _fetchGifts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('event_id', isEqualTo: widget.eventId)
          .get();

      setState(() {
        giftList = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching gifts: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteGift(String giftId) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper.instance;

      // Delete from Firestore
      await FirebaseFirestore.instance.collection('gifts').doc(giftId).delete();

      // Delete from Local Database
      await db.database.then((db) => db.delete(
        'gifts',
        where: 'firestore_Idgift = ?',
        whereArgs: [giftId],
      ));

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gift deleted successfully!')));
      _fetchGifts();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting gift: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _submitGift(
      String name, String description, String price, String category, {String? giftId}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> giftData = {
      'name': name,
      'description': description,
      'price': double.parse(price),
      'category': category,
      'status': 'available',
      'event_id': widget.eventId,
    };

    try {
      final db = DatabaseHelper.instance;

      if (giftId == null) {
        // Insert into Firestore and retrieve Firestore ID
        DocumentReference docRef = await FirebaseFirestore.instance.collection('gifts').add(giftData);
        String firestoreId = docRef.id;

        // Insert into Local Database including Firestore ID
        Map<String, dynamic> localGiftData = Map.from(giftData);
        localGiftData['firestore_Idgift'] = firestoreId; // Store Firestore ID locally

        await db.database.then((db) => db.insert('gifts', localGiftData));
      } else {
        // Update Firestore
        await FirebaseFirestore.instance.collection('gifts').doc(giftId).update(giftData);

        // Update Local Database including Firestore ID update
        Map<String, dynamic> localGiftData = Map.from(giftData);
        localGiftData['firestore_Idgift'] = giftId; // Update Firestore ID just in case

        await db.database.then((db) => db.update(
          'gifts',
          localGiftData,
          where: 'firestore_Idgift = ?',
          whereArgs: [giftId],
        ));
      }

      _fetchGifts(); // Refresh gift list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift ${giftId == null ? 'added' : 'updated'} successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding/updating gift: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _showGiftDetails(Map<String, dynamic> gift) {
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
  void _sortGifts(String sortBy) {
    setState(() {
      if (sortBy == 'name') {
        giftList.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (sortBy == 'date') {
        giftList.sort((a, b) {
          var dateA = DateTime.parse(a['eventDate']); // Assuming 'eventDate' is formatted properly
          var dateB = DateTime.parse(b['eventDate']);
          return dateA.compareTo(dateB);
        });
      } else if (sortBy == 'category') {
        giftList.sort((a, b) => a['category'].compareTo(b['category']));
      }
    });
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
            ],
          ),
        );
      },
    );
  }



  void _showGiftDialog({Map<String, dynamic>? gift}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController =
    TextEditingController(text: gift?['name']);
    final TextEditingController _descriptionController =
    TextEditingController(text: gift?['description']);
    final TextEditingController _priceController =
    TextEditingController(text: gift?['price']?.toString());
    final TextEditingController _categoryController =
    TextEditingController(text: gift?['category']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(gift == null ? 'Add New Gift' : 'Edit Gift'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Gift Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a gift name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(labelText: 'Category'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _submitGift(
                      _nameController.text,
                      _descriptionController.text,
                      _priceController.text,
                      _categoryController.text,
                      giftId: gift?['id']);
                  Navigator.of(context).pop();
                }
              },
              child: Text(gift == null ? 'Add' : 'Update'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Gift List for Event'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showGiftDialog(),
          ),
        ],
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : giftList.isEmpty
          ? Center(child: Text('No gifts available for this event.'))
          : ListView.builder(
        itemCount: giftList.length,
        itemBuilder: (context, index) {
          final gift = giftList[index];
          return Card(
            color: Colors.lightBlue[50],
            elevation: 4.0,
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(gift['name']),
              subtitle: Text(
                'Description: ${gift['description']}\n'
                    'Price: \$${gift['price'].toString()}\n'
                    'Category: ${gift['category']}',
              ),
              trailing: Wrap(
                spacing: 12, // space between actions
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showGiftDialog(gift: gift),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteGift(gift['id']),
                  ),
                ],
              ),
              onTap: () => _showGiftDetails(gift),
            ),
          );
        },
      ),
    );
  }
}