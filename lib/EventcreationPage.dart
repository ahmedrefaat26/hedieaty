import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database/sqldb.dart';
import 'database/eventsmodel.dart';

class EventCreationPage extends StatefulWidget {
  @override
  _EventCreationPageState createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? _eventDate;

  List<DocumentSnapshot> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      var snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('user_id', isEqualTo: userId)
          .get();

      setState(() {
        _events = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching events: $e'),
      ));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
        _dateController.text = '${_eventDate!.toLocal()}'.split(' ')[0];
      });
    }
  }

  Future<void> _saveEvent({String? eventId}) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Create an event with Firestore eventId and Firestore userId
      Map<String, dynamic> eventData = {
        'name': _eventNameController.text,
        'description': _descriptionController.text,
        'date': _eventDate,
        'location': _locationController.text,
        'user_id': userId,
      };
bool flag = eventId == null;
      if (flag) {
        // Add event to Firestore
        var ref = await FirebaseFirestore.instance.collection('events').add(eventData);
        eventId = ref.id; // Get the Firestore event ID
      } else {
        // Update the existing event in Firestore
        await FirebaseFirestore.instance.collection('events').doc(eventId).update(eventData);
      }

      // Save to local database (SQLite) with the event ID from Firestore
      EventModel event = EventModel(
        name: _eventNameController.text,
        description: _descriptionController.text,
        date: _eventDate.toString(),
        location: _locationController.text,
        userId: userId,
        eventId: eventId, // Use Firestore event ID
      );


      // If the event is new, insert it into the SQLite database
      await DatabaseHelper.instance.insertOrUpdateEvent(event);
      // If the event already exists, update it in the SQLite database

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(flag? 'Event created successfully!' : 'Event updated successfully!'),
      ));

      _fetchEvents();
      Navigator.pop(context);
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving event: $e'),
      ));
    }
  }

  void _clearForm() {
    _eventNameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _dateController.clear();
    setState(() {
      _eventDate = null;
    });
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      // Delete the event from Firestore
      await FirebaseFirestore.instance.collection('events').doc(eventId).delete();

      // Delete the event from the local SQLite database
      await DatabaseHelper.instance.deleteEvent(eventId);

      setState(() {
        _events.removeWhere((event) => event.id == eventId);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Event deleted successfully!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting event: $e'),
      ));
    }
  }


  void _showEventDetailsDialog([DocumentSnapshot? event]) {
    if (event != null) {
      _eventNameController.text = event['name'];
      _descriptionController.text = event['description'];
      _locationController.text = event['location'];
      _eventDate = (event['date'] as Timestamp).toDate();
      _dateController.text = '${_eventDate!.toLocal()}'.split(' ')[0];
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event != null ? 'Edit Event' : 'Create Event',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _eventNameController,
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an event name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Event Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value!.isEmpty) {
                        return 'Please enter an event description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: _eventDate == null ? 'Select Event Date' : 'Event Date: ${_eventDate!.toLocal()}'.split(' ')[0],
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (_eventDate == null) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Event Location',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||  value!.isEmpty) {
                        return 'Please enter an event location';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () => _saveEvent(eventId: event?.id),
                    child: Text(event != null ? 'Update Event' : 'Create Event'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event/List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showEventDetailsDialog(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Events',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  var event = _events[index];
                  return ListTile(
                    title: Text(event['name']),
                    subtitle: Text('Date: ${event['date'].toDate().toString().split(' ')[0]}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showEventDetailsDialog(event),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteEvent(event.id),
                        ),
                      ],
                    ),
                    onTap: () => _showEventDetailsDialog(event),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}