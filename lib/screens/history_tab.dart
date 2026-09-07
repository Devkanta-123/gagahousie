import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';

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
        // Reusable Branded Header
        const GaGaAppHeader(
          compact: true,
          subtitle: 'Game Alerts & Play History',
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Games',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.18),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${history.length} Played',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

  Widget _buildHistoryCard(Map<String, String> item) {
    final bool isWon = item['status'] == 'Won';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWon
              ? AppColors.primaryGreen.withOpacity(0.35)
              : AppColors.primaryGreen.withOpacity(0.12),
          width: isWon ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isWon
                ? AppColors.primaryGreen.withOpacity(0.06)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isWon
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : const Color(0xFFE74C3C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWon ? Icons.emoji_events_rounded : Icons.close_rounded,
              color: isWon ? AppColors.primaryGreen : const Color(0xFFE74C3C),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['game']!,
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      item['prize']!,
                      style: TextStyle(
                        color: isWon ? AppColors.primaryGreen : AppColors.textSecondary,
                        fontWeight: isWon ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.textSecondary.withOpacity(0.8),
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item['ticket']!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textSecondary.withOpacity(0.8),
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item['date']!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.access_time_rounded,
                          color: AppColors.textSecondary.withOpacity(0.8),
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item['time']!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isWon
                            ? AppColors.primaryGreen.withOpacity(0.09)
                            : const Color(0xFFE74C3C).withOpacity(0.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item['status']!,
                        style: TextStyle(
                          color: isWon ? AppColors.primaryGreen : const Color(0xFFE74C3C),
                          fontSize: 9.5,
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