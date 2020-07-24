import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import './pages/home/tabs.dart';
import './pages/upload.dart';
import './pages/notify.dart';
import './pages/userProfile/user_profile.dart';
import './widgets/progress_indicator.dart';
import './pages/trending/trending.dart';
import './auth/auth.dart';
import './models/user.dart';

final usersReference = Firestore.instance.collection("users");
final postsReference = Firestore.instance.collection("posts");
final activityFeedReference = Firestore.instance.collection("feed");
final commentsReference = Firestore.instance.collection('comments');
final friendsReference = Firestore.instance.collection('friends');
final followersReference = Firestore.instance.collection('followers');
final followingReference = Firestore.instance.collection('following');
final followTimelineReference = Firestore.instance.collection('followTimeline');
final friendTimelineReference = Firestore.instance.collection('friendTimeline');
final allPostTimelineReference = Firestore.instance.collection('allPostTimeline');

final StorageReference storageReference = FirebaseStorage.instance.ref().child('Posts Picture');
final StorageReference profileStorageReference = FirebaseStorage.instance.ref().child('Profile Picture');
final StorageReference coverImageStorageReference = FirebaseStorage.instance.ref().child('Cover Image');
final DateTime timestamp = DateTime.now();
 User currentUser;
class HomePage extends StatefulWidget {
  final String currentUserId;
  final BaseAuth auth;
  final VoidCallback onSignedOut;
 HomePage({Key key,this.auth,this.onSignedOut, this.currentUserId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {



  saveUserInfoToFireStore() async{
    String userId = await widget.auth.currentUser();
       DocumentSnapshot documentSnapshot = await usersReference.document(userId).get();
           if(mounted)setState(() {
             currentUser = User.fromDocument(documentSnapshot);
           });
  }

  PageController pageController;

  int getPageIndex = 0;

  void initState() {
    super.initState();
    saveUserInfoToFireStore();
    pageController = PageController();

  }
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  whenPageChanges(int index) {
    this.getPageIndex = index;
  }
  onTabChangePage(int index) {
    setState(() {
      getPageIndex = index;
    });
    pageController.animateToPage(
      index,
      duration: Duration(
        milliseconds: 100,
      ),
      curve: Curves.easeIn,
    );
  }

bool get _fecthingData => currentUser == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _fecthingData ? Center(child: circularProgress(),)
      // currentUser == null ?
      // Container(child: circularProgress(),)
      :
      PageView(
          controller: pageController,
          children: <Widget>[
           Home(currentUser: currentUser),
            Trending(),
            UploadImage(gCurrentUser: currentUser),
            NotificationsPage(),
            ProfilePage(userProfileId: currentUser?.id,),
          ],
          onPageChanged: (int index) {
            setState(() {
              getPageIndex = index;
            });
          },
          physics: NeverScrollableScrollPhysics(),
          ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
        currentIndex: getPageIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: onTabChangePage,
        items:[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            title: Text('Trending'),
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera),
            title: Text('Camera'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            title: Text('Notify'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Profile'),
          ),
        ],
        elevation: 0.5,
      ),
    );
  }
}
