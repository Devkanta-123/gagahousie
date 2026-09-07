import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';

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
        // Reusable Branded Header
        const GaGaAppHeader(
          compact: true,
          subtitle: 'Draw Results & Recent Winners',
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
                'Past Games',
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
                  '${results.length} Completed',
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['game']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Winner: ${result['winner']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                  color: AppColors.primaryGreen.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryGreen.withOpacity(0.8),
                      size: 9,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      result['date']!,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
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