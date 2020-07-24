import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as ImD;
import '../models/user.dart';
import '../home_page.dart';
import '../widgets/progress_indicator.dart';

class UploadImage extends StatefulWidget {
  final User gCurrentUser;
  UploadImage({this.gCurrentUser});

  @override
  _UploadImageState createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage>
    with AutomaticKeepAliveClientMixin<UploadImage> {
  File file;

  bool uploading = false;
  String postId = Uuid().v4();

  TextEditingController captionTextEditingController = TextEditingController();

  captureImageWithCamera() async {
    Navigator.pop(context);
    File imageFile = await ImagePicker.pickImage(
        source: ImageSource.camera, maxHeight: 700, maxWidth: double.infinity);
    setState(() {
      this.file = imageFile;
    });
  }

  picImageFromGallery() async {
    Navigator.pop(context);
    File imageFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    setState(() {
      this.file = imageFile;
    });
  }

  takeImage(mContext) {
    return showDialog(
      context: mContext,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            'New Post',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          children: <Widget>[
            SimpleDialogOption(
              child: Text(
                'Capture Image with Camera',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: captureImageWithCamera,
            ),
            SimpleDialogOption(
              child: Text(
                'Select Image From Gallery',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: picImageFromGallery,
            ),
            SimpleDialogOption(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        );
      },
    );
  }

  displayUploadScreen() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.add_photo_alternate,
            color: Colors.grey,
            size: 200.0,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9.0),
              ),
              child: Text(
                'Upload Image',
                style: TextStyle(color: Colors.black, fontSize: 20.0),
              ),
              color: Colors.green,
              onPressed: () => takeImage(context),
            ),
          )
        ],
      ),
    );
  }

  clearPostInfo() {
    captionTextEditingController.clear();
    setState(() {
      file = null;
    });
  }

  compressingPhoto() async {
    final tDirectory = await getTemporaryDirectory();
    final path = tDirectory.path;
    ImD.Image mImageFile = ImD.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(ImD.encodeJpg(mImageFile, quality: 60));
    setState(() {
      file = compressedImageFile;
    });
  }

  controlUploadAndSave() async {
    setState(() {
      uploading = true;
    });
    await compressingPhoto();
    String downloadUrl = await uploadPhoto(file);

    savePostInfoToFireStore(
        url: downloadUrl, caption: captionTextEditingController.text.trim());
    captionTextEditingController.clear();

    setState(() {
      file = null;
      uploading = false;
      postId = Uuid().v4();
    });
  }

  savePostInfoToFireStore({String url, String caption}) {
    postsReference
        .document(widget.gCurrentUser.id)
        .collection('usersPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'ownerId': widget.gCurrentUser.id,
      'timestamp': DateTime.now(),
      'likes': {},
      'username': widget.gCurrentUser.username,
      'profilename': widget.gCurrentUser.profileName,
      'caption': caption,
      'url': url,
    });
  }

  Future<String> uploadPhoto(mImageFile) async {
    StorageUploadTask mStorageUploadTask =
        storageReference.child('post_$postId.jpg').putFile(mImageFile);
    StorageTaskSnapshot storageTaskSnapshot =
        await mStorageUploadTask.onComplete;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  displayUploadFormScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: clearPostInfo,
        ),
        title: Text(
          "New Post",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(
              'Upload',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0),
            ),
            onPressed: uploading ? null : () => controlUploadAndSave(),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          uploading ? linearProgress() : Text(""),
          Center(
            child: Row(
              children: <Widget>[
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      controller: captionTextEditingController,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: '   say something about image',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[600]),
                        ),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38)),
                      ),
                      maxLines: null,
                    
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 12.0),
          ),
        ],
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? displayUploadScreen() : displayUploadFormScreen();
  }
}
