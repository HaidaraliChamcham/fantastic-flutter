import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasenate/pages/userProfile/user_profile.dart';
import 'package:fasenate/widgets/progress_indicator.dart';
import 'package:flutter/material.dart';
import '../../home_page.dart';
import '../../models/user.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin<SearchPage> {
  TextEditingController searchTextEditingController = TextEditingController();
  Future<QuerySnapshot> futureSearchResults;

  emptyTheTextField() {
    searchTextEditingController.clear();
  }

  controlSearching(String str) {
    Future<QuerySnapshot> allUsers = usersReference
        .where('profileName', isGreaterThanOrEqualTo: str)
        .getDocuments();
    setState(() {
      futureSearchResults = allUsers;
    });
  }

  AppBar searchPageHeader() {
    return AppBar(
      title: TextFormField(
        style: TextStyle(fontSize: 18, color: Colors.white),
        controller: searchTextEditingController,
        decoration: InputDecoration(
          hintText: 'Search user',
          hintStyle: TextStyle(color: Colors.white60),
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          focusedBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          filled: true,
          suffixIcon: IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.white,
            ),
            onPressed: emptyTheTextField,
          ),
        ),
        onFieldSubmitted: controlSearching,
      ),
    );
  }

  Container displayNoSearchResultScreen() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Icon(
              Icons.group,
              color: Colors.grey,
              size: 200.0,
            ),
            Text(
              'Search Users',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 35.0),
            ),
          ],
        ),
      ),
    );
  }

  displayUsersFoundScreen() {
    return FutureBuilder(
      future: futureSearchResults,
      builder: (context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return Center(
            child: circularProgress(),
          );
        }
        List<UserResult> searchUsersResult = [];
        dataSnapshot.data.documents.forEach((document) {
          User eachUser = User.fromDocument(document);
          UserResult userResult = UserResult(eachUser);
          searchUsersResult.add(userResult);
        });
        return ListView(children: searchUsersResult);
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: searchPageHeader(),
      
      body: futureSearchResults == null
          ? displayNoSearchResultScreen()
          : displayUsersFoundScreen(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User eachUser;
  UserResult(this.eachUser);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Container(
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: () =>
                  displayUserProfile(context, userProfileId: eachUser.id),
              child: ListTile(
                leading:
                    CachedNetworkImage(
              imageUrl: eachUser.url == null ?'' : eachUser.url,
              imageBuilder: (context, imageProvider) => Container(
                height: 45.0,
                width: 45.0,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: imageProvider,
                    ),
                ),
              ),
              // placeholder: (context, url) => CircleAvatar(backgroundImage: AssetImage('assets/sharukhKhan.jpg'),),
              errorWidget: (context, url, error) => Icon(Icons.account_circle,size: 45,color: Colors.grey,),
            ),
                // : CircleAvatar(
                //     backgroundColor: Colors.black,
                //     backgroundImage:
                //         CachedNetworkImageProvider(eachUser.url),
                //   ),
                title: Text(
                  eachUser.profileName,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  eachUser.username,
                  style: TextStyle(color: Colors.black, fontSize: 13.0),
                ),
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
