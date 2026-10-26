import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../services/supabase_service.dart';

/// Central State Provider for Wallet, Transactions, Recharges & Real-Time Alerts
class WalletProvider extends ChangeNotifier {
  final WalletService _service = WalletService.instance;
  final FlutterTts _flutterTts = FlutterTts();

  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  List<RechargeRequestModel> _userRecharges = [];
  List<RechargeRequestModel> _adminRecharges = [];
  List<UserNotificationModel> _notifications = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  dynamic _activeUserId;
  String? _activeUserEmail;
  bool _isAdmin = false;

  RealtimeChannel? _broadcastChannel;
  final List<RealtimeChannel> _activeCdcChannels = [];
  Timer? _fallbackPollTimer;

  RealtimeChannel? get _realtimeChannel => _broadcastChannel;

  final StreamController<UserNotificationModel> _alertStreamController =
      StreamController<UserNotificationModel>.broadcast();

  // Getters
  WalletModel? get wallet => _wallet;
  double get balance => _wallet?.balance ?? 0.0;
  String get formattedBalance => '₹${balance.toStringAsFixed(2)}';
  List<WalletTransactionModel> get transactions => _transactions;
  List<RechargeRequestModel> get userRecharges => _userRecharges;
  List<RechargeRequestModel> get adminRecharges => _adminRecharges;
  List<RechargeRequestModel> get pendingAdminRecharges =>
      _adminRecharges.where((r) => r.isPending).toList();
  List<UserNotificationModel> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  Stream<UserNotificationModel> get alertStream =>
      _alertStreamController.stream;

  WalletProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cleanupRealtime();
    _alertStreamController.close();
    super.dispose();
  }

  // ===========================================================================
  // 1. INITIALIZE & REALTIME SUBSCRIPTION
  // ===========================================================================

  /// Initialize wallet state for authenticated user or admin
  Future<void> initForUser({
    required dynamic userId,
    required String userEmail,
    bool isAdmin = false,
  }) async {
    _activeUserId = userId;
    _activeUserEmail = userEmail;
    _isAdmin = isAdmin;

    await refreshAll();
    _setupRealtimeSubscription();
  }

  /// Alias for initForUser
  Future<void> fetchOrCreateWallet({
    required dynamic userId,
    required String userEmail,
    bool isAdmin = false,
  }) =>
      initForUser(userId: userId, userEmail: userEmail, isAdmin: isAdmin);

  /// Quick refresh alias
  Future<void> refresh() => refreshAll();

  final List<String> _recentlyHandledAlerts = [];

  /// Sets up real-time notification listeners and peer-to-peer broadcast WebSocket
  void _setupRealtimeSubscription() {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      _cleanupRealtime();

      // 1. ISOLATED WEBSOCKET BROADCAST CHANNEL (Never fails even if tables are not published)
      _broadcastChannel = client.channel('gaga_broadcast_feed');

      _broadcastChannel!.onBroadcast(
        event: 'recharge_decision',
        callback: (payload) {
          debugPrint('⚡ [BROADCAST RECHARGE DECISION] $payload');
          final targetUserId = payload['user_id']?.toString();
          if (_activeUserId != null && targetUserId == _activeUserId.toString()) {
            final notification = UserNotificationModel(
              id: payload['notification_id'] ?? DateTime.now().millisecondsSinceEpoch,
              userId: _activeUserId,
              title: payload['title'] ?? 'Recharge Update',
              message: payload['message'] ?? '',
              type: payload['type'] ?? 'general',
              isRead: false,
              metadata: {
                if (payload['remarks'] != null) 'remarks': payload['remarks'],
                if (payload['amount'] != null) 'amount': payload['amount'],
              },
              createdAt: DateTime.now(),
            );
            _handleIncomingNotification(notification);
            refreshWalletOnly();
            fetchTransactions();
            fetchUserRecharges();
          }
        },
      );

      _broadcastChannel!.onBroadcast(
        event: 'new_recharge_submitted',
        callback: (payload) {
          debugPrint('⚡ [BROADCAST NEW RECHARGE SUBMITTED] $payload');
          if (_isAdmin) {
            final amount = payload['amount']?.toString() ?? '';
            final user = payload['user_name'] ?? 'A user';
            _playAlertSound(
              title: 'New Recharge Request',
              message: '$user submitted recharge for ₹$amount.',
            );
            fetchAdminRecharges();
          }
        },
      );

      _broadcastChannel!.onBroadcast(
        event: 'draw_started',
        callback: (payload) {
          debugPrint('⚡ [BROADCAST DRAW STARTED] $payload');
          // STRICT RULE: Draw started notifications go ONLY to regular user side, NEVER to Admin host!
          if (_isAdmin) {
            debugPrint(
                'ℹ️ [DRAW STARTED IGNORED] Host is Admin, skipping alert on host screen.');
            return;
          }

          final targetUserIds = (payload['user_ids'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final bool isTargeted = targetUserIds.isEmpty ||
              (_activeUserId != null &&
                  targetUserIds.contains(_activeUserId.toString()));

          if (isTargeted && _activeUserId != null) {
            final notification = UserNotificationModel(
              id: payload['notification_id'] ??
                  DateTime.now().millisecondsSinceEpoch,
              userId: _activeUserId,
              title: payload['title'] ?? '🎯 Housie Draw Started!',
              message: payload['message'] ??
                  'The draw has begun! Check your numbers now.',
              type: 'draw_started',
              isRead: false,
              metadata: {
                if (payload['ticket_id'] != null)
                  'ticket_id': payload['ticket_id'],
                if (payload['ticket_title'] != null)
                  'ticket_title': payload['ticket_title'],
              },
              createdAt: DateTime.now(),
            );
            _handleIncomingNotification(notification);
            fetchNotifications();
          }
        },
      );

      _broadcastChannel!.subscribe((status, error) {
        debugPrint('📡 [BROADCAST CHANNEL STATUS] $status ${error != null ? "Error: $error" : ""}');
      });

      // 2. ISOLATED CDC: wallets
      _subscribeTableCDC(
        table: 'wallets',
        onPayload: (payload) {
          debugPrint('🔔 [REALTIME WALLET BALANCE CDC] ${payload.eventType} => new:${payload.newRecord} old:${payload.oldRecord}');

          if (payload.eventType == PostgresChangeEvent.delete) {
            final oldRecord = payload.oldRecord;
            final oldUserId = oldRecord['user_id']?.toString();
            if (oldUserId == null || _activeUserId == null || oldUserId == _activeUserId.toString()) {
              debugPrint('⚡ [REALTIME WALLET RESET] Wallet deleted in DB. Resetting active user $_activeUserId balance to 0.00');
              _wallet = WalletModel(
                userId: _activeUserId,
                userEmail: _activeUserEmail ?? '',
                balance: 0.00,
                currency: 'INR',
                status: 'active',
              );
              _service.resetWallet(_activeUserId, _activeUserEmail ?? '');
              notifyListeners();
              refreshWalletOnly();
            }
            return;
          }

          final record = payload.newRecord;
          final targetUserId = record['user_id']?.toString();

          if (_activeUserId != null && targetUserId == _activeUserId.toString()) {
            final double newBalance = (record['balance'] is num)
                ? (record['balance'] as num).toDouble()
                : double.tryParse(record['balance']?.toString() ?? '0') ?? 0.0;
            if (_wallet != null) {
              _wallet = _wallet!.copyWith(balance: newBalance);
              notifyListeners();
            } else {
              refreshWalletOnly();
            }
          }
        },
      );

      // 3. ISOLATED CDC: wallet_transactions
      _subscribeTableCDC(
        table: 'wallet_transactions',
        onPayload: (payload) {
          debugPrint('🔔 [REALTIME TRANSACTIONS CDC] ${payload.eventType} => new:${payload.newRecord} old:${payload.oldRecord}');
          if (payload.eventType == PostgresChangeEvent.delete) {
            final oldId = payload.oldRecord['id'];
            if (oldId != null) {
              _transactions.removeWhere((t) => t.id?.toString() == oldId.toString());
              notifyListeners();
            } else {
              _transactions.clear();
              notifyListeners();
            }
            _service.clearFallbackTransactions();
          }
          fetchTransactions();
          refreshWalletOnly();
        },
      );

      // 4. ISOLATED CDC: recharge_requests
      _subscribeTableCDC(
        table: 'recharge_requests',
        onPayload: (payload) {
          debugPrint('🔔 [REALTIME RECHARGE CDC] ${payload.eventType} => new:${payload.newRecord} old:${payload.oldRecord}');
          
          if (payload.eventType == PostgresChangeEvent.delete) {
            final oldId = payload.oldRecord['id'];
            if (oldId != null) {
              _userRecharges.removeWhere((r) => r.id?.toString() == oldId.toString());
              _adminRecharges.removeWhere((r) => r.id?.toString() == oldId.toString());
              notifyListeners();
            } else {
              _userRecharges.clear();
              _adminRecharges.clear();
              notifyListeners();
            }
            _service.clearFallbackRecharges();
            fetchUserRecharges();
            if (_isAdmin) fetchAdminRecharges();
            return;
          }

          final record = payload.newRecord;
          final reqUserId = record['user_id']?.toString();

          // If Admin: new recharge request submitted
          if (_isAdmin) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              _playAlertSound(
                title: 'New Recharge Request',
                message: 'A user submitted ₹${record['amount'] ?? ''} for approval.',
              );
            }
            fetchAdminRecharges();
          }

          // If User: admin updated request status (Approved or Rejected)
          if (_activeUserId != null && (reqUserId == null || reqUserId == _activeUserId.toString())) {
            fetchUserRecharges();
            refreshWalletOnly();
            fetchTransactions();
          }
        },
      );

      // 5. ISOLATED CDC: user_notifications
      _subscribeTableCDC(
        table: 'user_notifications',
        onPayload: (payload) {
          debugPrint('🔔 [REALTIME NOTIFICATION CDC] ${payload.eventType} => new:${payload.newRecord} old:${payload.oldRecord}');
          
          if (payload.eventType == PostgresChangeEvent.delete) {
            final oldId = payload.oldRecord['id'];
            if (oldId != null) {
              _notifications.removeWhere((n) => n.id?.toString() == oldId.toString());
              notifyListeners();
            } else {
              _notifications.clear();
              notifyListeners();
            }
            _service.clearFallbackNotifications();
            fetchNotifications();
            return;
          }

          final record = payload.newRecord;
          final targetUserId = record['user_id']?.toString();

          if (_activeUserId != null && targetUserId == _activeUserId.toString()) {
            final notification = UserNotificationModel.fromJson(record);
            _handleIncomingNotification(notification);
          }
        },
      );
    } catch (e) {
      debugPrint('ℹ️ [REALTIME SUBSCRIPTION NOTICE] $e');
    }
  }

  void _subscribeTableCDC({
    required String table,
    required void Function(PostgresChangePayload payload) onPayload,
  }) {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      final channel = client.channel('gaga_cdc_$table');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: onPayload,
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint('ℹ️ [REALTIME NOTICE] "$table" is not in supabase_realtime publication yet. Polling fallback active.');
          _startFallbackPolling();
        } else if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('✅ [REALTIME CDC SUBSCRIBED] $table');
        }
      });

      _activeCdcChannels.add(channel);
    } catch (e) {
      debugPrint('ℹ️ [CDC SUBSCRIBE NOTICE] $table: $e');
    }
  }

  void _startFallbackPolling() {
    if (_fallbackPollTimer != null && _fallbackPollTimer!.isActive) return;
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_activeUserId != null) {
        refreshWalletOnly();
        fetchTransactions();
        fetchUserRecharges();
        fetchNotifications();
      }
      if (_isAdmin) {
        fetchAdminRecharges();
      }
    });
  }

  void _cleanupRealtime() {
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
    for (final ch in _activeCdcChannels) {
      try {
        ch.unsubscribe();
      } catch (_) {}
    }
    _activeCdcChannels.clear();
    _fallbackPollTimer?.cancel();
    _fallbackPollTimer = null;
  }

  /// Handle incoming real-time notification with audio sound & visual alert (deduplicated)
  void _handleIncomingNotification(UserNotificationModel notification) {
    // Only regular users receive draw started alerts, never the Admin host
    if (_isAdmin &&
        (notification.type == 'draw_started' ||
            notification.title.contains('Draw Started'))) {
      debugPrint(
          'ℹ️ [ALERT FILTER] Skipping draw started notification on Admin host.');
      return;
    }

    final alertKey = '${notification.id ?? ""}_${notification.title}_${notification.message}';
    if (_recentlyHandledAlerts.contains(alertKey)) {
      return;
    }
    _recentlyHandledAlerts.add(alertKey);
    if (_recentlyHandledAlerts.length > 50) {
      _recentlyHandledAlerts.removeAt(0);
    }

    final existingIdx = _notifications.indexWhere((n) =>
        (notification.id != null && n.id == notification.id) ||
        (n.title == notification.title && n.message == notification.message));

    if (existingIdx != -1) {
      _notifications[existingIdx] = notification;
    } else {
      _notifications.insert(0, notification);
    }

    _playAlertSound(title: notification.title, message: notification.message);
    _alertStreamController.add(notification);
    refreshWalletOnly();
    notifyListeners();
  }

  /// Plays native device alert sound, triggers haptic vibration, and vocalizes TTS announcement
  Future<void> _playAlertSound({required String title, required String message}) async {
    try {
      // 1. Play Native Device Alert Audio Sound
      await SystemSound.play(SystemSoundType.alert);

      // 2. Heavy Haptic Feedback
      await HapticFeedback.heavyImpact();

      // 3. Clear Voice Announcement
      if (title.contains('Approved')) {
        await _flutterTts.speak('Payment Approved! Your wallet has been credited.');
      } else if (title.contains('Rejected')) {
        await _flutterTts.speak('Payment Rejected. $message');
      } else if (title.contains('Draw') || title.contains('Housie')) {
        await _flutterTts.speak('Attention players! The Housie draw has officially started. Best of luck!');
      } else {
        await _flutterTts.speak('$title. $message');
      }
    } catch (e) {
      debugPrint('🔔 [SOUND ALERT ERROR] $e');
    }
  }

  // ===========================================================================
  // 2. FETCH & REFRESH DATA
  // ===========================================================================

  Future<void> refreshAll() async {
    if (_activeUserId == null && _activeUserEmail == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        refreshWalletOnly(),
        fetchTransactions(),
        fetchUserRecharges(),
        if (_isAdmin) fetchAdminRecharges(),
        fetchNotifications(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWalletOnly() async {
    if (_activeUserId == null && _activeUserEmail == null) return;
    try {
      _wallet = await _service.fetchOrCreateWallet(_activeUserId, _activeUserEmail ?? '');
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTransactions() async {
    if (_activeUserId == null) return;
    try {
      _transactions = await _service.fetchTransactions(_activeUserId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchUserRecharges() async {
    if (_activeUserId == null) return;
    try {
      _userRecharges = await _service.fetchUserRecharges(_activeUserId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchAdminRecharges() async {
    try {
      _adminRecharges = await _service.fetchAllRechargesForAdmin();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchNotifications() async {
    if (_activeUserId == null) return;
    try {
      _notifications = await _service.fetchUserNotifications(_activeUserId);
      notifyListeners();
    } catch (_) {}
  }

  // ===========================================================================
  // 3. SUBMIT RECHARGE (USER)
  // ===========================================================================

  Future<bool> submitRecharge({
    required double amount,
    required String paymentMethod,
    required String transactionUtr,
    required File proofFile,
    String? accountNumber,
    String? ifscCode,
    required String userName,
    required String userPhone,
    dynamic userId,
    String? userEmail,
  }) async {
    final effectiveUserId = userId ?? _activeUserId;
    final effectiveUserEmail = userEmail ?? _activeUserEmail;

    if (effectiveUserId == null || effectiveUserEmail == null) {
      _errorMessage = 'Please log in to recharge your wallet';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload proof file (Supabase storage or base64 data URI fallback)
      final proofUrl = await _service.uploadPaymentProof(proofFile, effectiveUserId);

      // 2. Submit recharge request
      final request = await _service.submitRechargeRequest(
        userId: effectiveUserId,
        userEmail: effectiveUserEmail,
        userName: userName,
        userPhone: userPhone,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionUtr: transactionUtr,
        proofUrl: proofUrl,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
      );

      _userRecharges.insert(0, request);

      // Instant broadcast to admin listeners
      try {
        _realtimeChannel?.sendBroadcastMessage(
          event: 'new_recharge_submitted',
          payload: {
            'amount': amount,
            'user_name': userName,
            'user_id': effectiveUserId.toString(),
          },
        );
      } catch (_) {}

      _playAlertSound(
        title: 'Recharge Submitted',
        message: 'Your recharge request is pending admin verification.',
      );
      await fetchNotifications();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to submit recharge: $e';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // 4. ADMIN APPROVE / REJECT
  // ===========================================================================

  Future<bool> approveRecharge({
    required RechargeRequestModel request,
    String? adminEmail,
    String? adminName,
    String? remarks,
    String? adminRemarks,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final effectiveAdminEmail = adminEmail ?? _activeUserEmail ?? 'admin@gagahousie.com';
    final effectiveRemarks = remarks ?? adminRemarks;

    final success = await _service.approveRechargeRequest(
      request: request,
      adminEmail: effectiveAdminEmail,
      remarks: effectiveRemarks,
    );

    if (success) {
      // Instant peer-to-peer broadcast alert to user
      try {
        _realtimeChannel?.sendBroadcastMessage(
          event: 'recharge_decision',
          payload: {
            'user_id': request.userId.toString(),
            'type': 'recharge_approved',
            'title': 'Recharge Approved!',
            'message':
                '₹${request.amount.toStringAsFixed(2)} has been credited to your wallet.',
            'remarks': effectiveRemarks,
            'amount': request.amount,
            'notification_id': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (_) {}

      await fetchAdminRecharges();
      if (_activeUserId == request.userId) {
        await refreshWalletOnly();
        await fetchTransactions();
      }
    }

    _isSubmitting = false;
    notifyListeners();
    return success;
  }

  Future<bool> rejectRecharge({
    required RechargeRequestModel request,
    String? adminEmail,
    String? adminName,
    String? remarks,
    String? adminRemarks,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final effectiveAdminEmail = adminEmail ?? _activeUserEmail ?? 'admin@gagahousie.com';
    final effectiveRemarks = (remarks ?? adminRemarks) ?? 'Payment verification rejected';

    final success = await _service.rejectRechargeRequest(
      request: request,
      adminEmail: effectiveAdminEmail,
      remarks: effectiveRemarks,
    );

    if (success) {
      // Instant peer-to-peer broadcast alert to user
      try {
        _realtimeChannel?.sendBroadcastMessage(
          event: 'recharge_decision',
          payload: {
            'user_id': request.userId.toString(),
            'type': 'recharge_rejected',
            'title': 'Recharge Rejected',
            'message':
                'Your recharge of ₹${request.amount.toStringAsFixed(2)} was rejected: $effectiveRemarks',
            'remarks': effectiveRemarks,
            'amount': request.amount,
            'notification_id': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (_) {}

      await fetchAdminRecharges();
    }

    _isSubmitting = false;
    notifyListeners();
    return success;
  }

  // ===========================================================================
  // 5. ATOMIC TICKET PURCHASE DEDUCTION
  // ===========================================================================

  Future<bool> deductForPurchase({
    double? totalAmount,
    double? amount,
    String? ticketTitle,
    String? description,
    String? ticketId,
    String? referenceId,
    dynamic userId,
    String? userEmail,
  }) async {
    final effectiveUserId = userId ?? _activeUserId;
    final effectiveUserEmail = userEmail ?? _activeUserEmail;
    final effectiveAmount = totalAmount ?? amount ?? 0.0;
    final effectiveTitle = ticketTitle ?? description ?? 'Tambola Ticket';
    final effectiveTicketId = ticketId ?? referenceId ?? 'TKT-001';

    if (effectiveUserId == null || effectiveUserEmail == null) {
      throw const InsufficientBalanceException(0, 0);
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tx = await _service.deductWalletForPurchase(
        userId: effectiveUserId,
        userEmail: effectiveUserEmail,
        totalAmount: effectiveAmount,
        ticketTitle: effectiveTitle,
        ticketId: effectiveTicketId,
      );

      _transactions.insert(0, tx);
      if (_wallet != null) {
        _wallet = _wallet!.copyWith(balance: tx.balanceAfter);
      }
      await fetchNotifications();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on InsufficientBalanceException {
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Purchase transaction failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> markNotificationAsRead(dynamic notificationId) async {
    await _service.markNotificationAsRead(notificationId);
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = UserNotificationModel(
        id: _notifications[idx].id,
        userId: _notifications[idx].userId,
        title: _notifications[idx].title,
        message: _notifications[idx].message,
        type: _notifications[idx].type,
        isRead: true,
        metadata: _notifications[idx].metadata,
        createdAt: _notifications[idx].createdAt,
      );
      notifyListeners();
    }
  }
}
