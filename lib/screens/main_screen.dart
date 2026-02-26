import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/screens/analysis_screen.dart';
import 'package:forrageira/screens/home_screen.dart';
import 'package:forrageira/screens/profile_screen.dart';
import 'package:forrageira/screens/reset_password_screen.dart';
import 'package:forrageira/screens/submit_analysis_screen.dart';
import 'package:forrageira/widgets/bottom_nav_custom.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalysisScreen(),
    SubmitAnalysisScreen(),
    ProfileScreen(),
    ResetPasswordScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavCustom(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}