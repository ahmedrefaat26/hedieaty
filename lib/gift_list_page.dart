import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          .where('eventId', isEqualTo: widget.eventId)
          .get();

      setState(() {
        giftList = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching gifts: $e')));
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
      await FirebaseFirestore.instance
          .collection('gifts')
          .doc(giftId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gift deleted successfully!')));
      _fetchGifts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting gift: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showGiftDialog({Map<String, dynamic>? gift}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController = TextEditingController(text: gift?['name']);
    final TextEditingController _descriptionController = TextEditingController(text: gift?['description']);
    final TextEditingController _priceController = TextEditingController(text: gift?['price']?.toString());
    final TextEditingController _categoryController = TextEditingController(text: gift?['category']);

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
                      giftId: gift?['id']
                  );
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

  Future<void> _submitGift(String name, String description, String price, String category, {String? giftId}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> giftData = {
      'name': name,
      'description': description,
      'price': double.parse(price),
      'category': category,
      'eventId': widget.eventId,
    };

    try {
      if (giftId == null) {
        await FirebaseFirestore.instance
            .collection('gifts')
            .add(giftData);
      } else {
        await FirebaseFirestore.instance
            .collection('gifts')
            .doc(giftId)
            .update(giftData);
      }
      _fetchGifts();  // Refresh gift list after adding/updating
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gift ${giftId == null ? 'added' : 'updated'} successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding/updating gift: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gift List for Event'),
        actions: <Widget>[
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
          return ListTile(
            title: Text(giftList[index]['name']),
            subtitle: Text('${giftList[index]['description']} - \$${giftList[index]['price']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showGiftDialog(gift: giftList[index]),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteGift(giftList[index]['id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
