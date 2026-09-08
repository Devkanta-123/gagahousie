import 'dart:math';

class TambolaTicketModel {
  final dynamic id;
  final String ticketId;
  final int slNo;
  final String serialNumber;
  final String uniqueCode;
  final String playerName;
  final List<List<int?>> ticketData;
  final String status;
  final DateTime? createdAt;

  TambolaTicketModel({
    this.id,
    required this.ticketId,
    required this.slNo,
    required this.serialNumber,
    required this.uniqueCode,
    this.playerName = 'Available',
    required this.ticketData,
    this.status = 'Available',
    this.createdAt,
  });

  TambolaTicketModel copyWith({
    dynamic id,
    String? ticketId,
    int? slNo,
    String? serialNumber,
    String? uniqueCode,
    String? playerName,
    List<List<int?>>? ticketData,
    String? status,
    DateTime? createdAt,
  }) {
    return TambolaTicketModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      slNo: slNo ?? this.slNo,
      serialNumber: serialNumber ?? this.serialNumber,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      playerName: playerName ?? this.playerName,
      ticketData: ticketData != null
          ? List<List<int?>>.from(
              ticketData.map((row) => List<int?>.from(row)))
          : List<List<int?>>.from(
              this.ticketData.map((row) => List<int?>.from(row))),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create an empty 3x9 tambola ticket with default serial number and unique code
  factory TambolaTicketModel.empty(String ticketId, int slNo) {
    final cleanId = ticketId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final paddedSl = slNo.toString().padLeft(2, '0');
    return TambolaTicketModel(
      ticketId: ticketId,
      slNo: slNo,
      serialNumber: 'SN: $cleanId-$paddedSl',
      uniqueCode: 'CODE: GH-$cleanId-SL$slNo',
      playerName: 'Available',
      ticketData: List.generate(3, (_) => List<int?>.filled(9, null)),
      status: 'Available',
    );
  }

  /// Auto-generate valid random tambola numbers (5 numbers per row, sorted columns)
  factory TambolaTicketModel.generateRandom(String ticketId, int slNo) {
    final emptyModel = TambolaTicketModel.empty(ticketId, slNo);
    return emptyModel.copyWith(ticketData: generateRandomGrid());
  }

  static List<List<int?>> generateRandomGrid() {
    final Random random = Random();
    final List<List<int?>> grid =
        List.generate(3, (_) => List<int?>.filled(9, null));

    for (int row = 0; row < 3; row++) {
      List<int> positions = List.generate(9, (index) => index);
      positions.shuffle(random);
      positions = positions.take(5).toList()..sort();

      for (int col = 0; col < 9; col++) {
        if (positions.contains(col)) {
          final int minNum = col == 0 ? 1 : (col * 10);
          final int maxNum = col == 8 ? 90 : (col * 10) + 9;

          int number = minNum + random.nextInt(maxNum - minNum + 1);
          bool duplicate = true;
          int attempts = 0;
          while (duplicate && attempts < 15) {
            duplicate = false;
            for (int r = 0; r < row; r++) {
              if (grid[r][col] == number) {
                duplicate = true;
                number = minNum + random.nextInt(maxNum - minNum + 1);
                break;
              }
            }
            attempts++;
          }
          grid[row][col] = number;
        }
      }
    }

    // Sort column numbers ascending from top to bottom
    for (int col = 0; col < 9; col++) {
      List<int> colNums = [];
      for (int row = 0; row < 3; row++) {
        if (grid[row][col] != null) colNums.add(grid[row][col]!);
      }
      colNums.sort();
      int idx = 0;
      for (int row = 0; row < 3; row++) {
        if (grid[row][col] != null) {
          grid[row][col] = colNums[idx++];
        }
      }
    }

    return grid;
  }

  /// Total count of filled numbers in this ticket (target: 15 for standard Housie)
  int get filledNumbersCount {
    int count = 0;
    for (final row in ticketData) {
      for (final cell in row) {
        if (cell != null) count++;
      }
    }
    return count;
  }

  /// Whether the ticket is completely empty
  bool get isEmpty => filledNumbersCount == 0;

  /// Check if the ticket is complete (15 numbers)
  bool get isComplete => filledNumbersCount == 15;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ticket_id': ticketId,
      'sl_no': slNo,
      'serial_number': serialNumber,
      'unique_code': uniqueCode,
      'player_name': playerName,
      'ticket_data': ticketData,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory TambolaTicketModel.fromJson(Map<String, dynamic> json) {
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

    return TambolaTicketModel(
      id: json['id'],
      ticketId: json['ticket_id'] ?? '',
      slNo: json['sl_no'] is int
          ? json['sl_no']
          : int.tryParse(json['sl_no']?.toString() ?? '1') ?? 1,
      serialNumber: json['serial_number'] ?? 'SN: TKT-${json['sl_no'] ?? 1}',
      uniqueCode: json['unique_code'] ??
          'CODE: GH-${json['ticket_id']}-SL${json['sl_no'] ?? 1}',
      playerName: json['player_name'] ?? 'Available',
      ticketData: grid,
      status: json['status'] ?? 'Available',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Convert to map format expected by ticket_selection_page.dart
  Map<String, dynamic> toSelectionMap() {
    return {
      'slNo': slNo,
      'playerName': playerName,
      'serialNumber': serialNumber,
      'uniqueCode': uniqueCode,
      'selected': false,
      'ticketData': {'ticketData': ticketData},
    };
  }
}
