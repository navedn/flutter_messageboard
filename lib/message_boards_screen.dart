import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageBoardsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> messageBoards = [
    {'name': 'General Chat', 'icon': Icons.chat, 'id': 'general'},
    {
      'name': 'Announcements',
      'icon': Icons.announcement,
      'id': 'announcements'
    },
    {'name': 'Feedback', 'icon': Icons.feedback, 'id': 'feedback'},
  ]; // Hardcoded message boards

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message Boards'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Navigation', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Message Boards'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.of(context).pushNamed('/settings');
              },
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: messageBoards.length,
        itemBuilder: (context, index) {
          final board = messageBoards[index];
          return ListTile(
            leading: Icon(board['icon']),
            title: Text(board['name']),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                      boardName: board['name'], boardId: board['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final String boardName;
  final String boardId;

  ChatScreen({required this.boardName, required this.boardId});

  final CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('messages');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(boardName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _messagesCollection
            .doc(boardId)
            .collection('chat')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No messages yet.'));
          }
          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                title: Text(message['username']),
                subtitle: Text(message['message']),
                trailing: Text(
                  DateTime.fromMillisecondsSinceEpoch(message['timestamp'])
                      .toLocal()
                      .toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Type a message',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) async {
                  if (value.isNotEmpty) {
                    await _messagesCollection
                        .doc(boardId)
                        .collection('chat')
                        .add({
                      'username': 'Anonymous', // Replace with actual username
                      'message': value,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                    });
                  }
                },
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                // Optionally handle send button press if needed
              },
            ),
          ],
        ),
      ),
    );
  }
}
