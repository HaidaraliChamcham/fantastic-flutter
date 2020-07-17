import 'package:flutter/material.dart';
import '../widgets/progress_indicator.dart';
import './auth.dart';
import '../home_page.dart';
import './login_page.dart';


class RootPage extends StatefulWidget {
  final BaseAuth auth;
  RootPage({this.auth});
  @override
  _RootPageState createState() => _RootPageState();
}

enum AuthStatus{
  notSignedIn,
  signedIn
}

class _RootPageState extends State<RootPage> {

  AuthStatus authStatus = AuthStatus.notSignedIn;

  @override
  void initState() {
    super.initState();
    widget.auth.currentUser().then((userId){
      setState((){
        authStatus = userId == null? AuthStatus.notSignedIn:AuthStatus.signedIn;
      });
    });
  }
  void _signedIn(){
    setState(() {
      authStatus = AuthStatus.signedIn;
    });
  }

  void _signedOut(){
    setState(() {
      authStatus = AuthStatus.notSignedIn;
    });
  }

  @override
  Widget build(BuildContext context) {

    switch (authStatus) {
      case AuthStatus.notSignedIn:
       return LoginPage(auth: widget.auth,onSignedIn: _signedIn);
      case AuthStatus.signedIn:
        return HomePage(auth: widget.auth, onSignedOut: _signedOut,);
       }
       return(circularProgress());
  }
}