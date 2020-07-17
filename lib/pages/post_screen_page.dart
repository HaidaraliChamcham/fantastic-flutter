import 'package:flutter/material.dart';
import '../widgets/post_widget.dart';
import '../home_page.dart';
import '../widgets/progress_indicator.dart';

class PostScreenPage extends StatelessWidget {
  final String postId;
  final String userId;

  PostScreenPage({this.postId, this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: postsReference.document(userId).collection('usersPosts').document(postId).snapshots(),
      builder: (BuildContext context, dataSnapshot)
       {
        if (!dataSnapshot.hasData)
        {
          return circularProgress();
        }
        Post post = Post.fromDocument(dataSnapshot.data);

        return Scaffold(
          body: ListView(
            children: <Widget>[
              Container(
                child: post,
              ),
            ],
          ),
        );
      },
    );
  }
}
