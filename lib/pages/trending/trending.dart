import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasenate/home_page.dart';
import 'package:fasenate/models/user.dart';
import 'package:fasenate/pages/trending/search.dart';
import 'package:fasenate/widgets/post_widget.dart';
import 'package:fasenate/widgets/progress_indicator.dart';
import 'package:fasenate/widgets/trending_tile.dart';
import 'package:flutter/material.dart';

class Trending extends StatefulWidget {
  final User currentUser;
  Trending({this.currentUser});
  @override
  _TrendingState createState() => _TrendingState();
}

class _TrendingState extends State<Trending> {
  bool loading = false;
  List<Post> postsList = [];

  void initState() {
    super.initState();
    getAllPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fantastic'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(child: displayPosts(),),
    );
  }
displayPosts(){
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
    List<GridTile> gridTilesList = [];
     postsList.forEach((eachPost) {
      gridTilesList.add(
        GridTile(
          child: TrendingTile(eachPost),
        ),
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
}
  getAllPosts() async {
    setState(() {
      loading = true;
    });
    QuerySnapshot querySnapshot = await postsReference
        .document(currentUser.id)
        .collection('usersPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    if (this.mounted) setState(() {
        loading = false;
        postsList = querySnapshot.documents
            .map((documentSnapshot) => Post.fromDocument(documentSnapshot))
            .toList();
      });
  }
}
