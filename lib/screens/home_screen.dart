import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'home_tab.dart';
import 'tickets_tab.dart';
import 'results_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _tabs = [
    const HomeTab(),
    const TicketsTab(),
    const ResultsTab(),
    const HistoryTab(),
    const ProfileTab(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _tabs[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Tickets'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Results'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
      ],
    );
  }
  
  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}