import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/balance_card.dart'; // Import the balance card widget

class ResultsTab extends StatelessWidget {
  const ResultsTab({super.key});
  
  final List<Map<String, String>> results = const [
    {'game': 'Game #1234', 'prize': '₹100', 'date': '20/09/2023', 'winner': 'Winner 1'},
    {'game': 'Game #1233', 'prize': '₹50', 'date': '19/09/2023', 'winner': 'Winner 2'},
    {'game': 'Game #1232', 'prize': '₹200', 'date': '18/09/2023', 'winner': 'Winner 3'},
    {'game': 'Game #1231', 'prize': '₹75', 'date': '17/09/2023', 'winner': 'Winner 4'},
    {'game': 'Game #1230', 'prize': '₹150', 'date': '16/09/2023', 'winner': 'Winner 5'},
    {'game': 'Game #1229', 'prize': '₹90', 'date': '15/09/2023', 'winner': 'Winner 6'},
    {'game': 'Game #1228', 'prize': '₹120', 'date': '14/09/2023', 'winner': 'Winner 7'},
    {'game': 'Game #1227', 'prize': '₹80', 'date': '13/09/2023', 'winner': 'Winner 8'},
    {'game': 'Game #1226', 'prize': '₹60', 'date': '12/09/2023', 'winner': 'Winner 9'},
    {'game': 'Game #1225', 'prize': '₹250', 'date': '11/09/2023', 'winner': 'Winner 10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Balance Card - Using Reusable Widget
        const BalanceCard(
          balance: 1000.00,
          showRechargeButton: true,
        ),
        
        const Padding(
          padding: EdgeInsets.all(AppDimens.paddingLarge),
          child: Text(
            'Game Results',
            style: TextStyle(
              color: AppColors.white,
              fontSize: AppDimens.textXXLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLarge),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return _buildResultCard(results[index]);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildResultCard(Map<String, String> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['game']!,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppColors.primaryGreen.withOpacity(0.6),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Winner: ${result['winner']}',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result['prize']!,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primaryGreen,
                      size: 8,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result['date']!,
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}