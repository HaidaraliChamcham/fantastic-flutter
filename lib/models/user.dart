import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class User with ChangeNotifier{
  final String id;
  final String profileName;
  final String username;
         String url;
  final String coverImage;
  final String email;
  final String bio;

  User({
   @required this.id,
   @required this.profileName,
   @required this.username,
    this.url,
    this.coverImage,
   @required this.email,
    this.bio
    });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc.documentID,
      email: doc.data['email'],
      username: doc.data['username'],
      url: doc.data['url'],
      coverImage: doc.data['coverImage'],
      profileName: doc.data['profileName'],
      bio: doc.data['bio'],
    );
  }
}
class  Users extends ChangeNotifier {
  List<User> _userList= [];

List<User> get userList{
  return [..._userList];
}

void addUser(){
  notifyListeners();
}
}