import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/screens/login_screen.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthCheck extends StatefulWidget{
  AuthCheck({Key ? key}) : super(key: key);

  @override
  _AuthCheckState createState() => _AuthCheckState();

}

class _AuthCheckState extends State<AuthCheck> {
  @override
  Widget build(BuildContext context) {
    AuthService auth = Provider.of<AuthService>(context);

    if (auth.isLoading) return loading();
    else if (auth.currentUser == null) return LoginScreen();
    else return MainScreen();
  }

  loading() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}