import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './auth/auth.dart';
import './models/user.dart';
import './auth/root_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Users(),
        ),
      ],
      child: MaterialApp(
        title: 'Fantastic',
        theme: ThemeData(
          primaryColor: Colors.purple[400],
        
        ),
        home: RootPage(auth: new Auth()),
      ),
    );
  }
}
