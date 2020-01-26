import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = Firestore.instance;
  String message;
  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user == null) {
        _auth.signOut();
        Navigator.pop(context);
      } else {
        currentUser = user;
      }
    } catch (e) {
      _auth.signOut();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder(
              stream: _firestore.collection("messages").snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  final List<MessageBubble> widgets = [];
                  for (var document in snapshot.data.documents) {
                    final sender = document.data["sender"];
                    final text = document.data["text"];
                    widgets.add(MessageBubble(
                      message: text,
                      sender: sender,
                      isMe: sender == currentUser.email,
                    ));
                  }
                  return Expanded(
                    child: ListView(
                      children: widgets,
                    ),
                  );
                }
                return Container();
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      _firestore
                          .collection("messages")
                          .add({"text": message, "sender": currentUser.email});
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final String sender;
  final bool isMe;

  MessageBubble({this.message, this.sender, this.isMe});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(
              height: 4.0,
            ),
            Material(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(isMe ? 0 : 30.0),
                topLeft: Radius.circular(isMe ? 30.0 : 0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
              color: isMe ? Colors.lightBlue : Colors.grey,
              elevation: 5.0,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                ),
              ),
            )
          ],
        ),
      );
}
