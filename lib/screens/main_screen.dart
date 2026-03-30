import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/screens/analysis_detail_screen.dart';
import 'package:forrageira/screens/analysis_screen.dart';
import 'package:forrageira/screens/home_screen.dart';
import 'package:forrageira/screens/profile_screen.dart';
import 'package:forrageira/screens/submit_analysis_screen.dart';
import 'package:forrageira/screens/notifications_screen.dart';
import 'package:forrageira/services/location_service.dart';
import 'package:forrageira/widgets/bottom_nav_custom.dart';
import 'package:forrageira/services/plesk_image_storage_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  AnalysisRequest? _selectedAnalysis;
  bool _showNotifications = false;

  late final List<Widget> _baseScreens = [
    const HomeScreen(),
    const AnalysisScreen(),
    SubmitAnalysisScreen(
      locationService: LocationService(),
      imageStorageService: const PleskImageStorageService(),
    ),
    const ProfileScreen(),
  ];

  // 🔹 Troca de abas
  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
      _selectedAnalysis = null;
      _showNotifications = false;
    });
  }

  // 🔹 Abrir detalhe
  void openAnalysisDetail(AnalysisRequest analysis) {
    setState(() {
      _selectedAnalysis = analysis;
      _showNotifications = false;
      _currentIndex = 4;
    });
  }

  // 🔹 Abrir notificações
  void openNotifications() {
    setState(() {
      _showNotifications = true;
      _selectedAnalysis = null;
    });
  }

  void _onTap(int index) {
    setIndex(index);
  }

  // 🔹 Define qual tela mostrar
  int _resolveIndex() {
    if (_showNotifications) return 5;
    return _currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _resolveIndex(),
        children: [
          ..._baseScreens,

          // índice 4 → detalhe
          _selectedAnalysis != null
              ? AnalysisDetailScreen(analysis: _selectedAnalysis!)
              : const SizedBox(),

          // índice 5 → notificações
          const NotificationsScreen(),
        ],
      ),

      bottomNavigationBar: BottomNavCustom(
        currentIndex: _currentIndex > 3 ? 0 : _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}