import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/balance_card.dart'; // Import the balance card widget

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Balance Card - Using Reusable Widget
          const BalanceCard(
            balance: 1000.00,
            showRechargeButton: true,
          ),
          
          const SizedBox(height: 20),
          
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.greenGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.glowGreen,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: AppColors.background,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // User Info
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return Column(
                children: [
                  Text(
                    auth.username ?? 'User',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.userEmail ?? 'user@example.com',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // Profile Options
          _buildProfileOption(Icons.person_outline, 'Personal Information'),
          _buildProfileOption(Icons.payment, 'Payment Methods'),
          _buildProfileOption(Icons.notifications, 'Notifications'),
          _buildProfileOption(Icons.security, 'Security Settings'),
          _buildProfileOption(Icons.help_outline, 'Help & Support'),
          _buildProfileOption(Icons.info_outline, 'About Us'),
        ],
      ),
    );
  }
  
  Widget _buildProfileOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.white),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.white),
      onTap: () {
        // Navigate to respective screens
      },
    );
  }
}