// screens/ticket_purchase_page.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/balance_card.dart';

class TicketPurchasePage extends StatefulWidget {
  final Map<String, String>? ticket;
  final bool showBackButton;

  const TicketPurchasePage({
    super.key,
    this.ticket,
    this.showBackButton = true,
  });

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  // Wallet balance (in a real app, this would come from a state management solution)
  double walletBalance = 1000.0;
  final double ticketPrice = 20.0; // Fixed price of ₹20
  int selectedCount = 0;

  @override
  void initState() {
    super.initState();
    // Get the number of selected tickets from navigation arguments
    // For now, default to 1
    selectedCount = 1;
  }

  @override
  Widget build(BuildContext context) {
    final double total = ticketPrice * selectedCount;
    final bool hasSufficientBalance = walletBalance >= total;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text(
          'Purchase Ticket',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Container(
        color: const Color(0xFFF5F0E8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              BalanceCard(
                balance: walletBalance,
                showRechargeButton: true,
              ),
              
              const SizedBox(height: 20),
              
              // Ticket Details Card
              _buildTicketDetailsCard(),
              
              const SizedBox(height: 20),
              
              // Selected Tickets Info
              _buildSelectedTicketsInfo(),
              
              const SizedBox(height: 20),
              
              // Total Amount
              _buildTotalAmount(total),
              
              const SizedBox(height: 20),
              
              // Confirm Button
              _buildConfirmButton(total, hasSufficientBalance),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00B894).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticket Details',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Ticket Name
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Ticket:',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.ticket?['ticket'] ?? 'Ticket #001',
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Date
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Date:',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.ticket?['date'] ?? '25/09/2023',
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Time
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Time:',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.ticket?['time'] ?? '07:00 PM',
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Price per ticket
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Price:',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '₹${ticketPrice.toStringAsFixed(2)} per ticket',
                  style: const TextStyle(
                    color: Color(0xFF00B894),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTicketsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00B894).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.confirmation_number,
              color: Color(0xFF00B894),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Tickets',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selectedCount} ticket${selectedCount > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00B894),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '₹${(ticketPrice * selectedCount).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00B894),
            Color(0xFF00A381),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(double total, bool hasSufficientBalance) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: hasSufficientBalance ? () => _confirmPurchase(total) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSufficientBalance 
              ? const Color(0xFF00B894)
              : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          hasSufficientBalance 
              ? 'Confirm Purchase (₹${total.toStringAsFixed(2)})'
              : 'Insufficient Balance - Please Recharge',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _confirmPurchase(double total) {
    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F0E8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(20),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF00B894),
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(
                color: Colors.grey,
                height: 16,
              ),
              _buildDialogRow('Ticket:', widget.ticket?['ticket'] ?? 'Ticket #001'),
              const SizedBox(height: 8),
              _buildDialogRow('Quantity:', selectedCount.toString()),
              const SizedBox(height: 8),
              _buildDialogRow('Price per ticket:', '₹${ticketPrice.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              const Divider(
                color: Colors.grey,
                height: 16,
              ),
              _buildDialogRow(
                'Total Paid:',
                '₹${total.toStringAsFixed(2)}',
                isHighlight: true,
              ),
              const SizedBox(height: 8),
              _buildDialogRow(
                'Remaining Balance:',
                '₹${(walletBalance - total).toStringAsFixed(2)}',
                isSuccess: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00B894).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF00B894),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your ticket${selectedCount > 1 ? 's have' : ' has'} been booked successfully!',
                        style: const TextStyle(
                          color: Color(0xFF00B894),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Update balance after purchase
                setState(() {
                  walletBalance -= total;
                });
                Navigator.pop(context);
                Navigator.pop(context);
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('₹${total.toStringAsFixed(2)} paid successfully!'),
                    backgroundColor: const Color(0xFF00B894),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Color(0xFF00B894),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isHighlight = false, bool isSuccess = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF2C3E50) : Colors.grey.withOpacity(0.7),
            fontSize: isHighlight ? 15 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isSuccess 
                  ? const Color(0xFF00B894)
                  : isHighlight 
                      ? const Color(0xFF00B894)
                      : const Color(0xFF2C3E50),
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}