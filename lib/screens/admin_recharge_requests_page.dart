import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wallet_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';

class AdminRechargeRequestsPage extends StatefulWidget {
  const AdminRechargeRequestsPage({super.key});

  @override
  State<AdminRechargeRequestsPage> createState() =>
      _AdminRechargeRequestsPageState();
}

class _AdminRechargeRequestsPageState extends State<AdminRechargeRequestsPage> {
  String _selectedFilter = 'pending'; // 'pending', 'approved', 'rejected', 'all'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      walletProvider.fetchAdminRecharges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final allRequests = walletProvider.adminRecharges;

    final pendingList = allRequests
        .where((r) => r.status.toLowerCase() == 'pending')
        .toList();
    final approvedList = allRequests
        .where((r) => r.status.toLowerCase() == 'approved')
        .toList();
    final rejectedList = allRequests
        .where((r) => r.status.toLowerCase() == 'rejected')
        .toList();

    List<RechargeRequestModel> displayList;
    if (_selectedFilter == 'pending') {
      displayList = pendingList;
    } else if (_selectedFilter == 'approved') {
      displayList = approvedList;
    } else if (_selectedFilter == 'rejected') {
      displayList = rejectedList;
    } else {
      displayList = allRequests;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GaGaAppHeader(
            showBackButton: true,
            compact: true,
            showBalance: false,
            subtitle: 'Admin • Payment Verification',
          ),

          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Pending (${pendingList.length})',
                    keyName: 'pending',
                    color: const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Approved (${approvedList.length})',
                    keyName: 'approved',
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Rejected (${rejectedList.length})',
                    keyName: 'rejected',
                    color: const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'All (${allRequests.length})',
                    keyName: 'all',
                    color: const Color(0xFF4B5563),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: walletProvider.isLoading && allRequests.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => walletProvider.fetchAdminRecharges(),
                    child: displayList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final request = displayList[index];
                              return _buildRequestCard(request);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String keyName,
    required Color color,
  }) {
    final bool isSelected = _selectedFilter == keyName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = keyName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No $_selectedFilter recharge requests',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'New top-up requests from users will appear here.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(RechargeRequestModel req) {
    final bool isPending = req.isPending;
    final bool isApproved = req.isApproved;
    final bool isRejected = req.isRejected;

    Color statusColor = const Color(0xFFD97706);
    IconData statusIcon = Icons.hourglass_top_rounded;
    if (isApproved) {
      statusColor = AppColors.primaryGreen;
      statusIcon = Icons.check_circle_rounded;
    } else if (isRejected) {
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFD97706).withOpacity(0.4)
              : statusColor.withOpacity(0.2),
          width: isPending ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: User & Amount
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.userName.isNotEmpty
                            ? req.userName
                            : (req.userEmail.isNotEmpty
                                ? req.userEmail
                                : 'User #${req.userId}'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${req.userEmail} ${req.userPhone.isNotEmpty ? '• ' + req.userPhone : ''}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${req.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Request Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Method:', req.paymentMethod.toUpperCase()),
                if (req.transactionUtr.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('UTR / Ref ID:', req.transactionUtr,
                      isSelectable: true),
                ],
                if (req.accountNumber != null && req.accountNumber!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Bank Account:', req.accountNumber!),
                ],
                if (req.ifscCode != null && req.ifscCode!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('IFSC Code:', req.ifscCode!),
                ],
                const SizedBox(height: 6),
                _buildInfoRow(
                  'Submitted:',
                  _formatDate(req.createdAt),
                ),

                // Rejection / Approval Remarks
                if (req.adminRemarks != null &&
                    req.adminRemarks!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRejected
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isRejected
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: isRejected
                              ? const Color(0xFFDC2626)
                              : AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Remarks: ${req.adminRemarks}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isRejected
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Payment Proof Preview Button
                if (req.proofUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _viewProofDialog(req.proofUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00B894).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_rounded,
                            color: AppColors.primaryGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'View Uploaded Payment Proof Receipt',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Inspect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Action Buttons for Pending requests
                if (isPending) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Reject Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _showRejectDialog(req),
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: Color(0xFFDC2626)),
                          label: const Text(
                            'Reject',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFDC2626), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Approve Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _showApproveDialog(req),
                          icon: const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                          label: const Text(
                            'Approve',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isSelectable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: isSelectable
              ? SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _viewProofDialog(String proofUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D281E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.4),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_rounded,
                            color: Color(0xFF00E676), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Payment Proof Receipt',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildProofImage(proofUrl),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close Preview'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProofImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _errorImageWidget(),
        );
      } catch (e) {
        return _errorImageWidget();
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child:
                  CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _errorImageWidget(),
      );
    } else if (url.startsWith('/')) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
    }
    return _errorImageWidget();
  }

  Widget _errorImageWidget() {
    return Container(
      height: 200,
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
          SizedBox(height: 8),
          Text(
            'Unable to load receipt image',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(RechargeRequestModel req) {
    final remarksController = TextEditingController(
      text: 'Verified & Credited to GaGa Wallet',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D281E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.4)),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF00E676), size: 24),
              SizedBox(width: 8),
              Text(
                'Approve Recharge',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to approve ₹${req.amount.toStringAsFixed(2)} for ${req.userName.isNotEmpty ? req.userName : req.userEmail}?',
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'The user wallet will be credited immediately and a real-time sound notification will be dispatched.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: remarksController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Remarks (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isProcessing = true);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final adminName = auth.fullName ?? auth.username ?? 'Admin';
                final walletProvider =
                    Provider.of<WalletProvider>(context, listen: false);

                final success = await walletProvider.approveRecharge(
                  request: req,
                  adminName: adminName,
                  adminRemarks: remarksController.text.trim(),
                );

                setState(() => _isProcessing = false);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Recharge of ₹${req.amount.toStringAsFixed(2)} approved! Real-time sound notification sent.'
                            : 'Failed to approve recharge: ${walletProvider.errorMessage ?? "Unknown error"}',
                      ),
                      backgroundColor:
                          success ? AppColors.primaryGreen : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Approve & Credit'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(RechargeRequestModel req) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D281E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text(
                'Reject Recharge',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting recharge of ₹${req.amount.toStringAsFixed(2)} for ${req.userName.isNotEmpty ? req.userName : req.userEmail}.',
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please provide the reason / remarks for rejection. The user will receive real-time notification with sound containing these remarks.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: remarksController,
                autofocus: true,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Rejection Remarks *',
                  hintText: 'e.g. UTR mismatch / Payment not received / Unclear receipt',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12),
                  labelStyle: const TextStyle(color: Color(0xFFFCA5A5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFDC2626), width: 1),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final remarks = remarksController.text.trim();
                if (remarks.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter remarks for rejection'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isProcessing = true);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final adminName = auth.fullName ?? auth.username ?? 'Admin';
                final walletProvider =
                    Provider.of<WalletProvider>(context, listen: false);

                final success = await walletProvider.rejectRecharge(
                  request: req,
                  adminName: adminName,
                  adminRemarks: remarks,
                );

                setState(() => _isProcessing = false);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Recharge request rejected. Real-time sound notification sent to user with remarks.'
                            : 'Failed to reject recharge: ${walletProvider.errorMessage ?? "Unknown error"}',
                      ),
                      backgroundColor:
                          success ? const Color(0xFFDC2626) : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Reject Request'),
            ),
          ],
        );
      },
    );
  }
}
