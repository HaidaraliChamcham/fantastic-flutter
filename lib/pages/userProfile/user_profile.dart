import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './edit_profile_page.dart';
import '../../widgets/post_tile_widget.dart';
import '../../widgets/post_widget.dart';
import '../../models/user.dart';
import '../../widgets/progress_indicator.dart';
import '../../home_page.dart';

class ProfilePage extends StatefulWidget {
  final String userProfileId;
  final Post post;
  ProfilePage({this.userProfileId, this.post});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String currentOnlineUserId = currentUser?.id;

  bool loading = false;
  int countPost = 0;
  List<Post> postsList = [];
  String postOrientation = "grid";
  int countTotalFollowers = 0;
  int countTotalFriends = 0;
  int countTotalFollowings = 0;

  bool friends = false;
  bool following = false;

  void initState() {
    super.initState();
    getAllProfilePosts();
    getAllFriends();
    getAllFollowers();
    getAllFollowings();
    checkIfAlreadyFriends();
    checkIfAlreadyFollowing();
  }

  getAllFollowings() async {
    QuerySnapshot querySnapshot = await followingReference
        .document(widget.userProfileId)
        .collection('userFollowing')
        .getDocuments();
    if (mounted)
      setState(() {
        countTotalFollowings = querySnapshot.documents.length;
      });
  }

  getAllFollowers() async {
    QuerySnapshot querySnapshot = await followersReference
        .document(widget.userProfileId)
        .collection('userFollowers')
        .getDocuments();
    if (mounted)
      setState(() {
        countTotalFollowers = querySnapshot.documents.length;
      });
  }

  getAllFriends() async {
    QuerySnapshot querySnapshot = await friendsReference
        .document(widget.userProfileId)
        .collection('userFriends')
        .getDocuments();
    if (mounted)
      setState(() {
        countTotalFriends = querySnapshot.documents.length;
      });
  }

  checkIfAlreadyFriends() async {
    DocumentSnapshot documentSnapshot = await friendsReference
        .document(widget.userProfileId)
        .collection('userFriends')
        .document(currentOnlineUserId)
        .get();
    if (this.mounted)
      setState(() {
        friends = documentSnapshot.exists;
      });
  }

  checkIfAlreadyFollowing() async {
    DocumentSnapshot documentSnapshot = await followersReference
        .document(widget.userProfileId)
        .collection('userFollowers')
        .document(currentOnlineUserId)
        .get();
    if (this.mounted)
      setState(() {
        following = documentSnapshot.exists;
      });
  }

  createProfileTopView() {
    return StreamBuilder(
      stream: usersReference.document(widget.userProfileId).snapshots(),
      builder: (BuildContext context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        return Column(children: <Widget>[
          Container(
            child: CachedNetworkImage(
              imageUrl: user.url == null ?'' : user.url,
              imageBuilder: (context, imageProvider) => Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: imageProvider,
                    ),
                    border: Border.all(
                        color: Theme.of(context).primaryColor, width: 5.0)),
              ),
              placeholder: (context, url) => CircleAvatar(backgroundColor: Colors.grey,radius: 75.0,),
              errorWidget: (context, url, error) => Icon(Icons.account_circle, size: 200,color: Colors.grey,),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17.0),
            child: Column(
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  child: Text(user.username,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                      )),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    user.profileName,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(
                  height: 5.0,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 5.0),
                  child: Text(
                    user.bio == null ? '' : user.bio,
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Container(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      createColumns('Uploads', countPost),
                      createColumns('Friends', countTotalFriends),
                      createColumns('Followers', countTotalFollowers),
                      createColumns('Following', countTotalFollowings),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    createFriendButton(),
                    createFollowButton(),
                  ],
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }

  Column createColumns(String title, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
              fontSize: 15.0, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.all(5.0),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 15.0,
                color: Colors.grey,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  createFriendButton() {
    bool ownProfile = currentOnlineUserId == widget.userProfileId;
    if (ownProfile) {
      return SizedBox();
    } else if (friends) {
      return createButtonTitleAndFunctionForFriend(
        title: 'Friends',
        performFunctionForFriend: () => _showWarningDialogForFriend(context),
      );
    } else if (!friends) {
      return createButtonTitleAndFunctionForFriend(
        title: 'Add Friend',
        performFunctionForFriend: controlAddFriendUser,
      );
    }
  }

  _showWarningDialogForFriend(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Are you sure you want to UnFriend ?'),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    'Un Friend',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  onPressed: () async {
                    await controlUnfriendUser();
                    Navigator.pop(context);
                  }),
              FlatButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  controlUnfriendUser() async {
    setState(() {
      friends = false;
    });
    friendsReference
        .document(widget.userProfileId)
        .collection('userFriends')
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    friendsReference
        .document(currentOnlineUserId)
        .collection('userFriends')
        .document(widget.userProfileId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });

    activityFeedReference
        .document(widget.userProfileId)
        .collection('feedItems')
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    await getAllFriends();
  }

  controlAddFriendUser() async {
    setState(() {
      friends = true;
    });
    friendsReference
        .document(widget.userProfileId)
        .collection('userFriends')
        .document(currentOnlineUserId)
        .setData({});

    friendsReference
        .document(currentOnlineUserId)
        .collection('userFriends')
        .document(widget.userProfileId)
        .setData({});

    activityFeedReference
        .document(widget.userProfileId)
        .collection('feedItems')
        .document(currentOnlineUserId)
        .setData({
      'type': 'friend',
      'ownerId': widget.userProfileId,
      'username': currentUser.username,
      'profileName': currentUser.profileName,
      'timestamp': DateTime.now(),
      'userProfileImg': currentUser.url,
      'userId': currentOnlineUserId,
    });
    await getAllFriends();
  }

  createFollowButton() {
    bool ownProfile = currentOnlineUserId == widget.userProfileId;
    if (ownProfile) {
      return SizedBox();
    } else if (following) {
      return createButtonTitleAndFunction(
        title: 'Following',
        performFunction: () {
          showWarningDialog(context);
        },
      );
    } else if (!following) {
      return createButtonTitleAndFunction(
        title: 'Follow',
        performFunction: () async {
          await controlFollowUser();
        },
      );
    }
    return SizedBox();
  }

  showWarningDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Are you sure you want to Unfollow ?'),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    'Unfollow',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  onPressed: () async {
                    await controlUnfollowUser(); // await controlUnfollowUser();
                    Navigator.pop(context);
                  }),
              FlatButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  controlUnfollowUser() async {
    setState(() {
      following = false;
    });
    followersReference
        .document(widget.userProfileId)
        .collection('userFollowers')
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    followingReference
        .document(currentOnlineUserId)
        .collection('userFollowing')
        .document(widget.userProfileId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    activityFeedReference
        .document(widget.userProfileId)
        .collection('feedItems')
        .document(currentOnlineUserId)
        .get()
        .then((document) {
      if (document.exists) {
        document.reference.delete();
      }
    });
    await getAllFollowers();
  }

  controlFollowUser() async {
    setState(() {
      following = true;
    });
    followersReference
        .document(widget.userProfileId)
        .collection('userFollowers')
        .document(currentOnlineUserId)
        .setData({});

    followingReference
        .document(currentOnlineUserId)
        .collection('userFollowing')
        .document(widget.userProfileId)
        .setData({});

    activityFeedReference
        .document(widget.userProfileId)
        .collection('feedItems')
        .document(currentOnlineUserId)
        .setData({
      'type': 'follow',
      'ownerId': widget.userProfileId,
      'username': currentUser.username,
      'profileName': currentUser.profileName,
      'timestamp': DateTime.now(),
      'userProfileImg': currentUser.url,
      'userId': currentOnlineUserId,
    });
    await getAllFollowers();
  }

  Container createButtonTitleAndFunction(
      {String title, Function performFunction}) {
    return Container(
      padding: EdgeInsets.only(top: 3.0),
      child: ButtonTheme(
        minWidth: 150.0,
        child: RaisedButton(
          onPressed: performFunction,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          color: following ? Colors.green : Theme.of(context).primaryColor,
          textColor: Theme.of(context).primaryTextTheme.button.color,
        ),
      ),
    );
  }

  Container createButtonTitleAndFunctionForFriend(
      {String title, Function performFunctionForFriend}) {
    return Container(
      padding: EdgeInsets.only(top: 3.0),
      child: ButtonTheme(
        minWidth: 150.0,
        child: RaisedButton(
          onPressed: performFunctionForFriend,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          color: friends ? Colors.green : Theme.of(context).primaryColor,
          textColor: Theme.of(context).primaryTextTheme.button.color,
        ),
      ),
    );
  }

  editUserProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SettingScreen())); //  EditProfilePage(currentOnlineUserId: currentOnlineUserId)
  }

  getEditButton() {
    bool ownProfile = currentOnlineUserId == widget.userProfileId;
    if (ownProfile) {
      return FlatButton(
        child: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        onPressed: editUserProfile,
      );
    } else {
      return SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        backgroundColor: Colors.white,
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[getEditButton()],
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(height: 2.5,),
          createProfileTopView(),
          Divider(),
          createListAndGridPostOrientation(),
          displayProfilePost(),
        ],
      ),
    );
  }

  displayProfilePost() {
    if (loading) {
      return circularProgress();
    } else if (postsList.isEmpty) {
      return Container(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.photo,
                  color: Colors.grey,
                  size: 15.0,
                ),
                Text(
                  ' No Uploads',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15.0,
                  ),
                ),
              ]),
        ),
      );
    }
    //  else if (postOrientation == "grid") {
    List<GridTile> gridTilesList = [];
    postsList.forEach((eachPost) {
      gridTilesList.add(
        GridTile(
          child: PostTile(eachPost),
        ),
        //     GridTile(
        //   child: InkWell(
        //       onTap: () {
        //         postTileColumnView();
        //       },
        //       child: PostTile(eachPost)),
        // ),
      );
    });

    return GridView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: gridTilesList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 5,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        primary: false,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (ctx, i) => gridTilesList[i]);
    // } else if (postOrientation == "list") {
    //   return Column(
    //     children: postsList,
    //   );
    // }
  }

  // postTileColumnView() {
  //   return SingleChildScrollView(
  //     child: Column(children: postsList),
  //   );
  // }

  getAllProfilePosts() async {
    setState(() {
      loading = true;
    });
    QuerySnapshot querySnapshot = await postsReference
        .document(widget.userProfileId)
        .collection('usersPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    if (this.mounted)
      setState(() {
        loading = false;
        countPost = querySnapshot.documents.length;
        postsList = querySnapshot.documents
            .map((documentSnapshot) => Post.fromDocument(documentSnapshot))
            .toList();
      });
  }

  createListAndGridPostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Uploads',
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 20.0,
              fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 10.0,
        )
      ],
    );
  }

  // setOrientation(String orientation) {
  //   setState(() {
  //     this.postOrientation = orientation;
  //   });
  // }
}
