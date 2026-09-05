import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'ticket_details.dart';

class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Tickets',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        children: [
          // Each ticket card navigates to its details
          _buildTicketCard(
            context,
            ticketNumber: '01. 02. 03.',
            date: '12/05/2001',
            time: '01:30 p.m.',
            price: '100',
            ticketId: 'TKT001',
          ),
          const SizedBox(height: 16),
          _buildTicketCard(
            context,
            ticketNumber: '01. 02. 03.',
            date: '12/05/2001',
            time: '01:30 p.m.',
            price: '50',
            ticketId: 'TKT002',
          ),
          const SizedBox(height: 16),
          _buildTicketCard(
            context,
            ticketNumber: '01. 02. 03.',
            date: '12/05/2001',
            time: '01:30 p.m.',
            price: '50',
            ticketId: 'TKT003',
          ),
          const SizedBox(height: 16),
          _buildTicketCard(
            context,
            ticketNumber: '01. 02. 03.',
            date: '12/05/2001',
            time: '01:30 p.m.',
            price: '50',
            ticketId: 'TKT004',
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // View all tickets
            },
            child: const Text(
              'View All →',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen.withOpacity(0.15),
              AppColors.secondaryGreen.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ticket',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '₹$price',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Date', date),
              const SizedBox(height: 8),
              _buildInfoRow('Time', time),
              const SizedBox(height: 8),
              _buildInfoRow('Ticket Sl. No.', ticketNumber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          ':',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}