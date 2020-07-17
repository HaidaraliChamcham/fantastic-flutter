import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../home_page.dart';
import '../../models/user.dart';
import '../../widgets/post_widget.dart';
import '../../widgets/progress_indicator.dart';


class FollowsTimeline extends StatefulWidget {
  final User currentUser;
  FollowsTimeline({this.currentUser});
  @override
  _FollowsTimelineState createState() => _FollowsTimelineState();
}

class _FollowsTimelineState extends State<FollowsTimeline> {
  List<Post> posts;
  List<String> followList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  retriveFollowTimline() async {
    QuerySnapshot querySnapshot = await followTimelineReference
        .document(widget.currentUser.id)
        .collection('followTimelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    List<Post> allPosts = querySnapshot.documents
        .map((document) => Post.fromDocument(document))
        .toList();

    setState(() {
      this.posts = allPosts;
    });
  }

  retriveFollowing() async {
    QuerySnapshot querySnapshot = await followingReference
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    if(mounted) setState(() {
      followList = querySnapshot.documents
          .map((document) => document.documentID)
          .toList();
    });
  }

  createFollowTimeline() {
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
    retriveFollowTimline();
    retriveFollowing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
          child: createFollowTimeline(),
          onRefresh: () => retriveFollowTimline()),
    );
  }
}
