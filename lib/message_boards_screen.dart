import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageBoardsScreen extends StatefulWidget {
  @override
  _MessageBoardsScreenState createState() => _MessageBoardsScreenState();
}

class _MessageBoardsScreenState extends State<MessageBoardsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _firstName;
  String? _lastName;
  bool _isLoading = true;

  final List<Map<String, dynamic>> messageBoards = [
    {'name': 'General Chat', 'icon': Icons.chat, 'id': 'general'},
    {
      'name': 'Announcements',
      'icon': Icons.announcement,
      'id': 'announcements'
    },
    {'name': 'Feedback', 'icon': Icons.feedback, 'id': 'feedback'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _firstName = data?['firstName'] ?? 'Unknown';
            _lastName = data?['lastName'] ?? 'User';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
    }
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome,',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  if (_isLoading)
                    CircularProgressIndicator(color: Colors.white)
                  else
                    Text(
                      '$_firstName $_lastName',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Message Boards'),
              onTap: () {
                Navigator.of(context).pop();
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
                    boardName: board['name'],
                    boardId: board['id'],
                    firstName: _firstName ?? 'Unknown',
                    lastName: _lastName ?? 'User',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String boardName;
  final String boardId;
  final String firstName;
  final String lastName;

  ChatScreen({
    required this.boardName,
    required this.boardId,
    required this.firstName,
    required this.lastName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('messages');

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      try {
        await _messagesCollection.doc(widget.boardId).collection('chat').add({
          'username': '${widget.firstName} ${widget.lastName}', // Full name
          'message': messageText,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _messageController.clear(); // Clear the input field after sending
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.boardName)),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesCollection
                  .doc(widget.boardId)
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
                        DateTime.fromMillisecondsSinceEpoch(
                                message['timestamp'])
                            .toLocal()
                            .toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input field and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
