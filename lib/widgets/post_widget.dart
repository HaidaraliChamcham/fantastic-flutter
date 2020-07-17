import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasenate/fasenate_icons_icons.dart';
import 'package:fasenate/pages/commets_page.dart';
import 'package:fasenate/pages/userProfile/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import '../home_page.dart';
import '../models/user.dart';
import '../widgets/progress_indicator.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final dynamic likes;
  final String username;
  final String profileName;
  final String caption;
  final String url;

  Post({
    this.postId,
    this.ownerId,
    this.likes,
    this.username,
    this.profileName,
    this.caption,
    this.url,
  });

  factory Post.fromDocument(DocumentSnapshot documentSnapshot) {
    return Post(
      postId: documentSnapshot['postId'],
      ownerId: documentSnapshot['ownerId'],
      likes: documentSnapshot['likes'],
      username: documentSnapshot['username'],
      profileName: documentSnapshot['profileName'],
      caption: documentSnapshot['caption'],
      url: documentSnapshot['url'],
    );
  }

  int getTotalNumberOfLikes(likes) {
    if (likes == null) {
      return 0;
    }
    int counter = 0;
    likes.values.forEach((eachValue) {
      if (eachValue == true) {
        counter = counter + 1;
      }
    });
    return counter;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        likes: this.likes,
        username: this.username,
        profileName: this.profileName,
        caption: this.caption,
        url: this.url,
        likeCount: getTotalNumberOfLikes(this.likes),
      );
}

class _PostState extends State<Post> {
  final String postId;
  final String ownerId;
  Map likes;
  final String username;
  final String profileName;
  final String caption;
  final String url;
  int likeCount;
  bool isLiked;
  bool showHeart = false;
  final String currentOnlineUserId = currentUser?.id;

  _PostState({
    this.postId,
    this.ownerId,
    this.likes,
    this.username,
    this.profileName,
    this.caption,
    this.url,
    this.likeCount,
  });

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentOnlineUserId] == true);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          createPostHead(),
          createPostPicture(),
          SizedBox(
            height: 5.0,
          ),
          createPostFooter(),
        ],
      ),
    );
  }

  createPostHead() {
    return StreamBuilder(
      stream: usersReference.document(ownerId).snapshots(),
      builder: (context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        bool isPostOwner = currentOnlineUserId == ownerId;

        return Stack(
          children: <Widget>[
            Container(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://pbs.twimg.com/profile_images/954970943255818240/ycI3A-DK_400x400.jpg'), //backgroundImage: CachedNetworkImageProvider(user.url),
                  backgroundColor: Colors.grey,
                ),
                title: GestureDetector(
                  onTap: () => displayUserProfile(context, userProfileId: user.id),
                  child: Text(
                    user.profileName,
                    style:
                        TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                trailing: isPostOwner
                    ? IconButton(
                        icon: Icon(
                          Icons.more_horiz,
                        ),
                        onPressed: () => controlPostDelete(context),
                      )
                    : Text(''),
              ),
            ),
          ],
        );
      },
    );
  }

  controlPostDelete(BuildContext mContext) {
    return showDialog(
        context: mContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('What do you want ?'),
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  removeUserPost();
                },
              ),
              SimpleDialogOption(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  removeUserPost() async {
    postsReference
        .document(ownerId)
        .collection('usersPosts')
        .document(postId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    storageReference.child('post_$postId.jpg').delete();
    QuerySnapshot querySnapshot = await activityFeedReference
        .document(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .getDocuments();
    querySnapshot.documents.forEach((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    QuerySnapshot commentQuerySnapshot = await commentsReference.document(postId).collection('comments')
      .getDocuments();
      commentQuerySnapshot.documents.forEach((document) {
        if(document.exists){
          document.reference.delete();
        }
       });
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

  removeLike() {
    bool isNotPostOwner = currentOnlineUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedReference
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get()
          .then((document) {
        if (document.exists) {
          document.reference.delete();
        }
      });
    }
  }

  addLike() {
    bool isNotPostOwner = currentOnlineUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedReference
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'profileName': currentUser.profileName,
        'userId': currentUser.id,
        'timestamp': DateTime.now(),
        'url': url,
        'postId': postId,
        'userProfileImg': currentUser.url,
      });
    }
  }

  controlUserLikePost() {
    bool _liked = likes[currentOnlineUserId] == true;
    if (_liked) {
      postsReference
          .document(ownerId)
          .collection('usersPosts')
          .document(postId)
          .updateData({'likes.$currentOnlineUserId': false});
      removeLike();
      setState(() {
        likeCount = likeCount - 1;
        isLiked = false;
        likes[currentOnlineUserId] = false;
      });
    } else if (!_liked) {
      postsReference
          .document(ownerId)
          .collection('usersPosts')
          .document(postId)
          .updateData({'likes.$currentOnlineUserId': true});
      addLike();
      setState(() {
        likeCount = likeCount + 1;
        isLiked = true;
        likes[currentOnlineUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 800), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  createPostPicture() {
    return StreamBuilder(
        stream: usersReference.document(ownerId).snapshots(),
        builder: (context, dataSnapshot) {
          if (!dataSnapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(dataSnapshot.data);
          return GestureDetector(
            onDoubleTap: () => controlUserLikePost(),
            onHorizontalDragUpdate: (details) {
              if (details.delta.dx < 0) {
                displayUserProfile(context, userProfileId: user.id);
              }
            },
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Image.network(
                url,
                fit: BoxFit.cover,
              ),
            ),
          );
        });
  }

  createPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),
            ),
            Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () => controlUserLikePost(),
                  child: Icon(
                    Icons.favorite,
                    color: isLiked ? Colors.pink : Colors.grey,
                    size: 35.0,
                  ),
                ),
                Text(
                  '$likeCount likes',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.only(right: 20.0),
            ),
            GestureDetector(
              onTap: () => displayComments(context,
                  postId: postId, ownerId: ownerId, url: url),
              child: Icon(
                FasenateIcons.communications__2_,
                color: Colors.grey,
                size: 35.0,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                username,
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 10.0,
            ),
            Expanded(
              child: Text(
                caption == null ? '' : caption.trim(),
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }

  displayComments(BuildContext context,
      {String postId, String ownerId, String url}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return CommentsPage(
            postId: postId, postOwnerId: ownerId, postImageUrl: url);
      },
    ));
  }
  //   Widget animationBtn() {
  //   return LikeButton(
  //     size: 50,
  //     circleColor:
  //         CircleColor(start: Color(0xff00ddff), end: Color(0xff0099cc)),
  //     bubblesColor: BubblesColor(
  //       dotPrimaryColor: Color(0xff33b5e5),
  //       dotSecondaryColor: Color(0xff0099cc),
  //     ),
  //     likeBuilder: (bool isLiked) {
  //       return Icon(
  //         Icons.favorite,
  //         color: isLiked ? Colors.pink : Colors.grey,
  //         size: 40.0,
  //       );
  //     },
  //     likeCount: 0,
  //     countBuilder: (int count, bool isLiked, String text) {
  //       var color = isLiked ? Colors.deepPurpleAccent : Colors.grey;
  //       Widget result;
  //       if (count == 0) {
  //         result = Text(
  //           "like",
  //           style: TextStyle(color: color),
  //         );
  //       } else
  //         result = Text(
  //           text,
  //           style: TextStyle(color: color),
  //         );
  //       return result;
  //     },
  //   );
  // }
}
