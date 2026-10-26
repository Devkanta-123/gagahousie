import 'dart:convert';

/// Model representing a user's wallet in `public.wallets`
class WalletModel {
  final dynamic id;
  final dynamic userId;
  final String userEmail;
  final double balance;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WalletModel({
    this.id,
    required this.userId,
    required this.userEmail,
    this.balance = 0.0,
    this.currency = 'INR',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      userId: json['user_id'],
      userEmail: json['user_email'] ?? '',
      balance: (json['balance'] is num)
          ? (json['balance'] as num).toDouble()
          : double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'balance': balance,
      'currency': currency,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  WalletModel copyWith({
    dynamic id,
    dynamic userId,
    String? userEmail,
    double? balance,
    String? currency,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model representing a transaction in `public.wallet_transactions`
class WalletTransactionModel {
  final dynamic id;
  final dynamic walletId;
  final dynamic userId;
  final double amount;
  final String type; // 'credit' | 'debit'
  final String category; // 'recharge' | 'ticket_purchase' | 'winning' | 'refund'
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final String? referenceId;
  final DateTime? createdAt;

  WalletTransactionModel({
    this.id,
    this.walletId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.referenceId,
    this.createdAt,
  });

  bool get isCredit => type.toLowerCase() == 'credit';
  bool get isDebit => type.toLowerCase() == 'debit';

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'],
      walletId: json['wallet_id'],
      userId: json['user_id'],
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'debit',
      category: json['category'] ?? 'ticket_purchase',
      balanceBefore: (json['balance_before'] is num)
          ? (json['balance_before'] as num).toDouble()
          : double.tryParse(json['balance_before']?.toString() ?? '0') ?? 0.0,
      balanceAfter: (json['balance_after'] is num)
          ? (json['balance_after'] as num).toDouble()
          : double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0.0,
      description: json['description'] ?? '',
      referenceId: json['reference_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (walletId != null) 'wallet_id': walletId,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'description': description,
      if (referenceId != null) 'reference_id': referenceId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

/// Model representing a recharge request in `public.recharge_requests`
class RechargeRequestModel {
  final dynamic id;
  final dynamic userId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final double amount;
  final String paymentMethod;
  final String transactionUtr;
  final String proofUrl;
  final String? accountNumber;
  final String? ifscCode;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? adminRemarks;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RechargeRequestModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.amount,
    this.paymentMethod = 'UPI',
    required this.transactionUtr,
    required this.proofUrl,
    this.accountNumber,
    this.ifscCode,
    this.status = 'pending',
    this.adminRemarks,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory RechargeRequestModel.fromJson(Map<String, dynamic> json) {
    return RechargeRequestModel(
      id: json['id'],
      userId: json['user_id'],
      userEmail: json['user_email'] ?? '',
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'UPI',
      transactionUtr: json['transaction_utr'] ?? '',
      proofUrl: json['proof_url'] ?? '',
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
      status: json['status'] ?? 'pending',
      adminRemarks: json['admin_remarks'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'user_phone': userPhone,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_utr': transactionUtr,
      'proof_url': proofUrl,
      if (accountNumber != null) 'account_number': accountNumber,
      if (ifscCode != null) 'ifsc_code': ifscCode,
      'status': status,
      if (adminRemarks != null) 'admin_remarks': adminRemarks,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  RechargeRequestModel copyWith({
    dynamic id,
    dynamic userId,
    String? userEmail,
    String? userName,
    String? userPhone,
    double? amount,
    String? paymentMethod,
    String? transactionUtr,
    String? proofUrl,
    String? accountNumber,
    String? ifscCode,
    String? status,
    String? adminRemarks,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RechargeRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionUtr: transactionUtr ?? this.transactionUtr,
      proofUrl: proofUrl ?? this.proofUrl,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model representing a notification in `public.user_notifications`
class UserNotificationModel {
  final dynamic id;
  final dynamic userId;
  final String title;
  final String message;
  final String type; // 'recharge_approved' | 'recharge_rejected' | 'ticket_purchased' | etc.
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  UserNotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.metadata = const {},
    this.createdAt,
  });

  bool get isRechargeApproved => type == 'recharge_approved';
  bool get isRechargeRejected => type == 'recharge_rejected';

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> meta = {};
    if (json['metadata'] != null) {
      if (json['metadata'] is Map) {
        meta = Map<String, dynamic>.from(json['metadata']);
      } else if (json['metadata'] is String) {
        try {
          meta = jsonDecode(json['metadata']);
        } catch (_) {}
      }
    }

    return UserNotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] == true,
      metadata: meta,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
