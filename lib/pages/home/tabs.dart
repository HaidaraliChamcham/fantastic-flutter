import 'package:fasenate/home_page.dart';
import 'package:fasenate/models/user.dart';
import 'package:fasenate/pages/home/follow_timeline.dart';
import 'package:fasenate/pages/home/friend_timeline.dart';
import 'package:fasenate/pages/home/suggested.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final User currentUser;
  Home({this.currentUser});
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {  
    return DefaultTabController(
      length: 3,
          child: Scaffold(
        appBar:
        TabBar(
          labelStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          labelPadding: EdgeInsets.only(top: 25.0),
          unselectedLabelStyle: TextStyle(fontSize: 15),
          unselectedLabelColor: Colors.black,
          labelColor: Theme.of(context).primaryColor,
          indicatorColor: Colors.transparent,
          tabs: [
            Tab(text: 'Friends'),
            Tab(text: 'Following'),
            Tab(text: 'Suggested',),
          ],
        ),
        body: new TabBarView(
          
           children: <Widget>[
          new FriendsTimeline(currentUser: currentUser),
          new FollowsTimeline(currentUser: currentUser),
          new Suggested(),
        ]),
      ),
    );
  }
}
