
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../create_account_page.dart';
import '../models/user.dart';
import '../home_page.dart';
import './auth.dart';

class LoginPage extends StatefulWidget {
  final BaseAuth auth;
  LoginPage({this.auth, this.onSignedIn});
  final VoidCallback onSignedIn;
  @override
  _LoginPageState createState() => _LoginPageState();
}

enum FormType { login, register }

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final formKey = new GlobalKey<FormState>();
  final DateTime timestamp = DateTime.now();
  User currentUser;

  final _passwordController = TextEditingController();
  String _email;
  String _password;
  FormType _formType = FormType.login;
  var _isLoading = false;
  bool isSignIn = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging =FirebaseMessaging();
  AnimationController _controller;
  Animation<Offset> _slideAnimation;
  Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 300,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1.5),
      end: Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    // _heightAnimation.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred!'),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      setState(() {
        _isLoading = true;
      });
      return true;
    }
    return false;
  }

configureRealTimePustNotifications()async{
  final userId = await widget.auth.currentUser();
  if(Platform.isIOS){
      getIOSPermission();
  }
  _firebaseMessaging.getToken().then((token) {
    usersReference.document(userId).updateData({'androidNotificationToken': token});
  });
  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> msg) async{
      final String recipientId = msg['data']['recipient'];
       final String body = msg['notification']['body'];
       if(recipientId == userId){
         SnackBar snackBar = SnackBar(backgroundColor: Colors.blue,
         content: Text(body, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
         _scaffoldKey.currentState.showSnackBar(snackBar);
       }
    },
  );
}
 getIOSPermission(){
   _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, badge: true, sound: true));
   _firebaseMessaging.onIosSettingsRegistered.listen((setting) { 
     print('Setting Register : $setting');
   });
 }

  saveUserInfoToFireStore() async {
    String userId = await widget.auth.currentUser();

    final Map<String, dynamic> formData = {
      'username': null,
      'profileName': null,
    };
    DocumentSnapshot documentSnapshot = await usersReference.document(
          userId,
        )
        .get();
    if (!documentSnapshot.exists) {
      final formData = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      usersReference.document(userId).setData({
        'id': userId,
        'profileName': formData['profileName'],
        'username': formData['username'],
        'url': '',
        'email': _email,
        'bio': " ",
        'timestamp': timestamp,
      });
      await followersReference
          .document(currentUser.id)
          .collection('userFollowers')
          .document(currentUser.id)
          .setData({});
      await friendsReference
          .document(currentUser.id)
          .collection('userFriends')
          .document(currentUser.id)
          .setData({});

      documentSnapshot = await usersReference.document(userId).get();
    }
    currentUser = User.fromDocument(documentSnapshot);
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      try {
        if (_formType == FormType.login) {
          String userId =
              await widget.auth.signInWithEmailAndPassword(_email, _password);
          // AuthResult result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email, password: _password);
          // FirebaseUser user = result.user;
          print('Signed in: $userId');
        } else {
          String userId = await widget.auth
              .createUserWithEmailAndPassword(_email, _password);
          if (userId != null) {
            await saveUserInfoToFireStore();
            setState(() {
              isSignIn = true;
            });
            configureRealTimePustNotifications();
          } else {
            setState(() {
              isSignIn = false;
            });
          }

          // AuthResult result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email, password: _password);
          // FirebaseUser user = result.user;
          print('Registered user: $userId');
        }
        widget.onSignedIn();
      } catch (error) {
        String errorMessage = 'Something went wrong.';
        if (error.toString().contains('EMAIL_EXISTS')) {
          errorMessage = 'This email address is already in use.';
        } else if (error.toString().contains('INVALID_EMAIL')) {
          errorMessage = 'This is not a valid email address';
        } else if (error.toString().contains('WEAK_PASSWORD')) {
          errorMessage = 'This password is too weak.';
        } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
          errorMessage = 'Could not find a user with that email.';
        } else if (error.toString().contains('INVALID_PASSWORD')) {
          errorMessage = 'Invalid password.';
        } else if (error.toString().contains('ERROR_USER_NOT_FOUND')) {
          errorMessage =
              'User Not Found with this email id check your email id';
        } else if (error.toString().contains('ERROR_EMAIL_ALREADY_IN_USE')) {
          errorMessage = 'This email id already exit';
        } else if (error.toString().contains('ERROR_WRONG_PASSWORD')) {
          errorMessage = 'The password is invalid';
        } else if (error.toString().contains('ERROR_NETWORK_REQUEST_FAILED')) {
          errorMessage = 'Check your internet connection';
        }
        _showErrorDialog(errorMessage);
        print(error);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchAuthMode() {
    if (_formType == FormType.login) {
      setState(() {
        _formType = FormType.register;
      });
      _controller.forward();
    } else {
      setState(() {
        _formType = FormType.login;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20.0),
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 94),
                      child: Text(
                        'Fantastic',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 35.0,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: deviceSize.width > 600 ? 2 : 1,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                      height: _formType == FormType.register ? 320 : 260,
                      // height: _heightAnimation.value.height,
                      constraints: BoxConstraints(
                          minHeight:
                              _formType == FormType.register ? 320 : 260),
                      width: deviceSize.width * 0.75,
                      padding: EdgeInsets.all(16.0),
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(children: <Widget>[
                            TextFormField(
                              decoration: InputDecoration(labelText: 'Email'),
                              style: TextStyle(color: Colors.black),
                              textCapitalization: TextCapitalization.none,
                              validator: (value) => value.isEmpty
                                  ? 'email can \'t be empty'
                                  : null,
                              onSaved: (value) => _email = value.trim(),
                            ),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                              ),
                              obscureText: true,
                              style: TextStyle(color: Colors.black),
                              controller: _passwordController,
                              validator: (value) => value.isEmpty
                                  ? 'password can \'t be empty'
                                  : null,
                              onSaved: (value) => _password = value.trim(),
                              autofocus: false,
                            ),
                            AnimatedContainer(
                              constraints: BoxConstraints(
                                minHeight:
                                    _formType == FormType.register ? 60 : 0,
                                maxHeight:
                                    _formType == FormType.register ? 120 : 0,
                              ),
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                              child: FadeTransition(
                                opacity: _opacityAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: TextFormField(
                                    enabled: _formType == FormType.register,
                                    decoration: InputDecoration(
                                        labelText: 'Confirm Password'),
                                    style: TextStyle(color: Colors.black),
                                    obscureText: true,
                                    validator: _formType == FormType.register
                                        ? (value) {
                                            if (value !=
                                                _passwordController.text) {
                                              return 'Passwords do not match!';
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            if (_isLoading)
                              CircularProgressIndicator()
                            else
                              RaisedButton(
                                child: Text(_formType == FormType.login
                                    ? 'LOGIN'
                                    : 'SIGN UP'),
                                onPressed: validateAndSubmit,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30.0, vertical: 8.0),
                                color: Theme.of(context).primaryColor,
                                textColor: Theme.of(context)
                                    .primaryTextTheme
                                    .button
                                    .color,
                              ),
                            FlatButton(
                              child: Text(
                                  '${_formType == FormType.login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                              onPressed: _switchAuthMode,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30.0, vertical: 4),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              textColor: Theme.of(context).primaryColor,
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
