import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tAgo;
import '../pages/post_screen_page.dart';
import '../widgets/progress_indicator.dart';
import '../home_page.dart';
import '../pages/userProfile/user_profile.dart';
import '../widgets/header_widget.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final String currentOnlineUserId = currentUser?.id;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: 'Notifications'),
      body: Container(
        child: FutureBuilder(
          future: retriveNotifications(),
          builder: (context, dataSnapshot) {
            if (!dataSnapshot.hasData) {
              return circularProgress();
            }
            return ListView(children: dataSnapshot.data);
          },
        ),
      ),
    );
  }

  retriveNotifications() async {
    QuerySnapshot querySnapshot = await activityFeedReference
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(80)
        .getDocuments();
    List<NotificationsItem> notificationsItems = [];
    querySnapshot.documents.forEach((document) {
      notificationsItems.add(NotificationsItem.fromDocument(document));
    });

    return notificationsItems;
  }
}

String notificationItemText;
Widget mediaPreview;

class NotificationsItem extends StatelessWidget {
  final String username;
  final String profileName;
  final String type;
  final String commentData;
  final String postId;
  final String userId;
  final String userProfileImg;
  final String url;
  final Timestamp timestamp;

  NotificationsItem({
    this.username,
    this.profileName,
    this.type,
    this.commentData,
    this.postId,
    this.userId,
    this.userProfileImg,
    this.url,
    this.timestamp,
  });

  factory NotificationsItem.fromDocument(DocumentSnapshot documentSnapshot) {
    return NotificationsItem(
      username: documentSnapshot['username'],
      profileName: documentSnapshot['profileName'],
      type: documentSnapshot['type'],
      commentData: documentSnapshot['commentData'],
      postId: documentSnapshot['postId'],
      userId: documentSnapshot['userId'],
      userProfileImg: documentSnapshot['userProfileImg'],
      url: documentSnapshot['url'],
      timestamp: documentSnapshot['timestamp'],
    );
  }
  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        child: ListTile(
          title: GestureDetector(
            onTap: () => displayUserProfile(context, userProfileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.0,
                  ),
                  children: [
                    TextSpan(
                        text: '$username  ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '$notificationItemText'),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: AssetImage("assets/sharukhKhan.jpg"),
          ),
          subtitle: Text(
            tAgo.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == 'comment' || type == 'like') {
      mediaPreview = GestureDetector(
        onTap: () => displayFullPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.cover, image: CachedNetworkImageProvider(url)),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }
    if (type == 'like') {
      notificationItemText = 'liked your post.';
    } else if (type == 'comment') {
      notificationItemText = 'commented :  $commentData';
    } else if (type == 'friend') {
      notificationItemText = 'become your friend.';
    } else if (type == 'follow') {
      notificationItemText = 'started following you.';
    } else {
      notificationItemText = 'Error, Unknown type = $type';
    }
  }

  displayFullPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostScreenPage(userId: userId, postId: postId),
        ));
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
