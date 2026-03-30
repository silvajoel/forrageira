import 'package:flutter/material.dart';
import 'package:forrageira/screens/analysis_screen.dart';
import 'package:forrageira/screens/home_screen.dart';
import 'package:forrageira/screens/profile_screen.dart';
import 'package:forrageira/screens/submit_analysis_screen.dart';
import 'package:forrageira/services/location_service.dart';
import 'package:forrageira/services/supabase_image_storage_service.dart';
import 'package:forrageira/widgets/bottom_nav_custom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState(); // público — sem underscore
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Instanciado uma vez — evita recriar os serviços a cada rebuild
  late final List<Widget> _screens = [
    const HomeScreen(),
    const AnalysisScreen(),
    SubmitAnalysisScreen(
      locationService: LocationService(),
      imageStorageService: SupabaseImageStorageService(
        Supabase.instance.client,
      ),
    ),
    const ProfileScreen(),
  ];

  void setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
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