import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasenate/home_page.dart';
import 'package:fasenate/models/user.dart';
import 'package:fasenate/widgets/post_widget.dart';
import 'package:fasenate/widgets/progress_indicator.dart';
import 'package:flutter/material.dart';

class FriendsTimeline extends StatefulWidget {
  final User currentUser;
  FriendsTimeline({this.currentUser});
  @override
  _FriendsTimelineState createState() => _FriendsTimelineState();
}

class _FriendsTimelineState extends State<FriendsTimeline> {
  List<Post> posts;
   List<String> friendList = [];
   final _scaffoldKey = GlobalKey<ScaffoldState>();

 retriveFriendTimline() async {
    QuerySnapshot querySnapshot = await friendTimelineReference
        .document(widget.currentUser.id)
        .collection('friendTimelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    List<Post> allPosts = querySnapshot.documents
        .map((document) => Post.fromDocument(document))
        .toList();

    if(mounted) setState(() {
      this.posts = allPosts;
    });
  }

  retriveFriend() async {
    QuerySnapshot querySnapshot = await friendsReference
        .document(currentUser.id)
        .collection('userFriends')
        .getDocuments();
    if(mounted) setState(() {
      friendList = querySnapshot.documents
          .map((document) => document.documentID)
          .toList();
    });
  }

  createFriendTimeline() {
    if (posts == null) {
      return circularProgress();
    } else {
      return ListView.builder(
        itemBuilder: (context, i) {
          return posts[i];
        },
        itemCount: posts.length,
      );
    }
  }

    @override
  void initState() {
    super.initState();

    retriveFriendTimline();
    retriveFriend();
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
          child: createFriendTimeline(),
          onRefresh: () => retriveFriendTimline()),
    );
  }
}