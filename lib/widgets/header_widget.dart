import 'package:flutter/material.dart';

AppBar header(context,
    {bool isAppTitle, String strTitle, disappearedBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: disappearedBackButton ? false : true,
    title: Text(
      strTitle,
      style: TextStyle(fontSize: 22.0),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
  );
}
