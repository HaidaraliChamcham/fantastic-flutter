import 'dart:async';
import 'package:flutter/material.dart';
import './widgets/header_widget.dart';
import './utils/lowercase_formater.dart';



class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Map<String, dynamic> formData = {
    'username':  null,
    'profileName': null,
  };

 bool submitForm() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      SnackBar snackBar = SnackBar(
        content: Text('Welcome        ' + formData['profileName']),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 3), () {
        Navigator.pop(context, formData);
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar:header(context, strTitle: 'Setting',disappearedBackButton: true),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 26.0),
                  child: Center(
                    child: Text(
                      'Set up Name and UserName',
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Container(
                    child: Form(
                      key: _formKey,
                      autovalidate: true,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Full Name'),
                            textCapitalization: TextCapitalization.none,
                            validator: (val) {
                              if (val.length < 3) {
                                return "Your name is to short.";
                              } else if (val.isEmpty) {
                                return "please enter username";
                              } else if (val.length > 26) {
                                return "Your name is too long.";
                              } else {
                                return null;
                              }
                            },
                              autofocus: false,
                            inputFormatters: [new LowerCaseTextFormatter()],
                            onSaved: (val) => formData['profileName'] = val,
                          ),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Username'),
                            textCapitalization: TextCapitalization.none,
                            validator: (val) {
                              if (val.trim().isEmpty) {
                                return "please enter username";
                              } else if (val.trim().length > 22) {
                                return "username too long.";
                              } else {
                                return null;
                              }
                            },
                            autofocus: false,
                            inputFormatters: [new UnderscoreLowerCaseTextFormatter()],
                            onSaved: (val) => formData['username'] = val.trim(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                RaisedButton(
                  child: Text(
                    'Procced',
                  ),
                  onPressed:(){ submitForm();},
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).primaryTextTheme.button.color,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
