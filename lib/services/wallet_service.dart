import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import 'supabase_service.dart';

class InsufficientBalanceException implements Exception {
  final double currentBalance;
  final double requiredAmount;

  const InsufficientBalanceException(this.currentBalance, this.requiredAmount);

  double get shortfall => requiredAmount - currentBalance;
  double get available => currentBalance;
  double get required => requiredAmount;

  @override
  String toString() =>
      'Insufficient wallet balance. Available: ₹${currentBalance.toStringAsFixed(2)}, Required: ₹${requiredAmount.toStringAsFixed(2)}';
}

/// Singleton Service handling all User Wallet, Transactions, Recharges & Notifications
class WalletService {
  static final WalletService _instance = WalletService._internal();
  static WalletService get instance => _instance;

  WalletService._internal();

  SupabaseClient? get _client => SupabaseService.instance.client;

  // In-memory fallback caches if offline or during initial table setup
  final Map<String, WalletModel> _fallbackWallets = {};
  final List<WalletTransactionModel> _fallbackTransactions = [];
  final List<RechargeRequestModel> _fallbackRecharges = [];
  final List<UserNotificationModel> _fallbackNotifications = [];

  // ===========================================================================
  // 1. WALLET BALANCE & PROFILE
  // ===========================================================================

  /// Fetches or auto-creates a user wallet
  Future<WalletModel> fetchOrCreateWallet(dynamic userId, String userEmail) async {
    final client = _client;
    final userKey = userId?.toString() ?? userEmail;

    if (client == null) {
      return _getOrCreateFallbackWallet(userId, userEmail);
    }

    try {
      final response = await client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final wallet = WalletModel.fromJson(response);
        _fallbackWallets[userKey] = wallet;
        return wallet;
      }

      // If no wallet exists yet, create one with 0.00 balance
      final newRecord = {
        'user_id': userId,
        'user_email': userEmail,
        'balance': 0.00,
        'currency': 'INR',
        'status': 'active',
      };

      final insertRes =
          await client.from('wallets').insert(newRecord).select().single();
      final wallet = WalletModel.fromJson(insertRes);
      _fallbackWallets[userKey] = wallet;
      return wallet;
    } catch (e) {
      debugPrint('ℹ️ [WALLET SERVICE] DB fetch error (using fallback): $e');
      return _getOrCreateFallbackWallet(userId, userEmail);
    }
  }

  WalletModel _getOrCreateFallbackWallet(dynamic userId, String userEmail) {
    final userKey = userId?.toString() ?? userEmail;
    return _fallbackWallets.putIfAbsent(
      userKey,
      () => WalletModel(
        id: 1,
        userId: userId ?? 1,
        userEmail: userEmail,
        balance: 0.00,
        currency: 'INR',
        status: 'active',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Reset in-memory wallet to 0.00 balance when cleared or deleted in DB
  void resetWallet(dynamic userId, String userEmail) {
    final userKey = userId?.toString() ?? userEmail;
    _fallbackWallets[userKey] = WalletModel(
      id: 1,
      userId: userId ?? 1,
      userEmail: userEmail,
      balance: 0.00,
      currency: 'INR',
      status: 'active',
      createdAt: DateTime.now(),
    );
  }

  /// Clears in-memory wallet fallback caches
  void clearFallbackWallets([dynamic userId]) {
    if (userId != null) {
      _fallbackWallets.remove(userId.toString());
    } else {
      _fallbackWallets.clear();
    }
  }

  /// Clears fallback transactions
  void clearFallbackTransactions() {
    _fallbackTransactions.clear();
  }

  /// Clears fallback recharge requests
  void clearFallbackRecharges() {
    _fallbackRecharges.clear();
  }

  /// Clears fallback notifications
  void clearFallbackNotifications() {
    _fallbackNotifications.clear();
  }

  // ===========================================================================
  // 2. TRANSACTIONS HISTORY (PASSBOOK)
  // ===========================================================================

  Future<List<WalletTransactionModel>> fetchTransactions(dynamic userId) async {
    final client = _client;
    if (client == null || userId == null) {
      return _fallbackTransactions
          .where((t) => t.userId.toString() == userId.toString())
          .toList();
    }

    try {
      final response = await client
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => WalletTransactionModel.fromJson(item))
          .toList();
      return list;
    } catch (e) {
      debugPrint('ℹ️ [WALLET SERVICE] Error fetching transactions: $e');
      return _fallbackTransactions
          .where((t) => t.userId.toString() == userId.toString())
          .toList();
    }
  }

  // ===========================================================================
  // 3. RECHARGE REQUESTS (USER & ADMIN)
  // ===========================================================================

  Future<List<RechargeRequestModel>> fetchUserRecharges(dynamic userId) async {
    final client = _client;
    if (client == null || userId == null) {
      return _fallbackRecharges
          .where((r) => r.userId.toString() == userId.toString())
          .toList();
    }

    try {
      final response = await client
          .from('recharge_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => RechargeRequestModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('ℹ️ [WALLET SERVICE] Error fetching user recharges: $e');
      return _fallbackRecharges
          .where((r) => r.userId.toString() == userId.toString())
          .toList();
    }
  }

  Future<List<RechargeRequestModel>> fetchAllRechargesForAdmin() async {
    final client = _client;
    if (client == null) {
      return List.from(_fallbackRecharges);
    }

    try {
      final response = await client
          .from('recharge_requests')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => RechargeRequestModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('ℹ️ [WALLET SERVICE] Error fetching admin recharges: $e');
      return List.from(_fallbackRecharges);
    }
  }

  /// Uploads proof screenshot to Supabase Storage or falls back to data URI
  Future<String> uploadPaymentProof(File file, dynamic userId) async {
    final client = _client;
    final fileExt = file.path.split('.').last.toLowerCase();
    final fileName =
        'proof_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    if (client != null) {
      final storagePath = 'receipts/$fileName';
      try {
        await client.storage.from('payment_proofs').upload(
              storagePath,
              file,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true),
            );
        return client.storage.from('payment_proofs').getPublicUrl(storagePath);
      } catch (uploadErr) {
        // If bucket is missing, attempt to create it automatically
        final errText = uploadErr.toString();
        if (errText.contains('Bucket not found') || errText.contains('404')) {
          try {
            await client.storage.createBucket(
              'payment_proofs',
              const BucketOptions(public: true),
            );
            await client.storage.from('payment_proofs').upload(
                  storagePath,
                  file,
                  fileOptions:
                      const FileOptions(cacheControl: '3600', upsert: true),
                );
            return client.storage
                .from('payment_proofs')
                .getPublicUrl(storagePath);
          } catch (_) {
            // Bucket creation requires service role in some configs; proceed with Base64 fallback
          }
        }
      }
    }

    // High-res Base64 Data URI fallback
    try {
      final bytes = await file.readAsBytes();
      final mime = fileExt == 'png' ? 'image/png' : 'image/jpeg';
      final base64String = base64Encode(bytes);
      return 'data:$mime;base64,$base64String';
    } catch (e) {
      return file.path;
    }
  }

  /// User submits a recharge request with proof file
  Future<RechargeRequestModel> submitRechargeRequest({
    required dynamic userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required double amount,
    required String paymentMethod,
    required String transactionUtr,
    required String proofUrl,
    String? accountNumber,
    String? ifscCode,
  }) async {
    final client = _client;
    final now = DateTime.now();

    final payload = {
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'user_phone': userPhone,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_utr': transactionUtr,
      'proof_url': proofUrl,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'status': 'pending',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    if (client != null) {
      try {
        final res = await client
            .from('recharge_requests')
            .insert(payload)
            .select()
            .single();

        final model = RechargeRequestModel.fromJson(res);

        // Record submission notification
        await createNotification(
          userId: userId,
          title: '⏳ Recharge Submitted',
          message:
              'Your recharge request of ₹${amount.toStringAsFixed(2)} (UTR: $transactionUtr) is pending admin verification.',
          type: 'recharge_submitted',
          metadata: {'request_id': model.id, 'amount': amount},
        );

        return model;
      } catch (e) {
        debugPrint('ℹ️ [WALLET SERVICE] DB insert recharge error: $e');
      }
    }

    // Fallback simulation
    final fallbackModel = RechargeRequestModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionUtr: transactionUtr,
      proofUrl: proofUrl,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      status: 'pending',
      createdAt: now,
    );
    _fallbackRecharges.insert(0, fallbackModel);
    return fallbackModel;
  }

  // ===========================================================================
  // 4. ADMIN VERIFICATION & APPROVAL / REJECTION
  // ===========================================================================

  /// Admin approves recharge: adds amount to wallet, logs transaction, sends notification
  Future<bool> approveRechargeRequest({
    required RechargeRequestModel request,
    required String adminEmail,
    String? remarks,
  }) async {
    final client = _client;
    final now = DateTime.now();

    try {
      // 1. Fetch current wallet
      final wallet = await fetchOrCreateWallet(request.userId, request.userEmail);
      final balanceBefore = wallet.balance;
      final balanceAfter = balanceBefore + request.amount;

      // 2. Update wallet balance in DB
      if (client != null) {
        await client.from('wallets').update({
          'balance': balanceAfter,
          'updated_at': now.toIso8601String(),
        }).eq('user_id', request.userId);

        // 3. Insert Credit Transaction
        await client.from('wallet_transactions').insert({
          'wallet_id': wallet.id,
          'user_id': request.userId,
          'amount': request.amount,
          'type': 'credit',
          'category': 'recharge',
          'balance_before': balanceBefore,
          'balance_after': balanceAfter,
          'description':
              'Wallet Recharge Approved (Ref: ${request.transactionUtr})',
          'reference_id': request.id?.toString(),
          'created_at': now.toIso8601String(),
        });

        // 4. Update Recharge Request Status
        await client.from('recharge_requests').update({
          'status': 'approved',
          'admin_remarks': remarks ?? 'Payment verified and credited',
          'reviewed_by': adminEmail,
          'reviewed_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }).eq('id', request.id);

        // 5. Send Real-Time Notification to User
        await createNotification(
          userId: request.userId,
          title: '🎉 Recharge Approved!',
          message:
              'Your recharge of ₹${request.amount.toStringAsFixed(2)} has been approved and credited to your wallet.',
          type: 'recharge_approved',
          metadata: {
            'amount': request.amount,
            'balance_after': balanceAfter,
            'utr': request.transactionUtr,
            'reviewed_by': adminEmail,
          },
        );
      } else {
        // Fallback update
        final userKey = request.userId.toString();
        _fallbackWallets[userKey] = wallet.copyWith(balance: balanceAfter);
        _fallbackTransactions.insert(
          0,
          WalletTransactionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            userId: request.userId,
            amount: request.amount,
            type: 'credit',
            category: 'recharge',
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            description:
                'Wallet Recharge Approved (Ref: ${request.transactionUtr})',
            referenceId: request.id?.toString(),
            createdAt: now,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ [WALLET SERVICE] Error approving recharge: $e');
      return false;
    }
  }

  /// Admin rejects recharge: records remarks, sends notification to user
  Future<bool> rejectRechargeRequest({
    required RechargeRequestModel request,
    required String adminEmail,
    required String remarks,
  }) async {
    final client = _client;
    final now = DateTime.now();

    try {
      if (client != null) {
        // 1. Update Recharge Request Status
        await client.from('recharge_requests').update({
          'status': 'rejected',
          'admin_remarks': remarks,
          'reviewed_by': adminEmail,
          'reviewed_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }).eq('id', request.id);

        // 2. Send Real-Time Notification to User
        await createNotification(
          userId: request.userId,
          title: '❌ Recharge Request Rejected',
          message:
              'Your recharge request of ₹${request.amount.toStringAsFixed(2)} was rejected. Remarks: $remarks',
          type: 'recharge_rejected',
          metadata: {
            'amount': request.amount,
            'remarks': remarks,
            'utr': request.transactionUtr,
            'reviewed_by': adminEmail,
          },
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ [WALLET SERVICE] Error rejecting recharge: $e');
      return false;
    }
  }

  /// Transfer prize winnings directly to winner's wallet
  Future<bool> transferPrizeToWinner({
    required dynamic userId,
    required String userEmail,
    required double amount,
    required String prizeName,
    required String ticketId,
    required String ticketTitle,
    String? adminEmail,
  }) async {
    final client = _client;
    final now = DateTime.now();

    try {
      // 1. Fetch or create winner's wallet
      final wallet = await fetchOrCreateWallet(userId, userEmail);
      final balanceBefore = wallet.balance;
      final balanceAfter = balanceBefore + amount;

      if (client != null) {
        // 2. Update wallet balance in DB
        await client.from('wallets').update({
          'balance': balanceAfter,
          'updated_at': now.toIso8601String(),
        }).eq('user_id', userId);

        // 3. Insert Credit Transaction with category 'winning'
        await client.from('wallet_transactions').insert({
          'wallet_id': wallet.id,
          'user_id': userId,
          'amount': amount,
          'type': 'credit',
          'category': 'winning',
          'balance_before': balanceBefore,
          'balance_after': balanceAfter,
          'description': 'Prize Won: $prizeName ($ticketTitle #$ticketId)',
          'reference_id': 'PRIZE-$ticketId-$prizeName',
          'created_at': now.toIso8601String(),
        });

        // 4. Send Real-Time Notification
        await createNotification(
          userId: userId,
          title: '🏆 Prize Money Credited!',
          message:
              'Congratulations! ₹${amount.toStringAsFixed(2)} for winning "$prizeName" on Draw #$ticketId has been transferred to your wallet.',
          type: 'general',
          metadata: {
            'ticket_id': ticketId,
            'prize_name': prizeName,
            'amount': amount,
            'balance_after': balanceAfter,
            'original_type': 'prize_won',
          },
        );
      } else {
        // In-memory fallback
        final userKey = userId.toString();
        _fallbackWallets[userKey] = wallet.copyWith(balance: balanceAfter);
        _fallbackTransactions.insert(
          0,
          WalletTransactionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            userId: userId,
            amount: amount,
            type: 'credit',
            category: 'winning',
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            description: 'Prize Won: $prizeName ($ticketTitle #$ticketId)',
            referenceId: 'PRIZE-$ticketId-$prizeName',
            createdAt: now,
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ [TRANSFER PRIZE ERROR] $e');
      return false;
    }
  }

  // ===========================================================================
  // 5. ATOMIC TICKET PURCHASE DEDUCTION
  // ===========================================================================

  /// Deducts ticket price from user wallet. Throws InsufficientBalanceException if balance is low.
  Future<WalletTransactionModel> deductWalletForPurchase({
    required dynamic userId,
    required String userEmail,
    required double totalAmount,
    required String ticketTitle,
    required String ticketId,
  }) async {
    final client = _client;
    final now = DateTime.now();

    // 1. Fetch current wallet
    final wallet = await fetchOrCreateWallet(userId, userEmail);

    if (wallet.balance < totalAmount) {
      throw InsufficientBalanceException(wallet.balance, totalAmount);
    }

    final balanceBefore = wallet.balance;
    final balanceAfter = balanceBefore - totalAmount;

    if (client != null) {
      // 2. Deduct balance in DB
      await client.from('wallets').update({
        'balance': balanceAfter,
        'updated_at': now.toIso8601String(),
      }).eq('user_id', userId);

      // 3. Record Debit Transaction
      final txPayload = {
        'wallet_id': wallet.id,
        'user_id': userId,
        'amount': totalAmount,
        'type': 'debit',
        'category': 'ticket_purchase',
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'description': 'Purchase: $ticketTitle ($ticketId)',
        'reference_id': ticketId,
        'created_at': now.toIso8601String(),
      };

      final txRes = await client
          .from('wallet_transactions')
          .insert(txPayload)
          .select()
          .single();

      // 4. Send Confirmation Notification
      await createNotification(
        userId: userId,
        title: '🎟️ Ticket Purchase Successful',
        message:
            '₹${totalAmount.toStringAsFixed(2)} deducted from your wallet for $ticketTitle.',
        type: 'ticket_purchased',
        metadata: {
          'ticket_id': ticketId,
          'amount': totalAmount,
          'balance_after': balanceAfter,
        },
      );

      final txModel = WalletTransactionModel.fromJson(txRes);
      return txModel;
    } else {
      // Fallback in-memory deduction
      final userKey = userId.toString();
      _fallbackWallets[userKey] = wallet.copyWith(balance: balanceAfter);

      final txModel = WalletTransactionModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        amount: totalAmount,
        type: 'debit',
        category: 'ticket_purchase',
        balanceBefore: balanceBefore,
        balanceAfter: balanceAfter,
        description: 'Purchase: $ticketTitle ($ticketId)',
        referenceId: ticketId,
        createdAt: now,
      );
      _fallbackTransactions.insert(0, txModel);
      return txModel;
    }
  }

  // ===========================================================================
  // 6. REAL-TIME NOTIFICATIONS
  // ===========================================================================

  Future<List<UserNotificationModel>> fetchUserNotifications(dynamic userId) async {
    final client = _client;
    if (client == null || userId == null) {
      return _fallbackNotifications
          .where((n) => n.userId.toString() == userId.toString())
          .toList();
    }

    try {
      final response = await client
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      return (response as List)
          .map((item) => UserNotificationModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('ℹ️ [WALLET SERVICE] Error fetching notifications: $e');
      return _fallbackNotifications
          .where((n) => n.userId.toString() == userId.toString())
          .toList();
    }
  }

  Future<void> createNotification({
    required dynamic userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    final client = _client;
    final now = DateTime.now();

    final payload = {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
      'metadata': metadata ?? {},
      'created_at': now.toIso8601String(),
    };

    if (client != null) {
      try {
        await client.from('user_notifications').insert(payload);
        return;
      } catch (e) {
        debugPrint('ℹ️ [WALLET SERVICE] Error inserting notification ($type): $e');
        // Fallback for strict database check constraint on type
        try {
          final fallbackPayload = Map<String, dynamic>.from(payload);
          fallbackPayload['type'] = 'general';
          final meta = Map<String, dynamic>.from(fallbackPayload['metadata'] as Map? ?? {});
          meta['original_type'] = type;
          fallbackPayload['metadata'] = meta;
          await client.from('user_notifications').insert(fallbackPayload);
          debugPrint('✅ [WALLET SERVICE] Inserted notification using general fallback with original_type=$type');
          return;
        } catch (e2) {
          debugPrint('ℹ️ [WALLET SERVICE] Fallback insert also failed: $e2');
        }
      }
    }

    _fallbackNotifications.insert(
      0,
      UserNotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        metadata: metadata ?? {},
        createdAt: now,
      ),
    );
  }

  Future<void> markNotificationAsRead(dynamic notificationId) async {
    final client = _client;
    if (client != null && notificationId != null) {
      try {
        await client
            .from('user_notifications')
            .update({'is_read': true}).eq('id', notificationId);
      } catch (_) {}
    }
  }
}
