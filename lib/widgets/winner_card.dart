import 'package:flutter/material.dart';
import '../utils/constants.dart';

class WinnerCard extends StatelessWidget {
  final String winnerName;
  final String date;
  final int index;

  const WinnerCard({
    super.key,
    required this.winnerName,
    required this.date,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusSmall),
        border: Border.all(
          color: AppColors.glassBorder.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
          child:
              Icon(Icons.emoji_events, color: AppColors.primaryGreen, size: 20),
        ),
        title: Text(
          winnerName,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            date,
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
