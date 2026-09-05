// tickets_tab.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'ticket_selection_page.dart';
import '../widgets/balance_card.dart'; // Import the balance card widget

class TicketsTab extends StatelessWidget {
  const TicketsTab({super.key});
  
  final List<Map<String, String>> tickets = const [
    {'ticket': 'Ticket #001', 'date': '25/09/2023', 'price': '\₹10', 'status': 'Active', 'id': 'TKT001'},
    {'ticket': 'Ticket #002', 'date': '25/09/2023', 'price': '\₹10', 'status': 'Active', 'id': 'TKT002'},
    {'ticket': 'Ticket #003', 'date': '26/09/2023', 'price': '\₹15', 'status': 'Active', 'id': 'TKT003'},
    {'ticket': 'Ticket #004', 'date': '26/09/2023', 'price': '\₹15', 'status': 'Active', 'id': 'TKT004'},
    {'ticket': 'Ticket #005', 'date': '27/09/2023', 'price': '\₹20', 'status': 'Active', 'id': 'TKT005'},
    {'ticket': 'Ticket #006', 'date': '27/09/2023', 'price': '\₹20', 'status': 'Active', 'id': 'TKT006'},
    {'ticket': 'Ticket #007', 'date': '28/09/2023', 'price': '\₹25', 'status': 'Active', 'id': 'TKT007'},
    {'ticket': 'Ticket #008', 'date': '28/09/2023', 'price': '\₹25', 'status': 'Active', 'id': 'TKT008'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Balance Card - Reused from widgets
        const BalanceCard(
          balance: 1000.0,
          showRechargeButton: true,
        ),
        
        const Padding(
          padding: EdgeInsets.all(AppDimens.paddingLarge),
          child: Text(
            'Tickets',
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
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketSelectionPage(
                        ticket: tickets[index],
                      ),
                    ),
                  );
                },
                child: _buildTicketCard(tickets[index]),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTicketCard(Map<String, String> ticket) {
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
                ticket['ticket']!,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket['date']!,
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ticket['price']!,
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
                child: Text(
                  ticket['status']!,
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}