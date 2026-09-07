import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';
import 'dart:math';
class QRScannerPage extends StatefulWidget {
  final List<String> selectedTickets;
  final double totalAmount;
  final String ticketId;
  
  const QRScannerPage({
    super.key,
    required this.selectedTickets,
    required this.totalAmount,
    required this.ticketId,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late Timer _timer;
  int _secondsRemaining = 60;
  bool _isScanning = true;
  bool _isPaymentSuccess = false;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          _isScanning = false;
          _showTimeoutDialog();
        }
      });
    });
  }
  
  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glass,
        title: const Text(
          'Time Expired',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'QR scan time has expired. Please try again.',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Go Back',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
  
  void _simulateQRScan() {
    // Simulate QR code scanning
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isScanning) {
        setState(() {
          _isScanning = false;
          _isPaymentSuccess = true;
        });
        _timer.cancel();
        _showSuccessDialog();
      }
    });
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glass,
        title: const Text(
          'Payment Successful!',
          style: TextStyle(color: AppColors.primaryGreen),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket ID: ${widget.ticketId}',
              style: const TextStyle(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected Tickets: ${widget.selectedTickets.join(", ")}',
              style: const TextStyle(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ₹${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close QR page
              Navigator.pop(context); // Close selection page
            },
            child: Text(
              'Done',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GaGaAppHeader(
            showBackButton: true,
            compact: true,
            subtitle: 'Scan QR Code • Payment',
          ),
          // Timer Card
          _buildTimerCard(),
          
          // QR Scanner Area
          Expanded(
            child: Center(
              child: _isScanning ? _buildQRScanner() : _buildResultScreen(),
            ),
          ),
          
          // Payment Info
          _buildPaymentInfo(),
        ],
      ),
    );
  }
  
  Widget _buildTimerCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.25),
            AppColors.secondaryGreen.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryGreen,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Time Remaining',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '00:${_secondsRemaining.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: _secondsRemaining <= 10 
                  ? Colors.redAccent 
                  : AppColors.primaryGreen,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _secondsRemaining / 60,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              _secondsRemaining <= 10 
                  ? Colors.redAccent 
                  : AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQRScanner() {
    return GestureDetector(
      onTap: _simulateQRScan,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryGreen,
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.glowGreen.withOpacity(0.4),
              blurRadius: 18,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // QR Image perfectly scaled and fitted to the border div
              Transform.scale(
                scale: 1.385,
                alignment: const Alignment(0.0, -0.09),
                child: Image.asset(
                  'assets/qr_scanner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: CustomPaint(
                        painter: QRCodePainter(),
                        size: const Size(250, 250),
                      ),
                    );
                  },
                ),
              ),
              // Scanning animation overlay across full width
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  height: 3,
                  color: AppColors.primaryGreen,
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultScreen() {
    if (_isPaymentSuccess) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.primaryGreen,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₹${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan Failed',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try scanning again',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isScanning = true;
                _secondsRemaining = 60;
                _startTimer();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ticket ID:',
                style: TextStyle(color: AppColors.white),
              ),
              Text(
                widget.ticketId,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Tickets:',
                style: TextStyle(color: AppColors.white),
              ),
              Text(
                widget.selectedTickets.length.toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount:',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${widget.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for simulated QR code
class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final random = Random();
    final cellSize = size.width / 10;
    
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize - 2, cellSize - 2),
            paint,
          );
        }
      }
    }
    
    // Draw position markers
    _drawPositionMarker(canvas, 0, 0, cellSize * 2, paint);
    _drawPositionMarker(canvas, size.width - cellSize * 2, 0, cellSize * 2, paint);
    _drawPositionMarker(canvas, 0, size.height - cellSize * 2, cellSize * 2, paint);
  }
  
  void _drawPositionMarker(Canvas canvas, double x, double y, double size, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x, y, size, size), paint);
    canvas.drawRect(
      Rect.fromLTWH(x + size * 0.2, y + size * 0.2, size * 0.6, size * 0.6),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + size * 0.4, y + size * 0.4, size * 0.2, size * 0.2),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}