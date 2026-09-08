// widgets/balance_card.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../screens/wallet_page.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final bool showRechargeButton;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Function? onTap;

  const BalanceCard({
    super.key,
    this.balance = 0.0,
    this.showRechargeButton = true,
    this.margin,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          // Navigate to Wallet Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletPage(),
            ),
          );
        }
      },
      child: Container(
        margin: margin ?? const EdgeInsets.all(AppDimens.paddingLarge),
        padding: padding ?? const EdgeInsets.all(AppDimens.paddingLarge),
        decoration: BoxDecoration(
          gradient: AppColors.greenGradient,
          borderRadius: BorderRadius.circular(
              borderRadius ?? AppDimens.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.glowGreen,
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for balance and wallet icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.balance,
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: AppDimens.textMedium,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.background,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppDimens.paddingSmall + 4),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(AppDimens.borderRadiusSmall),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.background,
                    size: 30,
                  ),
                ),
              ],
            ),

            // Recharge Button - Moved to next line
            if (showRechargeButton) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.add,
                        color: AppColors.background,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Recharge',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
