/// Model representing a user's purchased Tambola Ticket stored in DB
class TicketPurchaseModel {
  final dynamic id;
  final dynamic userId;
  final String userEmail;
  final String userName;
  final String ticketId;
  final String ticketTitle;
  final String drawDate;
  final String drawTime;
  final int slNo;
  final String serialNumber;
  final String uniqueCode;
  final List<List<int?>> ticketData;
  final double price;
  final String status;
  final DateTime createdAt;

  TicketPurchaseModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.ticketId,
    required this.ticketTitle,
    required this.drawDate,
    required this.drawTime,
    required this.slNo,
    required this.serialNumber,
    required this.uniqueCode,
    required this.ticketData,
    required this.price,
    this.status = 'Booked',
    required this.createdAt,
  });

  factory TicketPurchaseModel.fromJson(Map<String, dynamic> json) {
    List<List<int?>> grid = [];
    if (json['ticket_data'] != null) {
      final rawGrid = json['ticket_data'];
      if (rawGrid is List) {
        grid = rawGrid.map((row) {
          if (row is List) {
            return row
                .map((cell) =>
                    cell == null ? null : int.tryParse(cell.toString()))
                .toList();
          }
          return List<int?>.filled(9, null);
        }).toList();
      }
    }
    if (grid.length != 3) {
      grid = List.generate(3, (_) => List<int?>.filled(9, null));
    }

    return TicketPurchaseModel(
      id: json['id'],
      userId: json['user_id'],
      userEmail: json['user_email']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Player',
      ticketId: json['ticket_id']?.toString() ?? '',
      ticketTitle: json['ticket_title']?.toString() ?? 'GaGa Housie Draw',
      drawDate: json['draw_date']?.toString() ?? '',
      drawTime: json['draw_time']?.toString() ?? '',
      slNo: json['sl_no'] is int
          ? json['sl_no']
          : int.tryParse(json['sl_no']?.toString() ?? '1') ?? 1,
      serialNumber: json['serial_number']?.toString() ?? '',
      uniqueCode: json['unique_code']?.toString() ?? '',
      ticketData: grid,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '20') ?? 20.0,
      status: json['status']?.toString() ?? 'Booked',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'ticket_id': ticketId,
      'ticket_title': ticketTitle,
      'draw_date': drawDate,
      'draw_time': drawTime,
      'sl_no': slNo,
      'serial_number': serialNumber,
      'unique_code': uniqueCode,
      'ticket_data': ticketData,
      'price': price,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Extracts all 15 non-null numbers for quick preview
  List<int> get filledNumbers {
    final List<int> nums = [];
    for (final row in ticketData) {
      for (final cell in row) {
        if (cell != null) nums.add(cell);
      }
    }
    nums.sort();
    return nums;
  }
}
