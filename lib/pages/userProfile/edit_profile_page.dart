import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../widgets/header_widget.dart';
import '../../home_page.dart';
import '../../utils/lowercase_formater.dart';
import '../../widgets/progress_indicator.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  TextEditingController profileNameTextEditingController;
  TextEditingController usernameTextEditingController;
  TextEditingController bioTextEditingController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPreferences preferences;
  String id = '';
  String profileName = '';
  String username = '';
  String url = '';
  String coverImage = '';
  String bio = '';
  bool _bioValid = true;
  bool _profileNameValid = true;
  bool _usernameValid = true;
  File imageFileAvatar;
  bool isLoading = false;
  final FocusNode profileNameFocusNode = FocusNode();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode bioFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    readDataFromLocal();
  }

  void dispose() {
    super.dispose();
    profileNameFocusNode.dispose();
    usernameFocusNode.dispose();
    bioFocusNode.dispose();
    profileNameTextEditingController.dispose();
    usernameTextEditingController.dispose();
    bioTextEditingController.dispose();
  }

  readDataFromLocal() async {
    preferences = await SharedPreferences.getInstance();
    id = preferences.getString('id');
    profileName = preferences.getString('profileName');
    username = preferences.getString('username');
    url = preferences.getString('url');
    coverImage = preferences.getString('coverImage');
    bio = preferences.getString('bio');

    profileNameTextEditingController = TextEditingController(text: profileName);
    usernameTextEditingController = TextEditingController(text: username);
    bioTextEditingController = TextEditingController(text: bio);
    setState(() {});
  }

  Future getImage() async {
    File newImageFile =
        await ImagePicker.pickImage(source: ImageSource.gallery);
    if (newImageFile != null) {
      setState(() {
        this.imageFileAvatar = newImageFile;
        isLoading = true;
      });
    }
    uploadImageToFirestoreAndStorage();
  }

  Future uploadImageToFirestoreAndStorage() async {
    String mFileName = id;
    StorageUploadTask storageUploadTask =
        profileStorageReference.child(mFileName).putFile(imageFileAvatar);
    StorageTaskSnapshot storageTaskSnapshot;
    storageUploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((newImageDownloadUrl) {
          url = newImageDownloadUrl;
          usersReference.document(id).updateData({
            'url': url,
            'coverImage': coverImage,
            'username': username,
            'profileName': profileName,
            'bio': bio,
          }).then((data) async {
            await preferences.setString('url', url);
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: 'Updated Successfully.');
          });
        }, onError: (errorMsg) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: 'Error Occured in getting Download Url.');
        });
      }
    }, onError: (errorMsg) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: errorMsg.toString());
    });
  }

  void updateUserData() {
    setState(() {
      profileNameTextEditingController.text.trim().length < 3 ||
              profileNameTextEditingController.text.isEmpty
          ? _profileNameValid = false
          : _profileNameValid = true;
      usernameTextEditingController.text.trim().length < 3 ||
              usernameTextEditingController.text.isEmpty
          ? _usernameValid = false
          : _usernameValid = true;

      bioTextEditingController.text.trim().length > 111
          ? _bioValid = false
          : _bioValid = true;
    });
    profileNameFocusNode.unfocus();
    usernameFocusNode.unfocus();
    bioFocusNode.unfocus();
    setState(() {
      isLoading = false;
    });

    if (_bioValid && _profileNameValid && _usernameValid) {
      usersReference.document(id).updateData({
        'url': url,
        'coverImage': coverImage,
        'username': username,
        'profileName': profileName,
        'bio': bio,
      }).then((data) async {
        await preferences.setString('url', url);
        await preferences.setString('coverImage', coverImage);
        await preferences.setString('username', username);
        await preferences.setString('profileName', profileName);
        await preferences.setString('bio', bio);
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Updated Successfully.',
          backgroundColor: Colors.grey[800],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: 'Edit Profile'),
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    child: Center(
                      child: Stack(alignment: Alignment.bottomLeft,
                        overflow: Overflow.visible,
                        children: <Widget>[
                          Stack(
                            overflow: Overflow.visible,
                            children: <Widget>[
                              Container(
                                child: (imageFileAvatar == null)
                                    ? (url != '')
                                        ? Material(
                                            child: CachedNetworkImage(
                                              placeholder: (context, url) =>
                                                  Container(
                                                      child: circularProgress(),
                                                      width: 150,
                                                      height: 150,
                                                      padding:
                                                          EdgeInsets.all(20.0)),
                                              imageUrl: url,
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
                                            ),

                                            borderRadius: BorderRadius.all(
                                                Radius.circular(94.0),),
                                            clipBehavior: Clip.hardEdge,
                                          )
                                        : Icon(
                                            Icons.account_circle,
                                            size: 200,
                                            color: Colors.grey,
                                          )
                                    : Material(
                                        child: Image.file(
                                          imageFileAvatar,
                                          height: 200,
                                          width: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 45,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: getImage,
                                  padding: EdgeInsets.all(0.0),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.grey,
                                  iconSize: 200,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    width: double.infinity,
                    margin: EdgeInsets.all(20.0),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(1.0),
                          child: isLoading ? circularProgress() : Container(),
                        ),

                        // Profile Name Part

                        Padding(
                          padding: EdgeInsets.only(top: 13),
                          child: Text(
                            'Full Name',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Container(
                          child: TextField(
                            style: TextStyle(color: Colors.black),
                            inputFormatters: [new LowerCaseTextFormatter()],
                            controller: profileNameTextEditingController,
                            decoration: InputDecoration(
                                hintText: 'write your name here...',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                hintStyle: TextStyle(color: Colors.grey),
                                errorText: _profileNameValid
                                    ? null
                                    : 'Profile name is very short'),
                            onChanged: (value) {
                              profileName = value.trim();
                            },
                            focusNode: profileNameFocusNode,
                          ),
                        ),

                        // Username Part is here

                        Padding(
                          padding: EdgeInsets.only(top: 13),
                          child: Text(
                            'Username',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Container(
                          child: TextField(
                            style: TextStyle(color: Colors.black),
                            inputFormatters: [
                              new UnderscoreLowerCaseTextFormatter()
                            ],
                            controller: usernameTextEditingController,
                            decoration: InputDecoration(
                                hintText: 'write username here...',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                hintStyle: TextStyle(color: Colors.grey),
                                errorText: _usernameValid
                                    ? null
                                    : 'Please enter username'),
                            onChanged: (value) {
                              username = value.trim();
                            },
                            focusNode: usernameFocusNode,
                          ),
                        ),

                        // Profile Name Part

                        Padding(
                          padding: EdgeInsets.only(top: 13),
                          child: Text(
                            'Bio',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Container(
                          child: TextField(
                            style: TextStyle(color: Colors.black),
                            controller: bioTextEditingController,
                            decoration: InputDecoration(
                                hintText: 'Write Bio here...',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                hintStyle: TextStyle(color: Colors.grey),
                                errorText:
                                    _bioValid ? null : 'Bio is very Long'),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            onChanged: (value) {
                              bio = value.trim();
                            },
                            focusNode: bioFocusNode,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(top: 29.0, left: 50.0, right: 50.0),
                    child: RaisedButton(
                      child: Text(
                        '     Update     ',
                        style: TextStyle(color: Colors.black, fontSize: 16.0),
                      ),
                      onPressed: updateUserData,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(top: 10.0, left: 50.0, right: 50.0),
                    child: RaisedButton(
                      color: Colors.red,
                      child: Text(
                        '     Sign Out     ',
                        style: TextStyle(color: Colors.white, fontSize: 14.0),
                      ),
                      onPressed: _signOut,
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Future<Null> _signOut() async {
    await _auth.signOut();
    this.setState(() {
      isLoading = false;
    });
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }
}
