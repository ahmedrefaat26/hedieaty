import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EventcreationPage.dart';
import 'profile_page.dart';
import 'event_list_page.dart';
import 'database/sqldb.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> friendswatch = [];  // List to store friends
  int _selectedIndex = 0;
  TextEditingController _textFieldController = TextEditingController();

  static List<Widget> _widgetOptions = <Widget>[
    EventCreationPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    fetchFriendsFromFirestore();  // Fetch friends when the page initializes
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _widgetOptions[index]),
    );
  }

  void _showAddFriendDialog() {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;  // Get current user's UID
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Friend"),
          content: Container(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text("Something went wrong");
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();  // Manually filter out the current user
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var user = docs[index].data() as Map<String, dynamic>;
                    String userName = user['name'] as String? ?? "Unknown";
                    return ListTile(
                      title: Text(userName),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          await addFriendToLocalAndFirestoreDatabase(user);
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        automaticallyImplyLeading: false,
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search functionality here
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventCreationPage()),
                );
              },
              child: Text('Create Your Own Event/List'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ),
          Expanded(
            child: friendswatch.isEmpty
                ? Center(child: Text("No friends to show."))
                : ListView.builder(
              itemCount: friendswatch.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(),
                  title: Text(friendswatch[index]['name'] ?? 'No Name'),
                  onTap: () {
                    String friendId = friendswatch[index]['friend_id']; // Get the friend's ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventListPage(friendId: friendId), // Pass friendId
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> addFriendToLocalAndFirestoreDatabase(Map<String, dynamic> userData) async {
    Database db = await DatabaseHelper.instance.database;
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Add to local database
    await db.insert('friends', {
      'user_id': currentUserId,
      'friend_id': userData['uid'],  // Assuming 'uid' is part of userData from Firestore
    });

    // Add to Firestore
    await FirebaseFirestore.instance.collection('friends').add({
      'user_id': currentUserId,
      'friend_id': userData['uid'],
      'name': userData['name'],  // Storing the friend's name in Firestore for easy access
    });

    print("Friend added to both local database and Firestore.");
    fetchFriendsFromFirestore();  // Refresh the friends list after adding a friend
  }

  Future<void> fetchFriendsFromFirestore() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance.collection('friends')
        .where('user_id', isEqualTo: currentUserId)
        .get();

    List<Map<String, dynamic>> friends = snapshot.docs.map((doc) => {
      'name': doc.data()['name'],  // Display name directly
      'friend_id': doc.data()['friend_id']  // Use friend_id for other operations if needed
    }).toList();

    setState(() {
      friendswatch = friends;  // Update the state to reflect the fetched data
    });
  }
}
