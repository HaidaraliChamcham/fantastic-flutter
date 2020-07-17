import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasenate/pages/userProfile/user_profile.dart';
import 'package:fasenate/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tAgo;
import '../home_page.dart';
import '../widgets/progress_indicator.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;
  CommentsPage({this.postId, this.postOwnerId, this.postImageUrl});

  @override
  CommentsPageState createState() => CommentsPageState(
      postId: postId, postOwnerId: postOwnerId, postImageUrl: postImageUrl);
}

class CommentsPageState extends State<CommentsPage> {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;
  TextEditingController commentTextEditingController = TextEditingController();

  CommentsPageState({this.postId, this.postOwnerId, this.postImageUrl});

  void dispose() {
    super.dispose();
    commentTextEditingController.dispose();
  }

  displayComment() {
    return StreamBuilder(
      stream: commentsReference
          .document(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        dataSnapshot.data.documents.forEach((document) {
          comments.add(Comment.fromDocument(document));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  saveComment() {
    commentsReference.document(postId).collection('comments').add({
      'username': currentUser.username,
      'profileName': currentUser.profileName,
      'comment': commentTextEditingController.text,
      'timestamp': DateTime.now(),
      'url': currentUser.url,
      'userId': currentUser.id,
    });
    bool isNotPostOwner = postOwnerId != currentUser.id;
    if (isNotPostOwner) {
      activityFeedReference.document(postOwnerId).collection('feedItems').add({
        'type': 'comment',
        'commentData': commentTextEditingController.text,
        'postId': postId,
        'userId': currentUser.id,
        'username': currentUser.username,
        'profileName': currentUser.profileName,
        'userProfileImg': currentUser.url,
        'url': postImageUrl,
        'timestamp': DateTime.now(),
      });
    }
    commentTextEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: 'Comment', disappearedBackButton: true),
      body: Column(
        children: <Widget>[
          Expanded(
            child: displayComment(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentTextEditingController,
              decoration: InputDecoration(
                labelText: 'Write comment here',
              ),
              style: TextStyle(color: Colors.black),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: saveComment,
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String profileName;
  final String userId;
  final String url;
  final String comment;
  final Timestamp timestamp;

  Comment(
      {this.username,
      this.profileName,
      this.userId,
      this.url,
      this.comment,
      this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot documentSnapshot) {
    return Comment(
      username: documentSnapshot['username'],
      profileName: documentSnapshot['profileName'],
      userId: documentSnapshot['userId'],
      url: documentSnapshot['url'],
      comment: documentSnapshot['comment'],
      timestamp: documentSnapshot['timestamp'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.0),
      child: Container(
        child: Column(
          children: <Widget>[
            ListTile(
              title: GestureDetector(
                onTap: () => displayUserProfile(context, userProfileId: userId),
                child: Text(
                  username + " :   " + comment,
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.black,
                  ),
                ),
              ),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://pbs.twimg.com/media/EYFEmM0UMAAMVaV?format=jpg&name=240x240'), //CachedNetworkImageProvider(url),
              ),
              subtitle: Text(
                tAgo.format(timestamp.toDate()),
                style: TextStyle(color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }

  displayUserProfile(BuildContext context, {String userProfileId}) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            userProfileId: userProfileId,
          ),
        ));
  }
}
