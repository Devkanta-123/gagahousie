class PrizeItem {
  String name;
  String price;

  PrizeItem({required this.name, required this.price});

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };

  factory PrizeItem.fromJson(Map<String, dynamic> json) => PrizeItem(
        name: json['name'] ?? '',
        price: json['price'] ?? '',
      );

  PrizeItem copyWith({String? name, String? price}) {
    return PrizeItem(
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}

class TicketModel {
  final dynamic id;
  final String ticketId;
  final String ticketTitle;
  final String drawDate;
  final String drawTime;
  final String price;
  final String totalPrize;
  final List<PrizeItem> prizes;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;

  TicketModel({
    this.id,
    required this.ticketId,
    required this.ticketTitle,
    required this.drawDate,
    required this.drawTime,
    this.price = '₹20',
    this.totalPrize = '₹75000',
    required this.prizes,
    this.status = 'Active',
    this.createdBy,
    this.createdAt,
  });

  TicketModel copyWith({
    dynamic id,
    String? ticketId,
    String? ticketTitle,
    String? drawDate,
    String? drawTime,
    String? price,
    String? totalPrize,
    List<PrizeItem>? prizes,
    String? status,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      ticketTitle: ticketTitle ?? this.ticketTitle,
      drawDate: drawDate ?? this.drawDate,
      drawTime: drawTime ?? this.drawTime,
      price: price ?? this.price,
      totalPrize: totalPrize ?? this.totalPrize,
      prizes: prizes ?? this.prizes,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Autogenerate a ticket ID like GAGA26000001
  static String generateTicketId([int sequence = 1]) {
    final yearTwoDigits =
        (DateTime.now().year % 100).toString().padLeft(2, '0');
    final seqStr = sequence.toString().padLeft(6, '0');
    return 'GAGA$yearTwoDigits$seqStr';
  }

  /// Default standard prize list requested by user
  static List<PrizeItem> defaultPrizes() {
    return [
      PrizeItem(name: 'Housefull', price: '₹50000'),
      PrizeItem(name: '1st Line', price: '₹3000'),
      PrizeItem(name: '2nd Line', price: '₹3000'),
      PrizeItem(name: '3rd Line', price: '₹3000'),
      PrizeItem(name: '4th Corner', price: '₹3000'),
      PrizeItem(name: 'Quick Five', price: '₹3000'),
      PrizeItem(name: '3 Ticket Quick', price: '₹10000'),
    ];
  }

  /// Sum total value of all prizes
  int get calculatedTotalPrize {
    int sum = 0;
    for (final prize in prizes) {
      final clean = prize.price.replaceAll(RegExp(r'[^0-9]'), '');
      sum += int.tryParse(clean) ?? 0;
    }
    return sum;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ticket_id': ticketId,
      'ticket_title': ticketTitle,
      'draw_date': drawDate,
      'draw_time': drawTime,
      'price': price,
      'total_prize': totalPrize,
      'prizes': prizes.map((p) => p.toJson()).toList(),
      'status': status,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    List<PrizeItem> parsedPrizes = [];
    if (json['prizes'] != null) {
      if (json['prizes'] is List) {
        parsedPrizes = (json['prizes'] as List)
            .map((e) => PrizeItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    if (parsedPrizes.isEmpty) {
      parsedPrizes = defaultPrizes();
    }

    return TicketModel(
      id: json['id'],
      ticketId:
          json['ticket_id'] ?? json['id']?.toString() ?? generateTicketId(),
      ticketTitle: json['ticket_title'] ?? json['ticket'] ?? 'GaGa Housie Draw',
      drawDate: json['draw_date'] ?? json['date'] ?? '25/09/2026',
      drawTime: json['draw_time'] ?? json['time'] ?? '08:00 PM',
      price: json['price'] ?? '₹20',
      totalPrize: json['total_prize'] ?? '₹75000',
      prizes: parsedPrizes,
      status: json['status'] ?? 'Active',
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Format compatible with HomeTab carousel
  Map<String, dynamic> toUpcomingMap() {
    return {
      'ticket': ticketTitle,
      'date': drawDate,
      'time': drawTime,
      'id': ticketId,
      'price': price,
      'prizes': prizes.map((p) => p.toJson()).toList(),
    };
  }

  /// Format compatible with TicketsTab list
  Map<String, String> toLiveTicketMap() {
    return {
      'ticket': ticketTitle,
      'date': drawDate,
      'price': price,
      'status': status,
      'id': ticketId,
    };
  }
}
