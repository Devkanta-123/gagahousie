import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/balance_card.dart'; // Import the balance card widget

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});
  
  final List<Map<String, String>> history = const [
    {'game': 'Game #1225', 'ticket': 'Ticket #001', 'prize': '₹0', 'date': '11/09/2023', 'status': 'Lost', 'time': '07:00 PM'},
    {'game': 'Game #1226', 'ticket': 'Ticket #002', 'prize': '₹0', 'date': '12/09/2023', 'status': 'Lost', 'time': '08:00 PM'},
    {'game': 'Game #1227', 'ticket': 'Ticket #003', 'prize': '₹80', 'date': '13/09/2023', 'status': 'Won', 'time': '07:30 PM'},
    {'game': 'Game #1228', 'ticket': 'Ticket #004', 'prize': '₹0', 'date': '14/09/2023', 'status': 'Lost', 'time': '09:00 PM'},
    {'game': 'Game #1229', 'ticket': 'Ticket #005', 'prize': '₹90', 'date': '15/09/2023', 'status': 'Won', 'time': '06:30 PM'},
    {'game': 'Game #1230', 'ticket': 'Ticket #006', 'prize': '₹0', 'date': '16/09/2023', 'status': 'Lost', 'time': '08:30 PM'},
    {'game': 'Game #1231', 'ticket': 'Ticket #007', 'prize': '₹75', 'date': '17/09/2023', 'status': 'Won', 'time': '07:15 PM'},
    {'game': 'Game #1232', 'ticket': 'Ticket #008', 'prize': '₹0', 'date': '18/09/2023', 'status': 'Lost', 'time': '09:30 PM'},
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
            'Game History',
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
            itemCount: history.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(history[index]);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistoryCard(Map<String, String> history) {
    final bool isWon = history['status'] == 'Won';
    final bool isLost = history['status'] == 'Lost';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium),
        border: Border.all(
          color: isWon 
              ? AppColors.primaryGreen.withOpacity(0.5) 
              : Colors.white.withOpacity(0.1),
          width: isWon ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isWon 
                ? AppColors.primaryGreen.withOpacity(0.1) 
                : Colors.transparent,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Icon
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isWon 
                  ? AppColors.primaryGreen.withOpacity(0.2) 
                  : Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWon ? Icons.emoji_events : Icons.close,
              color: isWon ? AppColors.primaryGreen : Colors.red,
              size: 18,
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Game Name and Prize
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        history['game']!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      history['prize']!,
                      style: TextStyle(
                        color: isWon ? AppColors.primaryGreen : Colors.white.withOpacity(0.4),
                        fontWeight: isWon ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Row 2: Ticket
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      color: Colors.white.withOpacity(0.3),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      history['ticket']!,
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Row 3: Date and Time in same row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white.withOpacity(0.3),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          history['date']!,
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white.withOpacity(0.3),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          history['time']!,
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    // Status Badge - Inline with date/time
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isWon 
                            ? AppColors.primaryGreen.withOpacity(0.2) 
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        history['status']!,
                        style: TextStyle(
                          color: isWon ? AppColors.primaryGreen : Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}