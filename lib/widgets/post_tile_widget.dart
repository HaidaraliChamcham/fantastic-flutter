import 'package:flutter/material.dart';
import '../pages/post_screen_page.dart';
import './post_widget.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);

  displayFullPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                PostScreenPage(postId: post.postId, userId: post.ownerId)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
       onTap: () => displayFullPost(context),
          child: GridTile(
        child: Image.network(
          post.url,
          fit: BoxFit.cover,
        ),
        footer: Padding(
          padding: const EdgeInsets.all(8.0),
          child: (Text(
            post.caption == null ? '' : post.caption.trim(),
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )),
        ),
      ),
    );
  }
}
