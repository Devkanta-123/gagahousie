import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import 'ticket_selection_page.dart';
import '../widgets/gaga_app_header.dart';

class TicketsTab extends StatelessWidget {
  const TicketsTab({super.key});

  final List<Map<String, String>> tickets = const [
    {
      'ticket': 'Ticket #001',
      'date': '25/09/2023',
      'price': '₹10',
      'status': 'Active',
      'id': 'TKT001'
    },
    {
      'ticket': 'Ticket #002',
      'date': '25/09/2023',
      'price': '₹10',
      'status': 'Active',
      'id': 'TKT002'
    },
    {
      'ticket': 'Ticket #003',
      'date': '26/09/2023',
      'price': '₹15',
      'status': 'Active',
      'id': 'TKT003'
    },
    {
      'ticket': 'Ticket #004',
      'date': '26/09/2023',
      'price': '₹15',
      'status': 'Active',
      'id': 'TKT004'
    },
    {
      'ticket': 'Ticket #005',
      'date': '27/09/2023',
      'price': '₹20',
      'status': 'Active',
      'id': 'TKT005'
    },
    {
      'ticket': 'Ticket #006',
      'date': '27/09/2023',
      'price': '₹20',
      'status': 'Active',
      'id': 'TKT006'
    },
    {
      'ticket': 'Ticket #007',
      'date': '28/09/2023',
      'price': '₹25',
      'status': 'Active',
      'id': 'TKT007'
    },
    {
      'ticket': 'Ticket #008',
      'date': '28/09/2023',
      'price': '₹25',
      'status': 'Active',
      'id': 'TKT008'
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> displayTickets = tickets;
    TicketProvider? provider;
    try {
      provider = Provider.of<TicketProvider>(context);
      if (provider.liveTicketsMap.isNotEmpty) {
        displayTickets = provider.liveTicketsMap;
      }
    } catch (_) {
      // Fallback if TicketProvider is not in tree
    }

    return Column(
      children: [
        // Reusable Branded Header with integrated balance card
        const GaGaAppHeader(
          compact: true,
          subtitle: 'Available Draws & Tickets',
          showBalance: true,
          balance: 1000.0,
          showRechargeButton: true,
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
                'Live Tickets',
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
                  '${displayTickets.length} Active',
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
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () async {
              if (provider != null) {
                await provider.fetchTickets();
              }
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingLarge),
              itemCount: displayTickets.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketSelectionPage(
                          ticket: displayTickets[index],
                        ),
                      ),
                    );
                  },
                  child: _buildTicketCard(displayTickets[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, String> ticket) {
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
                    color: AppColors.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket['ticket']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ticket['date']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
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
          ),
          const SizedBox(width: 8),
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
                  color: AppColors.primaryGreen.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ticket['status']!,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
