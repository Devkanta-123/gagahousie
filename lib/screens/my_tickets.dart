import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';
import 'ticket_details.dart';

class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ticketsList = [
      {
        'ticketNumber': '01. 02. 03.',
        'date': '12/05/2024',
        'time': '01:30 PM',
        'price': '100',
        'ticketId': 'TKT001',
        'status': 'Active',
      },
      {
        'ticketNumber': '04. 12. 25.',
        'date': '12/05/2024',
        'time': '01:30 PM',
        'price': '50',
        'ticketId': 'TKT002',
        'status': 'Active',
      },
      {
        'ticketNumber': '11. 22. 33.',
        'date': '13/05/2024',
        'time': '04:00 PM',
        'price': '50',
        'ticketId': 'TKT003',
        'status': 'Booked',
      },
      {
        'ticketNumber': '07. 14. 28.',
        'date': '14/05/2024',
        'time': '07:30 PM',
        'price': '50',
        'ticketId': 'TKT004',
        'status': 'Booked',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Full-width consistent branded header with integrated balance card
          const GaGaAppHeader(
            showBackButton: true,
            subtitle: 'My Purchased Tickets',
            showBalance: true,
            balance: 1000.0,
            showRechargeButton: true,
          ),

          // Subheader with ticket count
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Purchased Tickets',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF0F3B2C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${ticketsList.length} Active',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Responsive tickets list matching tickets_tab.dart green cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              itemCount: ticketsList.length,
              itemBuilder: (context, index) {
                final t = ticketsList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildTicketCard(
                    context,
                    ticketNumber: t['ticketNumber']!,
                    date: t['date']!,
                    time: t['time']!,
                    price: t['price']!,
                    ticketId: t['ticketId']!,
                    status: t['status']!,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context, {
    required String ticketNumber,
    required String date,
    required String time,
    required String price,
    required String ticketId,
    required String status,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailsPage(
              ticketNumber: ticketNumber,
              date: date,
              time: time,
              price: price,
              ticketId: ticketId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
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
          children: [
            // Compact green emblem icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: AppColors.primaryGreen,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Flexible ticket details & metadata without overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Ticket #$ticketId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Sl: $ticketNumber',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            date,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            time,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Price & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹$price',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}