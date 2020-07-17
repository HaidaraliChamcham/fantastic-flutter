import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasenate/widgets/header_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/login_page.dart';
import '../../home_page.dart';
import '../../models/user.dart';
import '../../utils/lowercase_formater.dart';
import '../../widgets/progress_indicator.dart';

class EditProfilePage extends StatefulWidget {
  final String currentOnlineUserId;
  EditProfilePage({this.currentOnlineUserId});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController profileNameTextEditingController =
      TextEditingController();
  TextEditingController usernameTextEditingController = TextEditingController();
  TextEditingController bioTextEditingController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  bool loading = false;
  User user;
  bool _bioValid = true;
  bool _profileNameValid = true;
  bool _usernameValid = true;
  File imageFileAvatar;
  bool isLoading = false;
  FlutterToast flutterToast;

  void initState() {
    super.initState();
    getAndDisplayUserInformation();
    flutterToast = FlutterToast(context);
  }

  @override
  void dispose() {
    profileNameTextEditingController.dispose();
    usernameTextEditingController.dispose();
    bioTextEditingController.dispose();
    super.dispose();
  }

  getAndDisplayUserInformation() async {
    setState(() {
      loading = true;
    });
    DocumentSnapshot documentSnapshot =
        await usersReference.document(widget.currentOnlineUserId).get();
    user = User.fromDocument(documentSnapshot);
    usernameTextEditingController.text = user.username;
    profileNameTextEditingController.text = user.profileName;
    bioTextEditingController.text = user.bio;

    setState(() {
      loading = false;
    });
  }

  updateUserData() {
    setState(() {
      usernameTextEditingController.text.trim().length < 3 ||
              usernameTextEditingController.text.isEmpty
          ? _profileNameValid = false
          : _profileNameValid = true;
      profileNameTextEditingController.text.trim().length < 3 ||
              profileNameTextEditingController.text.isEmpty
          ? _usernameValid = false
          : _usernameValid = true;
      bioTextEditingController.text.trim().length > 111
          ? _bioValid = false
          : _bioValid = true;
    });
    if (_bioValid && _profileNameValid && _usernameValid) {
      usersReference.document(widget.currentOnlineUserId).updateData({
        'username': usernameTextEditingController.text,
        'profileName': profileNameTextEditingController.text,
        'bio': bioTextEditingController.text.trim(),
      });
      SnackBar successSnackBar = SnackBar(
        content: Text('Profile has been updated successfully. '),
      );
      _scaffoldGlobalKey.currentState.showSnackBar(successSnackBar);
    }
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
    String mFileName = user.id;
    final StorageReference profile = FirebaseStorage.instance.ref().child(mFileName);
    StorageUploadTask storageUploadTask =
        storageReference.putFile(imageFileAvatar);
    StorageTaskSnapshot storageTaskSnapshot;
    storageUploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((newImageDownloadUrl) {
          user.url = newImageDownloadUrl;
           usersReference.document(widget.currentOnlineUserId).updateData({
            'url': user.url,
          });
        },
            onError: (errorMsg) {
          setState(() {
            isLoading = false;
          });
          flutterToast.showToast(child: Text('Error occured in getting Profile Download Url'));
        });
      }
    }, onError: (errorMsg) {
      setState(() {
        isLoading = false;
      });
      flutterToast.showToast(child: Text(errorMsg.toString()));
      // Fluttertoast.showToast(msg: errorMsg.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldGlobalKey,
      appBar: header(context, strTitle: 'Edit Profile'),
      body: loading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                (imageFileAvatar == null)
                    ? (user.url != '')
                        ? Material(
                            child: CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                child: circularProgress(),
                              ),
                              imageUrl: user.url,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(75.0)),
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
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(75.0)),
                        clipBehavior: Clip.hardEdge,
                      ),
                IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    size: 100,
                    color: Colors.white54.withOpacity(0.3),
                  ),
                  onPressed: getImage,
                  padding: EdgeInsets.all(0.0),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.grey,
                  iconSize: 200,
                ),
                // Stack(
                //   overflow: Overflow.visible,
                //   children: <Widget>[
                //     Row(
                //       children: <Widget>[
                //         Expanded(
                //           child: Container(
                //             height: 200.0,
                //             decoration: BoxDecoration(
                //               image: DecorationImage(
                //                 fit: BoxFit.fill,
                //                 image: NetworkImage(
                //                     'https://pbs.twimg.com/profile_banners/132385468/1590425639/1500x500'),
                //               ),
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //     Positioned(
                //       top: 130.0,
                //       child: Container(
                //         height: 120,
                //         width: 120,
                //         decoration: BoxDecoration(
                //             shape: BoxShape.circle,
                //             image: DecorationImage(
                //               fit: BoxFit.cover,
                //               image: NetworkImage(
                //                   'https://pbs.twimg.com/profile_images/954970943255818240/ycI3A-DK_400x400.jpg'),
                //             ),
                //             border:
                //                 Border.all(color: Colors.white, width: 5.0)),
                //       ),
                //     ),
                //   ],
                // ),
                SizedBox(
                  height: 10.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => getImage(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Icon(
                          Icons.edit,
                          color: Colors.black54,
                          size: 20.0,
                        ),
                        Text(
                          'Change cover image',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                    onTap: () => print('you change profile image'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.edit,
                          color: Colors.black54,
                          size: 20.0,
                        ),
                        Text(
                          'Change dp',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      createProfileNameTextFormField(),
                      createUsernameTextFormField(),
                      createBioTextFormField()
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 29.0, left: 50.0, right: 50.0),
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
                  padding: EdgeInsets.only(top: 10.0, left: 50.0, right: 50.0),
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
            ),
    );
  }

 Future<void> _signOut() async {
     await _auth.signOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Column createUsernameTextFormField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 13),
          child: Text(
            'Username',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        TextField(
          style: TextStyle(color: Colors.black),
          inputFormatters: [new UnderscoreLowerCaseTextFormatter()],
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
              errorText: _usernameValid ? null : 'Username is very short'),
        ),
      ],
    );
  }

  Column createProfileNameTextFormField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 13),
          child: Text(
            'Full Name',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        TextField(
          style: TextStyle(color: Colors.black),
          inputFormatters: [new LowerCaseTextFormatter()],
          controller: profileNameTextEditingController,
          decoration: InputDecoration(
              hintText: 'write profile name here...',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              hintStyle: TextStyle(color: Colors.grey),
              errorText:
                  _profileNameValid ? null : 'Profile name is very short'),
        ),
      ],
    );
  }

  Column createBioTextFormField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 13),
          child: Text(
            'Bio',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        TextField(
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
              errorText: _bioValid ? null : 'Bio is very Long'),
          keyboardType: TextInputType.multiline,
          maxLines: null,
        ),
      ],
    );
  }
}
