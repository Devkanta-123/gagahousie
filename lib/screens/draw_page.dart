import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../models/ticket_purchase_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/supabase_service.dart';
import '../services/ticket_service.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';
import 'ticket_selection_page.dart';

class DrawPage extends StatefulWidget {
  final String? ticketId;

  const DrawPage({super.key, this.ticketId});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage>
    with SingleTickerProviderStateMixin {
  // Current Draw Model & All Available Draws
  TicketModel? _drawTicket;
  List<TicketModel> _availableDraws = [];
  bool _isLoading = true;

  // Called Numbers State
  int? _currentNumber;
  final Set<int> _calledNumbers = {};
  String? _lastAnnouncement;

  // All User Purchased Tickets across all draws & for current draw
  List<TicketPurchaseModel> _allUserPurchases = [];
  List<TicketPurchaseModel> _userPurchasedTickets = [];

  // Track marked numbers per user ticket: Map<ticketIndex, Set<number>>
  final Map<int, Set<int>> _userMarkedNumbers = {};

  // Track claimed prizes in this session: Set<prizeName>
  final Set<String> _claimedPrizes = {};

  // Awarded prizes & claims tracking
  final Map<String, Map<String, dynamic>> _awardedPrizes = {};
  final Set<String> _pendingUserClaims = {};
  final Set<String> _spokenAlertKeys = {};

  // Real-time Subscriptions
  RealtimeChannel? _broadcastChannel;
  RealtimeChannel? _ticketsTableChannel;

  // Animation & UI state
  bool _isBoardExpanded = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Voice TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _voiceEnabled = true;

  // Traditional Tambola Nicknames (1 to 90)
  static const Map<int, String> _tambolaSlang = {
    1: 'Top of the house',
    2: 'Kaala dana / Doctor’s time',
    3: 'Goodness me',
    4: 'Knock at the door',
    5: 'Fingers in hand',
    6: 'Chopper stops',
    7: 'Lucky seven',
    8: 'One fat lady',
    9: 'Doctor’s orders',
    10: 'A big fat hen',
    11: 'Two beautiful legs',
    12: 'One dozen',
    13: 'Unlucky for some',
    14: 'Valentine’s day',
    15: 'Young and keen',
    16: 'Sweet sixteen',
    17: 'Dancing queen',
    18: 'Now you can vote',
    19: 'Goodbye teens',
    20: 'One score',
    21: 'Key of the door',
    22: 'Two little ducks',
    23: 'The Lord is my shepherd',
    24: 'Two dozen',
    25: 'Silver jubilee',
    26: 'Republic day',
    27: 'Gateway to heaven',
    28: 'Duck and its mate',
    29: 'In your prime',
    30: 'Women get flirty',
    31: 'Time for fun',
    32: 'Mouth full of teeth',
    33: 'All the threes',
    34: 'Ask for more',
    35: 'Jump and jive',
    36: 'Three dozen',
    37: 'More than eleven',
    38: 'Christmas cake',
    39: 'Watch your waistline',
    40: 'Naughty forty',
    41: 'Life’s begun',
    42: 'Winnie the Pooh',
    43: 'Down and out',
    44: 'Chor chor char',
    45: 'Halfway there',
    46: 'Up to tricks',
    47: 'Four and seven',
    48: 'Four dozen',
    49: 'Rise and shine',
    50: 'Golden jubilee / Half century',
    51: 'Charity begins',
    52: 'Pack of cards',
    53: 'Pack them with glee',
    54: 'Clean the floor',
    55: 'All the fives',
    56: 'Was she worth it?',
    57: 'Mutiny year',
    58: 'Time to retire',
    59: 'Just retired',
    60: 'Five dozen',
    61: 'Baker’s bun',
    62: 'Turn the screw',
    63: 'Tickle me',
    64: 'Almost retired',
    65: 'Old age pension',
    66: 'Clickety click',
    67: 'Made in heaven',
    68: 'Saving grace',
    69: 'Ulta pulta',
    70: 'Lucky blind',
    71: 'Bang on drum',
    72: 'Six dozen',
    73: 'Under the tree',
    74: 'Candy store',
    75: 'Diamond jubilee',
    76: 'Trombones',
    77: 'Two hockey sticks / Sunset strip',
    78: 'Heaven’s gate',
    79: 'One more time',
    80: 'Blind eighty',
    81: 'Stop and run',
    82: 'Fat lady with duck',
    83: 'Time for tea',
    84: 'Seven dozen',
    85: 'Staying alive',
    86: 'Between the sticks',
    87: 'Torquay in Devon',
    88: 'Two fat ladies',
    89: 'Nearly there',
    90: 'Top of the shop',
  };

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initTts();
    _loadDrawData();
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (_) {}
    _pulseController.dispose();
    _broadcastChannel?.unsubscribe();
    _ticketsTableChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('🎙️ [USER TTS INIT NOTICE] $e');
    }
  }

  Future<void> _speakAnnouncement(int number, [String? customAnnouncement]) async {
    if (!_voiceEnabled) return;
    try {
      final slang = _tambolaSlang[number];
      final tens = number ~/ 10;
      final units = number % 10;

      String digitDetail;
      if (number < 10) {
        digitDetail = 'Single number $number';
      } else {
        const digitNames = [
          'Zero', 'One', 'Two', 'Three', 'Four',
          'Five', 'Six', 'Seven', 'Eight', 'Nine'
        ];
        digitDetail = '${digitNames[tens]} and ${digitNames[units]}, $number';
      }

      String text;
      // Strictly guarantee audio announcement matches this exact called number!
      if (customAnnouncement != null &&
          customAnnouncement.isNotEmpty &&
          customAnnouncement.contains('$number')) {
        text = customAnnouncement;
      } else {
        text = slang != null && slang.isNotEmpty
            ? 'Pick up number is $number! $digitDetail. $slang, $number!'
            : 'Pick up number is $number! $digitDetail!';
      }

      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  /// Load real draw data, called numbers, and user purchased tickets from Supabase DB
  Future<void> _loadDrawData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all draws from DB so the user can easily select/switch
      final allDraws = await TicketService.instance.fetchTickets();
      _availableDraws = allDraws;

      // 2. Fetch all tickets purchased by the current user
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user?.id != null) {
        _allUserPurchases = await TicketService.instance
            .fetchPurchasedTicketsForUser(user!.id);
        debugPrint(
            '🎟️ [DRAW PAGE] Loaded ${_allUserPurchases.length} total purchased tickets for user ${user.id}');
      }

      // 3. Resolve which draw to display
      TicketModel? selectedDraw;
      final targetId = widget.ticketId?.replaceAll('#', '').trim();

      if (targetId != null && targetId.isNotEmpty) {
        // Priority A: Explicitly requested draw ID
        selectedDraw = _availableDraws.cast<TicketModel?>().firstWhere(
              (t) =>
                  t?.ticketId.replaceAll('#', '').trim().toLowerCase() ==
                  targetId.toLowerCase(),
              orElse: () => null,
            );
      }

      // Priority B: If no explicit ID or not found, check if user purchased tickets for a draw!
      if (selectedDraw == null && _allUserPurchases.isNotEmpty) {
        final purchasedDrawId = _allUserPurchases.first.ticketId
            .replaceAll('#', '')
            .trim()
            .toLowerCase();
        selectedDraw = _availableDraws.cast<TicketModel?>().firstWhere(
              (t) =>
                  t?.ticketId.replaceAll('#', '').trim().toLowerCase() ==
                  purchasedDrawId,
              orElse: () => null,
            );
        debugPrint(
            '🎯 [DRAW PAGE] Auto-selected user purchased draw: ${selectedDraw?.ticketId}');
      }

      // Priority C: Fallback to first active draw
      if (selectedDraw == null) {
        if (_availableDraws.isNotEmpty) {
          selectedDraw = _availableDraws.firstWhere(
            (t) => t.status.toLowerCase() == 'active',
            orElse: () => _availableDraws.first,
          );
        }
      }

      _drawTicket = selectedDraw;

      if (_drawTicket != null) {
        await _syncDrawStateAndTickets();
      }
    } catch (e) {
      debugPrint('⚠️ [DRAW PAGE LOAD ERROR] $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Syncs called numbers & loads purchased tickets for current `_drawTicket`
  Future<void> _syncDrawStateAndTickets() async {
    if (_drawTicket == null) return;
    final cleanId = _drawTicket!.ticketId.replaceAll('#', '').trim();

    // 1. Filter user tickets for this draw
    _userPurchasedTickets = _allUserPurchases.where((p) {
      final pId = p.ticketId.replaceAll('#', '').trim().toLowerCase();
      return pId == cleanId.toLowerCase();
    }).toList();

    debugPrint(
        '🎟️ [DRAW PAGE] User owns ${_userPurchasedTickets.length} tickets for draw $cleanId');

    // 2. Fetch latest called numbers and awarded prizes directly from DB
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final res = await client
            .from('tickets')
            .select('called_numbers, current_number, awarded_prizes')
            .or('ticket_id.eq.$cleanId,ticket_id.eq.#$cleanId')
            .maybeSingle();

        if (res != null) {
          final called = res['called_numbers'];
          final curr = res['current_number'];
          final awarded = res['awarded_prizes'];
          if (curr != null) {
            _currentNumber = int.tryParse(curr.toString());
          }
          if (called is List) {
            _calledNumbers.clear();
            for (final item in called) {
              final n = int.tryParse(item.toString());
              if (n != null && n > 0) _calledNumbers.add(n);
            }
          }
          if (awarded is List) {
            _awardedPrizes.clear();
            for (final item in awarded) {
              if (item is Map) {
                final k = (item['prize_name']?.toString() ?? '')
                    .toLowerCase()
                    .trim();
                if (k.isNotEmpty) {
                  _awardedPrizes[k] = Map<String, dynamic>.from(item);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SYNC CALLED NUMBERS NOTICE] $e');
    }

    // 3. Auto-mark numbers on user tickets that have already been called
    for (int i = 0; i < _userPurchasedTickets.length; i++) {
      _userMarkedNumbers.putIfAbsent(i, () => <int>{});
      for (final row in _userPurchasedTickets[i].ticketData) {
        for (final cell in row) {
          if (cell != null && _calledNumbers.contains(cell)) {
            _userMarkedNumbers[i]!.add(cell);
          }
        }
      }
    }

    // 4. Setup real-time listener for this draw
    _setupRealtimeChannel();
  }

  /// Switches to another draw seamlessly
  Future<void> _switchDraw(TicketModel newDraw) async {
    if (_drawTicket?.ticketId == newDraw.ticketId) return;
    setState(() {
      _drawTicket = newDraw;
      _calledNumbers.clear();
      _currentNumber = null;
      _lastAnnouncement = null;
      _userMarkedNumbers.clear();
      _claimedPrizes.clear();
      _awardedPrizes.clear();
      _pendingUserClaims.clear();
      _spokenAlertKeys.clear();
      _isLoading = true;
    });

    await _syncDrawStateAndTickets();

    if (mounted) setState(() => _isLoading = false);
  }

  /// Subscribes to real-time events broadcast by the caller / host
  void _setupRealtimeChannel() {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    _broadcastChannel?.unsubscribe();
    _ticketsTableChannel?.unsubscribe();

    try {
      _broadcastChannel = client.channel('gaga_broadcast_feed');

      // 1. Host called a new number
      _broadcastChannel?.onBroadcast(
        event: 'number_called',
        callback: (payload) {
          final tid = payload['ticket_id']?.toString() ?? '';
          final cleanTid = tid.replaceAll('#', '').trim();
          final currentTid =
              _drawTicket?.ticketId.replaceAll('#', '').trim() ?? '';

          if (cleanTid.isNotEmpty &&
              currentTid.isNotEmpty &&
              cleanTid != currentTid) {
            return;
          }

          final num = int.tryParse(payload['number']?.toString() ?? '');
          final calledList = payload['called_numbers'];
          final announcement = payload['announcement']?.toString();

          if (mounted && num != null && num > 0 && num <= 90) {
            setState(() {
              _currentNumber = num;
              _calledNumbers.add(num);
              _lastAnnouncement = _tambolaSlang[num];

              // Also auto-mark this called number on user tickets
              for (int i = 0; i < _userPurchasedTickets.length; i++) {
                _userMarkedNumbers.putIfAbsent(i, () => <int>{});
                for (final row in _userPurchasedTickets[i].ticketData) {
                  if (row.contains(num)) {
                    _userMarkedNumbers[i]!.add(num);
                  }
                }
              }

              if (calledList is List) {
                for (final item in calledList) {
                  final n = int.tryParse(item.toString());
                  if (n != null && n > 0) _calledNumbers.add(n);
                }
              }
            });

            _speakAnnouncement(num, announcement);

            // Check if any pattern is 1-away or ready to claim, and announce
            final analysis = _analyzeUserTickets();
            _checkAndSpeakPatternAlerts(analysis);
          }
        },
      );

      // 2. Host unpicked / undid a number
      _broadcastChannel?.onBroadcast(
        event: 'number_unmarked',
        callback: (payload) {
          final tid = payload['ticket_id']?.toString() ?? '';
          final cleanTid = tid.replaceAll('#', '').trim();
          final currentTid =
              _drawTicket?.ticketId.replaceAll('#', '').trim() ?? '';

          if (cleanTid.isNotEmpty &&
              currentTid.isNotEmpty &&
              cleanTid != currentTid) {
            return;
          }

          final num = int.tryParse(payload['number']?.toString() ?? '');
          final curr = int.tryParse(payload['current_number']?.toString() ?? '');

          if (mounted) {
            setState(() {
              if (num != null) _calledNumbers.remove(num);
              _currentNumber = curr;
              for (final set in _userMarkedNumbers.values) {
                if (num != null) set.remove(num);
              }
            });
          }
        },
      );

      // 3. Host reset the game draw
      _broadcastChannel?.onBroadcast(
        event: 'draw_reset',
        callback: (payload) {
          final tid = payload['ticket_id']?.toString() ?? '';
          final cleanTid = tid.replaceAll('#', '').trim();
          final currentTid =
              _drawTicket?.ticketId.replaceAll('#', '').trim() ?? '';

          if (cleanTid.isNotEmpty &&
              currentTid.isNotEmpty &&
              cleanTid != currentTid) {
            return;
          }

          if (mounted) {
            setState(() {
              _calledNumbers.clear();
              _currentNumber = null;
              _lastAnnouncement = null;
              _claimedPrizes.clear();
              _awardedPrizes.clear();
              _pendingUserClaims.clear();
              _spokenAlertKeys.clear();
              for (final set in _userMarkedNumbers.values) {
                set.clear();
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔄 The host has reset the draw board.'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );

      // 4. Host approved a winner for a prize
      _broadcastChannel?.onBroadcast(
        event: 'prize_awarded',
        callback: (payload) {
          final tid = payload['ticket_id']?.toString() ?? '';
          final cleanTid = tid.replaceAll('#', '').trim();
          final currentTid =
              _drawTicket?.ticketId.replaceAll('#', '').trim() ?? '';

          if (cleanTid.isNotEmpty &&
              currentTid.isNotEmpty &&
              cleanTid != currentTid) {
            return;
          }

          final pName =
              (payload['prize_name']?.toString() ?? '').toLowerCase().trim();
          final uName = payload['winner_name']?.toString() ?? 'Player';
          final sl = payload['sl_no']?.toString() ?? '';
          final sn = payload['serial_number']?.toString() ?? '';
          final pAmount = payload['prize_amount']?.toString() ?? '';
          final uId = payload['user_id']?.toString();

          final awardRecord = {
            'prize_name': payload['prize_name'] ?? '',
            'winner_name': uName,
            'sl_no': sl,
            'serial_number': sn,
            'prize_amount': pAmount,
            'user_id': uId,
            'awarded_at': DateTime.now().toIso8601String(),
          };

          if (mounted) {
            setState(() {
              if (pName.isNotEmpty) {
                _awardedPrizes[pName] = awardRecord;
                _pendingUserClaims.remove(pName);
              }
              if (payload['awarded_prizes'] is List) {
                for (final item in payload['awarded_prizes']) {
                  if (item is Map) {
                    final k = (item['prize_name']?.toString() ?? '')
                        .toLowerCase()
                        .trim();
                    if (k.isNotEmpty) {
                      _awardedPrizes[k] = Map<String, dynamic>.from(item);
                    }
                  }
                }
              }
            });

            final auth = Provider.of<AuthProvider>(context, listen: false);
            final myUserId = auth.currentUser?.id;
            final originalPrizeName =
                payload['prize_name']?.toString() ?? 'Prize';

            if (myUserId != null && uId != null && myUserId == uId) {
              _showWinnerCelebrationDialog(
                prizeName: originalPrizeName,
                prizeAmount: pAmount,
                slNo: sl,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF27AE60),
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🏆 $uName won $originalPrizeName (SL #$sl)! Prize is now closed.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
      );

      // 5. Host rejected a bogey claim
      _broadcastChannel?.onBroadcast(
        event: 'claim_rejected',
        callback: (payload) {
          final tid = payload['ticket_id']?.toString() ?? '';
          final cleanTid = tid.replaceAll('#', '').trim();
          final currentTid =
              _drawTicket?.ticketId.replaceAll('#', '').trim() ?? '';

          if (cleanTid.isNotEmpty &&
              currentTid.isNotEmpty &&
              cleanTid != currentTid) {
            return;
          }

          final auth = Provider.of<AuthProvider>(context, listen: false);
          final myUserId = auth.currentUser?.id;
          final claimantId = payload['user_id']?.toString();
          final pName =
              (payload['prize_name']?.toString() ?? '').toLowerCase().trim();

          if (mounted) {
            setState(() {
              if (pName.isNotEmpty) {
                _pendingUserClaims.remove(pName);
              }
            });

            if (myUserId != null &&
                claimantId != null &&
                myUserId == claimantId) {
              _showClaimRejectedDialog(
                prizeName: payload['prize_name']?.toString() ?? 'Prize',
                reason: payload['reason']?.toString() ??
                    'Pattern requirements not satisfied',
                slNo: payload['sl_no']?.toString() ?? '',
              );
            }
          }
        },
      );

      // 6. Host officially started the draw
      _broadcastChannel?.onBroadcast(
        event: 'draw_started',
        callback: (payload) {
          final tid = payload['ticket_id']?.toString() ?? '';
          final cleanTid = tid.replaceAll('#', '').trim();
          final currentTid =
              _drawTicket?.ticketId.replaceAll('#', '').trim() ?? '';

          if (cleanTid.isNotEmpty &&
              currentTid.isNotEmpty &&
              cleanTid != currentTid) {
            return;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.play_circle_fill_rounded,
                        color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎯 The host has officially started this draw! Best of luck!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1E3C72),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );

      _broadcastChannel?.subscribe();

      // Table CDC changes fallback for tickets
      _ticketsTableChannel = client
          .channel('public:tickets:draw_page')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'tickets',
            callback: (payload) {
              final newRec = payload.newRecord;
              final tid = newRec['ticket_id']?.toString() ?? '';
              final currentTid =
                  _drawTicket?.ticketId.replaceAll('#', '').trim() ?? '';
              if (tid.replaceAll('#', '').trim() != currentTid) return;

              final called = newRec['called_numbers'];
              final curr = newRec['current_number'];
              final awarded = newRec['awarded_prizes'];
              if (mounted) {
                setState(() {
                  if (curr != null) {
                    _currentNumber = int.tryParse(curr.toString());
                  }
                  if (called is List) {
                    _calledNumbers.clear();
                    for (final item in called) {
                      final n = int.tryParse(item.toString());
                      if (n != null && n > 0) _calledNumbers.add(n);
                    }
                  }
                  if (awarded is List) {
                    _awardedPrizes.clear();
                    for (final item in awarded) {
                      if (item is Map) {
                        final k = (item['prize_name']?.toString() ?? '')
                            .toLowerCase()
                            .trim();
                        if (k.isNotEmpty) {
                          _awardedPrizes[k] = Map<String, dynamic>.from(item);
                        }
                      }
                    }
                  }
                });
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('⚠️ [REALTIME CHANNEL ERROR] $e');
    }
  }

  // ===========================================================================
  // INTERACTIVE NUMBER MARKING / DABBING (FULL USER CONTROL)
  // ===========================================================================
  /// Lets the user tap ANY cell on their Tambola ticket to mark or unmark it at will
  void _onCellTapped(int ticketIndex, int? number) {
    if (number == null) return;

    setState(() {
      _userMarkedNumbers.putIfAbsent(ticketIndex, () => <int>{});
      if (_userMarkedNumbers[ticketIndex]!.contains(number)) {
        _userMarkedNumbers[ticketIndex]!.remove(number);
      } else {
        _userMarkedNumbers[ticketIndex]!.add(number);
      }
    });
  }

  void _autoMarkAll() {
    int count = 0;
    setState(() {
      for (int i = 0; i < _userPurchasedTickets.length; i++) {
        _userMarkedNumbers.putIfAbsent(i, () => <int>{});
        for (final row in _userPurchasedTickets[i].ticketData) {
          for (final cell in row) {
            if (cell != null && _calledNumbers.contains(cell)) {
              if (_userMarkedNumbers[i]!.add(cell)) {
                count++;
              }
            }
          }
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(count > 0
            ? '🎯 Auto-marked $count called numbers on your tickets!'
            : 'All called numbers already marked!'),
        backgroundColor: const Color(0xFF00B894),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _autoMarkSingleTicket(int ticketIndex) {
    final ticket = _userPurchasedTickets[ticketIndex];
    int count = 0;
    setState(() {
      _userMarkedNumbers.putIfAbsent(ticketIndex, () => <int>{});
      for (final row in ticket.ticketData) {
        for (final cell in row) {
          if (cell != null && _calledNumbers.contains(cell)) {
            if (_userMarkedNumbers[ticketIndex]!.add(cell)) {
              count++;
            }
          }
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(count > 0
            ? '🎯 Auto-marked $count numbers on SL #${ticket.slNo}!'
            : 'All called numbers already marked on SL #${ticket.slNo}!'),
        backgroundColor: const Color(0xFF00B894),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===========================================================================
  // PRIZE CLAIM VALIDATION & SUBMISSION
  // ===========================================================================
  void _handlePrizeClaim(PrizeItem prize) {
    if (_userPurchasedTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to own tickets in this draw to claim prizes!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_calledNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('The draw has not started yet. Wait for numbers to be called.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pKey = prize.name.toLowerCase().trim();

    // 1. Check if prize was already awarded and closed
    if (_awardedPrizes.containsKey(pKey)) {
      final winner = _awardedPrizes[pKey];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ ${prize.name} was already won by ${winner?['winner_name'] ?? "another player"} (SL #${winner?['sl_no'] ?? ""}). Prize is closed.',
          ),
          backgroundColor: Colors.orange.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Check if this user already submitted a pending claim
    if (_pendingUserClaims.contains(pKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⏳ Your claim for ${prize.name} is currently being verified by the host.',
          ),
          backgroundColor: const Color(0xFFE67E22),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final pName = prize.name.trim();

    // Check each purchased ticket to see if any satisfies the claim
    ClaimValidationResult? bestResult;
    for (int i = 0; i < _userPurchasedTickets.length; i++) {
      final ticket = _userPurchasedTickets[i];
      final res = _validateTicketForPrize(ticket, pName);
      if (res.isValid) {
        bestResult = res;
        break;
      } else {
        if (bestResult == null ||
            res.missingNumbers.length < bestResult.missingNumbers.length) {
          bestResult = res;
        }
      }
    }

    if (bestResult == null) return;

    if (bestResult.isValid) {
      _confirmAndBroadcastClaim(bestResult, prize);
    } else {
      _showBogeyDialog(bestResult, prize);
    }
  }

  ClaimValidationResult _validateTicketForPrize(
      TicketPurchaseModel ticket, String prizeName) {
    final nameLower = prizeName.toLowerCase();
    final grid = ticket.ticketData;

    final row0 = grid.isNotEmpty ? grid[0].whereType<int>().toList() : <int>[];
    final row1 = grid.length > 1 ? grid[1].whereType<int>().toList() : <int>[];
    final row2 = grid.length > 2 ? grid[2].whereType<int>().toList() : <int>[];
    final all15 = [...row0, ...row1, ...row2];

    bool isValid = false;
    List<int> required = [];
    List<int> missing = [];
    String explanation = '';

    if (nameLower.contains('housefull') || nameLower.contains('house full')) {
      required = all15;
      missing = all15.where((n) => !_calledNumbers.contains(n)).toList();
      isValid = missing.isEmpty && all15.length >= 15;
      explanation = isValid
          ? 'All 15 numbers on your ticket have been called!'
          : 'Housefull requires all 15 numbers. You still need ${missing.length} number(s): ${missing.take(5).join(', ')}${missing.length > 5 ? '...' : ''}.';
    } else if (nameLower.contains('quick') || nameLower.contains('five')) {
      final calledOnTicket =
          all15.where((n) => _calledNumbers.contains(n)).toList();
      required = all15;
      isValid = calledOnTicket.length >= 5;
      final needMore = 5 - calledOnTicket.length;
      missing = all15.where((n) => !_calledNumbers.contains(n)).toList();
      explanation = isValid
          ? '${calledOnTicket.length} numbers on your ticket have been called!'
          : 'Quick 5 requires at least 5 numbers. You currently have ${calledOnTicket.length}/5 numbers called. Need $needMore more.';
    } else if (nameLower.contains('1st') ||
        nameLower.contains('first') ||
        nameLower.contains('top')) {
      required = row0;
      missing = row0.where((n) => !_calledNumbers.contains(n)).toList();
      isValid = missing.isEmpty && row0.isNotEmpty;
      explanation = isValid
          ? 'All numbers in Row 1 (Top Line) have been called!'
          : '1st Line requires all 5 numbers in Row 1. Missing: ${missing.join(', ')}.';
    } else if (nameLower.contains('2nd') ||
        nameLower.contains('second') ||
        nameLower.contains('middle')) {
      required = row1;
      missing = row1.where((n) => !_calledNumbers.contains(n)).toList();
      isValid = missing.isEmpty && row1.isNotEmpty;
      explanation = isValid
          ? 'All numbers in Row 2 (Middle Line) have been called!'
          : '2nd Line requires all 5 numbers in Row 2. Missing: ${missing.join(', ')}.';
    } else if (nameLower.contains('3rd') ||
        nameLower.contains('third') ||
        nameLower.contains('bottom')) {
      required = row2;
      missing = row2.where((n) => !_calledNumbers.contains(n)).toList();
      isValid = missing.isEmpty && row2.isNotEmpty;
      explanation = isValid
          ? 'All numbers in Row 3 (Bottom Line) have been called!'
          : '3rd Line requires all 5 numbers in Row 3. Missing: ${missing.join(', ')}.';
    } else if (nameLower.contains('corner') || nameLower.contains('4th')) {
      if (row0.length >= 2 && row2.length >= 2) {
        required = [row0.first, row0.last, row2.first, row2.last];
        missing = required.where((n) => !_calledNumbers.contains(n)).toList();
        isValid = missing.isEmpty;
        explanation = isValid
            ? 'All 4 corner numbers on your ticket have been called!'
            : '4th Corner requires 4 corners. Missing: ${missing.join(', ')}.';
      } else {
        isValid = false;
        explanation = 'Ticket does not have enough corner numbers.';
      }
    } else {
      // General pattern or Quick 10
      final called = all15.where((n) => _calledNumbers.contains(n)).toList();
      isValid = called.length >= 5;
      explanation = isValid
          ? 'Pattern satisfied with ${called.length} called numbers.'
          : 'Pattern requires at least 5 numbers. You currently have ${called.length}.';
    }

    return ClaimValidationResult(
      isValid: isValid,
      prizeName: prizeName,
      winningTicket: ticket,
      requiredNumbers: required,
      missingNumbers: missing,
      explanation: explanation,
    );
  }

  Future<void> _confirmAndBroadcastClaim(
      ClaimValidationResult result, PrizeItem prize) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (user?.phone ?? 'Player');
    final tid = _drawTicket?.ticketId ?? '';
    final pKey = prize.name.toLowerCase().trim();

    // Mark as pending locally
    setState(() {
      _pendingUserClaims.add(pKey);
      _claimedPrizes.add(prize.name);
    });

    // 1. Broadcast instant event to Host Screen with ticket_data
    try {
      final payload = {
        'ticket_id': tid,
        'prize_name': prize.name,
        'prize_amount': prize.price,
        'user_id': user?.id,
        'user_name': userName,
        'sl_no': result.winningTicket?.slNo,
        'serial_number': result.winningTicket?.serialNumber,
        'unique_code': result.winningTicket?.uniqueCode,
        'ticket_data': result.winningTicket?.ticketData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (_broadcastChannel != null) {
        await _broadcastChannel!.sendBroadcastMessage(
          event: 'prize_claimed',
          payload: payload,
        );
      } else {
        final client = SupabaseService.instance.client;
        if (client != null) {
          final ch = client.channel('gaga_broadcast_feed');
          await ch.subscribe();
          await ch.sendBroadcastMessage(
            event: 'prize_claimed',
            payload: payload,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [BROADCAST CLAIM ERROR] $e');
    }

    // 2. Show pending verification dialog to inform user
    _showClaimSubmittedDialog(result, prize, userName);
  }

  void _showClaimSubmittedDialog(
      ClaimValidationResult result, PrizeItem prize, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF39C12).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFE67E22),
                size: 52,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⏳ Claim Submitted!',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your claim for "${prize.name}" (${prize.price}) on SL #${result.winningTicket?.slNo} has been submitted to the Host for official verification.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00B894).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: Color(0xFF00B894), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The Host is checking your ticket live. Once approved, the winner will be officially announced!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00896F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Waiting for Verification ⏳',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWinnerCelebrationDialog({
    required String prizeName,
    required String prizeAmount,
    required String slNo,
  }) {
    if (_voiceEnabled) {
      try {
        _flutterTts.speak('Congratulations! You have WON $prizeName!');
      } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF39C12), Color(0xFFF1C40F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF39C12).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '🏆 YOU ARE THE WINNER!',
              style: TextStyle(
                color: Color(0xFF27AE60),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The Host verified your ticket and officially announced you as the WINNER of:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B894).withOpacity(0.12),
                    const Color(0xFF00D2D3).withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00B894),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    prizeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prizeAmount,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00B894),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Winning Ticket SL #$slNo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Prize rewards are processed directly to your GaGa wallet balance!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Collect & Celebrate! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClaimRejectedDialog({
    required String prizeName,
    required String reason,
    required String slNo,
  }) {
    if (_voiceEnabled) {
      try {
        _flutterTts.speak('Your claim for $prizeName was rejected by host.');
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cancel_rounded,
                color: Colors.red.shade700,
                size: 54,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Claim Rejected (Bogey)',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The Host reviewed your claim for "$prizeName" on SL #$slNo and marked it as Bogey.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can continue playing as more numbers are drawn!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Continue Playing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REAL-TIME PATTERN ANALYSIS & SMART AUTO-SUGGEST ALERTS
  // ===========================================================================
  PatternAnalysisResult _analyzeUserTickets() {
    final List<ReadyToClaimAlert> readyList = [];
    final List<NearWinAlert> nearWinList = [];
    final Map<int, Set<int>> targetNumbersPerTicket = {};

    final prizes = _drawTicket?.prizes ?? TicketModel.defaultPrizes();

    for (int tIdx = 0; tIdx < _userPurchasedTickets.length; tIdx++) {
      targetNumbersPerTicket[tIdx] = <int>{};
      final ticket = _userPurchasedTickets[tIdx];
      final grid = ticket.ticketData;
      final row0 =
          grid.isNotEmpty ? grid[0].whereType<int>().toList() : <int>[];
      final row1 =
          grid.length > 1 ? grid[1].whereType<int>().toList() : <int>[];
      final row2 =
          grid.length > 2 ? grid[2].whereType<int>().toList() : <int>[];
      final all15 = [...row0, ...row1, ...row2];
      final corners = (row0.length >= 2 && row2.length >= 2)
          ? [row0.first, row0.last, row2.first, row2.last]
          : <int>[];

      for (final prize in prizes) {
        final pName = prize.name.trim();
        final pLower = pName.toLowerCase();

        // If prize is already won and closed, do not alert
        if (_awardedPrizes.containsKey(pLower)) continue;

        // If user already submitted a pending claim for this prize, skip
        if (_pendingUserClaims.contains(pLower)) continue;

        if (pLower.contains('housefull') || pLower.contains('house full')) {
          final missing =
              all15.where((n) => !_calledNumbers.contains(n)).toList();
          if (missing.isEmpty && all15.length >= 15) {
            readyList.add(ReadyToClaimAlert(
              prize: prize,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              ticket: ticket,
              patternType: 'Housefull',
              message:
                  'All 15 numbers filled for Housefull on SL #${ticket.slNo}!',
            ));
          } else if (missing.length == 1) {
            final targetNum = missing.first;
            targetNumbersPerTicket[tIdx]!.add(targetNum);
            nearWinList.add(NearWinAlert(
              prizeName: prize.name,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              missingNumber: targetNum,
              patternType: 'Housefull',
              message:
                  'Only number $targetNum needed for Housefull on SL #${ticket.slNo}!',
            ));
          }
        } else if (pLower.contains('quick') || pLower.contains('five')) {
          final calledOnTicket =
              all15.where((n) => _calledNumbers.contains(n)).toList();
          if (calledOnTicket.length >= 5) {
            readyList.add(ReadyToClaimAlert(
              prize: prize,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              ticket: ticket,
              patternType: 'Quick 5',
              message:
                  '${calledOnTicket.length} numbers marked for Quick 5 on SL #${ticket.slNo}!',
            ));
          } else if (calledOnTicket.length == 4) {
            final uncalled =
                all15.where((n) => !_calledNumbers.contains(n)).toList();
            if (uncalled.isNotEmpty) {
              targetNumbersPerTicket[tIdx]!.addAll(uncalled);
            }
            nearWinList.add(NearWinAlert(
              prizeName: prize.name,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              missingNumber: 0,
              patternType: 'Quick 5',
              message:
                  'Just 1 more called number needed for Quick 5 on SL #${ticket.slNo}!',
            ));
          }
        } else if (pLower.contains('1st') ||
            pLower.contains('first') ||
            pLower.contains('top')) {
          final missing =
              row0.where((n) => !_calledNumbers.contains(n)).toList();
          if (missing.isEmpty && row0.isNotEmpty) {
            readyList.add(ReadyToClaimAlert(
              prize: prize,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              ticket: ticket,
              patternType: '1st Line',
              message:
                  'Row 1 is filled! Ready to claim 1st Line on SL #${ticket.slNo}!',
            ));
          } else if (missing.length == 1) {
            final targetNum = missing.first;
            targetNumbersPerTicket[tIdx]!.add(targetNum);
            nearWinList.add(NearWinAlert(
              prizeName: prize.name,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              missingNumber: targetNum,
              patternType: '1st Line',
              message:
                  'Only number $targetNum needed for 1st Line on SL #${ticket.slNo}!',
            ));
          }
        } else if (pLower.contains('2nd') ||
            pLower.contains('second') ||
            pLower.contains('middle')) {
          final missing =
              row1.where((n) => !_calledNumbers.contains(n)).toList();
          if (missing.isEmpty && row1.isNotEmpty) {
            readyList.add(ReadyToClaimAlert(
              prize: prize,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              ticket: ticket,
              patternType: '2nd Line',
              message:
                  'Row 2 is filled! Ready to claim 2nd Line on SL #${ticket.slNo}!',
            ));
          } else if (missing.length == 1) {
            final targetNum = missing.first;
            targetNumbersPerTicket[tIdx]!.add(targetNum);
            nearWinList.add(NearWinAlert(
              prizeName: prize.name,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              missingNumber: targetNum,
              patternType: '2nd Line',
              message:
                  'Only number $targetNum needed for 2nd Line on SL #${ticket.slNo}!',
            ));
          }
        } else if (pLower.contains('3rd') ||
            pLower.contains('third') ||
            pLower.contains('bottom')) {
          final missing =
              row2.where((n) => !_calledNumbers.contains(n)).toList();
          if (missing.isEmpty && row2.isNotEmpty) {
            readyList.add(ReadyToClaimAlert(
              prize: prize,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              ticket: ticket,
              patternType: '3rd Line',
              message:
                  'Row 3 is filled! Ready to claim 3rd Line on SL #${ticket.slNo}!',
            ));
          } else if (missing.length == 1) {
            final targetNum = missing.first;
            targetNumbersPerTicket[tIdx]!.add(targetNum);
            nearWinList.add(NearWinAlert(
              prizeName: prize.name,
              ticketIndex: tIdx,
              slNo: ticket.slNo,
              missingNumber: targetNum,
              patternType: '3rd Line',
              message:
                  'Only number $targetNum needed for 3rd Line on SL #${ticket.slNo}!',
            ));
          }
        } else if (pLower.contains('corner') || pLower.contains('4th')) {
          final missing =
              corners.where((n) => !_calledNumbers.contains(n)).toList();
          if (corners.isNotEmpty) {
            if (missing.isEmpty) {
              readyList.add(ReadyToClaimAlert(
                prize: prize,
                ticketIndex: tIdx,
                slNo: ticket.slNo,
                ticket: ticket,
                patternType: '4 Corners',
                message:
                    'All 4 corners filled! Ready to claim 4th Corner on SL #${ticket.slNo}!',
              ));
            } else if (missing.length == 1) {
              final targetNum = missing.first;
              targetNumbersPerTicket[tIdx]!.add(targetNum);
              nearWinList.add(NearWinAlert(
                prizeName: prize.name,
                ticketIndex: tIdx,
                slNo: ticket.slNo,
                missingNumber: targetNum,
                patternType: '4 Corners',
                message:
                    'Only number $targetNum needed for 4 Corners on SL #${ticket.slNo}!',
              ));
            }
          }
        }
      }
    }

    return PatternAnalysisResult(
      readyToClaim: readyList,
      nearWins: nearWinList,
      targetNumbersPerTicket: targetNumbersPerTicket,
    );
  }

  void _checkAndSpeakPatternAlerts(PatternAnalysisResult analysis) {
    if (!_voiceEnabled) return;

    // Ready to claim has highest voice announcement priority
    if (analysis.readyToClaim.isNotEmpty) {
      final alert = analysis.readyToClaim.first;
      final key = '${alert.slNo}_${alert.prize.name}_ready';
      if (_spokenAlertKeys.add(key)) {
        Future.delayed(const Duration(milliseconds: 3200), () {
          if (mounted && _voiceEnabled) {
            try {
              _flutterTts.speak(
                '${alert.patternType} completed on ticket SL ${alert.slNo}! Claim your prize now!',
              );
            } catch (_) {}
          }
        });
        return;
      }
    }

    // Near win announcement (1 away)
    if (analysis.nearWins.isNotEmpty) {
      final alert = analysis.nearWins.first;
      final key =
          '${alert.slNo}_${alert.prizeName}_1away_${alert.missingNumber}';
      if (_spokenAlertKeys.add(key)) {
        Future.delayed(const Duration(milliseconds: 3200), () {
          if (mounted && _voiceEnabled) {
            try {
              if (alert.missingNumber > 0) {
                _flutterTts.speak(
                  'Alert! Only number ${alert.missingNumber} needed for ${alert.patternType} on ticket SL ${alert.slNo}!',
                );
              } else {
                _flutterTts.speak(
                  'Alert! Only one more number needed for ${alert.patternType} on ticket SL ${alert.slNo}!',
                );
              }
            } catch (_) {}
          }
        });
      }
    }
  }

  void _showBogeyDialog(ClaimValidationResult result, PrizeItem prize) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.deepOrange,
                size: 54,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Bogey Claim!',
              style: TextStyle(
                color: Colors.deepOrange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your ticket does not meet the pattern requirements for "${prize.name}" yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                result.explanation,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF34495E),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep watching the caller board as more numbers are drawn!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Continue Playing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DRAW SELECTION BOTTOM SHEET
  // ===========================================================================
  void _showDrawSelectorBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.confirmation_number_rounded,
                          color: Color(0xFF00B894), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Select Housie Draw',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose an active draw to watch live numbers and play your tickets:',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _availableDraws.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final d = _availableDraws[idx];
                    final isSelected = d.ticketId == _drawTicket?.ticketId;
                    final ownedCount = _allUserPurchases
                        .where((p) =>
                            p.ticketId
                                .replaceAll('#', '')
                                .trim()
                                .toLowerCase() ==
                            d.ticketId
                                .replaceAll('#', '')
                                .trim()
                                .toLowerCase())
                        .length;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _switchDraw(d);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00B894).withOpacity(0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00B894)
                                : Colors.grey.shade200,
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected
                                  ? const Color(0xFF00B894)
                                  : Colors.grey.shade300,
                              radius: 16,
                              child: Icon(
                                isSelected
                                    ? Icons.check
                                    : Icons.confirmation_number,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.ticketTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected
                                          ? const Color(0xFF00B894)
                                          : const Color(0xFF2C3E50),
                                    ),
                                  ),
                                  Text(
                                    'Draw #${d.ticketId} • ${d.drawDate} ${d.drawTime}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ownedCount > 0
                                    ? const Color(0xFF00B894).withOpacity(0.15)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ownedCount > 0
                                    ? '$ownedCount Owned'
                                    : '0 Owned',
                                style: TextStyle(
                                  color: ownedCount > 0
                                      ? const Color(0xFF00B894)
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);
    final analysis = _analyzeUserTickets();
    final readyList = analysis.readyToClaim;
    final nearWinList = analysis.nearWins;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GaGaAppHeader(
            showBackButton: true,
            subtitle: _drawTicket != null
                ? 'Live: ${_drawTicket!.ticketTitle}'
                : 'Live Tambola Draw',
            showBalance: true,
            balance: wallet.balance,
            showRechargeButton: true,
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B894)),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF00B894),
                onRefresh: _loadDrawData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Draw Switcher Card
                      _buildDrawSwitcherCard(),
                      const SizedBox(height: 12),

                      // Auto-Suggest Claim Banner (Pulsing high-priority when cells fill)
                      if (readyList.isNotEmpty) ...[
                        _buildAutoSuggestClaimBanner(readyList.first),
                        const SizedBox(height: 12),
                      ] else if (nearWinList.isNotEmpty) ...[
                        // 1-Away Alert Banner (when only 1 number is needed)
                        _buildNearWinAlertBanner(nearWinList.first),
                        const SizedBox(height: 12),
                      ],

                      // Status & Controls Ribbon
                      _buildStatusRibbon(),
                      const SizedBox(height: 14),

                      // Big Current Number Card
                      _buildCurrentNumberCard(),
                      const SizedBox(height: 14),

                      // 1-90 Master Board (Collapsible)
                      _buildMasterBoardSection(),
                      const SizedBox(height: 20),

                      // User's Real Purchased Tickets
                      _buildUserTicketsSection(analysis),
                      const SizedBox(height: 24),

                      // Prizes & Claims Section
                      _buildPrizePanel(analysis),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-WIDGETS & SMART ALERTS
  // ===========================================================================
  Widget _buildAutoSuggestClaimBanner(ReadyToClaimAlert alert) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B894), Color(0xFF00A382)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B894).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Color(0xFF00B894),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '⚡ READY TO CLAIM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SL #${alert.slNo}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${alert.prize.name} Completed!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'All required cells are filled. Tap CLAIM NOW before others!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39C12),
                foregroundColor: Colors.white,
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _handlePrizeClaim(alert.prize),
              child: const Text(
                'CLAIM NOW',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearWinAlertBanner(NearWinAlert alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE67E22),
            Color(0xFFD35400),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD35400).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🔥 1 CELL AWAY!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SL #${alert.slNo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  alert.missingNumber > 0
                      ? 'Waiting for number ${alert.missingNumber} for ${alert.prizeName}!'
                      : 'Just 1 more called number needed for ${alert.prizeName}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (alert.missingNumber > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'NEED',
                    style: TextStyle(
                      color: Color(0xFFD35400),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${alert.missingNumber}',
                    style: const TextStyle(
                      color: Color(0xFFD35400),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawSwitcherCard() {
    final ownedCount = _userPurchasedTickets.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00B894).withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFFF39C12), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _drawTicket?.ticketTitle ?? 'GaGa Housie Draw',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Draw #${_drawTicket?.ticketId ?? ""} • $ownedCount Ticket(s) in Play',
                  style: TextStyle(
                    fontSize: 11,
                    color: ownedCount > 0
                        ? const Color(0xFF00B894)
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _showDrawSelectorBottomSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Switch Draw',
                    style: TextStyle(
                      color: Color(0xFF00B894),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.keyboard_arrow_down,
                      size: 16, color: Color(0xFF00B894)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Blinking LIVE indicator
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 5),
                  Text(
                    'LIVE DRAW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Called: ${_calledNumbers.length}/90',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          // TTS Audio Mute/Unmute
          IconButton(
            icon: Icon(
              _voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceEnabled ? const Color(0xFF00B894) : Colors.grey,
              size: 22,
            ),
            tooltip: _voiceEnabled ? 'Mute Caller Voice' : 'Unmute Caller Voice',
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (!_voiceEnabled) {
                try {
                  _flutterTts.stop();
                } catch (_) {}
              }
            },
          ),
          // Auto Mark All
          InkWell(
            onTap: _autoMarkAll,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00B894).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_fix_high_rounded,
                      size: 14, color: Color(0xFF00B894)),
                  SizedBox(width: 4),
                  Text(
                    'Auto Mark',
                    style: TextStyle(
                      color: Color(0xFF00B894),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentNumberCard() {
    final hasNumber = _currentNumber != null && _currentNumber! > 0;
    final slang = hasNumber ? _tambolaSlang[_currentNumber!] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.radio_button_checked,
                  color: Color(0xFF00B894), size: 16),
              const SizedBox(width: 6),
              Text(
                'LATEST NUMBER CALLED (${_calledNumbers.length}/90)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasNumber) ...[
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B894).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_currentNumber',
                    style: const TextStyle(
                      color: Color(0xFF1E3C72),
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (slang != null)
              InkWell(
                onTap: () {
                  if (_currentNumber != null) {
                    _speakAnnouncement(_currentNumber!);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_up_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '“$slang”',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            Container(
              height: 90,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty_rounded,
                      color: Colors.white70, size: 36),
                  SizedBox(height: 6),
                  Text(
                    'Waiting for host to call first number...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMasterBoardSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _isBoardExpanded = !_isBoardExpanded);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.grid_on_rounded,
                      color: Color(0xFF00B894), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Caller Board (${_calledNumbers.length}/90 Called)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  Icon(
                    _isBoardExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_isBoardExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 90,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (_, index) {
                  final number = index + 1;
                  final isCalled = _calledNumbers.contains(number);
                  final isCurrent = _currentNumber == number;

                  return Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFF39C12)
                          : (isCalled
                              ? const Color(0xFF00B894)
                              : Colors.grey.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFFD68910)
                            : (isCalled
                                ? const Color(0xFF00A382)
                                : Colors.grey.withOpacity(0.15)),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: (isCurrent || isCalled)
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTicketsSection(PatternAnalysisResult analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Tambola Tickets (${_userPurchasedTickets.length})',
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_userPurchasedTickets.isNotEmpty)
              Text(
                'Tap cells to mark / unmark',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_userPurchasedTickets.isEmpty)
          _buildEmptyTicketsCard()
        else
          ..._userPurchasedTickets.asMap().entries.map((entry) {
            final idx = entry.key;
            final tkt = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInteractiveTicketCard(idx, tkt, analysis),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyTicketsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.confirmation_number_outlined,
              size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'No Tickets Owned for ${_drawTicket?.ticketTitle ?? "this Draw"}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'You haven\'t bought any Tambola tickets for Draw #${_drawTicket?.ticketId ?? ""}. If you own tickets in another draw, tap "Switch Draw" above, or buy tickets now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_availableDraws.length > 1) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00B894),
                    side: const BorderSide(color: Color(0xFF00B894)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Switch Draw'),
                  onPressed: _showDrawSelectorBottomSheet,
                ),
                const SizedBox(width: 12),
              ],
              if (_drawTicket != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Buy Tickets',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketSelectionPage(
                          ticket: _drawTicket!.toUpcomingMap(),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTicketCard(
      int ticketIndex, TicketPurchaseModel ticket, PatternAnalysisResult analysis) {
    final marked = _userMarkedNumbers[ticketIndex] ?? <int>{};
    final allNumbers =
        ticket.ticketData.expand((r) => r).whereType<int>().toList();
    final markedCount = allNumbers.where((n) => marked.contains(n)).length;

    final readyForThis = analysis.readyToClaim
        .where((r) => r.ticketIndex == ticketIndex)
        .toList();
    final nearForThis =
        analysis.nearWins.where((n) => n.ticketIndex == ticketIndex).toList();
    final targetNumbers =
        analysis.targetNumbersPerTicket[ticketIndex] ?? <int>{};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00B894).withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: SL No, User Name, Code, Auto-Dab
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SL #${ticket.slNo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.userName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${ticket.serialNumber} • ${ticket.uniqueCode}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Marked tally chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$markedCount/${allNumbers.length} Marked',
                    style: const TextStyle(
                      color: Color(0xFF00B894),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _autoMarkSingleTicket(ticketIndex),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.flash_on_rounded,
                        color: Color(0xFFF39C12), size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Smart In-Ticket Alert Ribbons
            if (readyForThis.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00B894).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFF00B894), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '🎉 READY TO CLAIM: ${readyForThis.map((r) => r.prize.name).join(", ")}!',
                        style: const TextStyle(
                          color: Color(0xFF00896F),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _handlePrizeClaim(readyForThis.first.prize),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B894),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CLAIM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (nearForThis.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE67E22).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFE67E22), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '🔥 1 AWAY from ${nearForThis.first.prizeName}! ' +
                            (nearForThis.first.missingNumber > 0
                                ? 'Waiting for #${nearForThis.first.missingNumber}'
                                : 'Needs 1 more called number'),
                        style: const TextStyle(
                          color: Color(0xFFD35400),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 3x9 Grid Matrix - Interactive Cell Tapping with Target Number Highlight
            ...List.generate(3, (rowIndex) {
              final rowList = rowIndex < ticket.ticketData.length
                  ? ticket.ticketData[rowIndex]
                  : List<int?>.filled(9, null);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: List.generate(9, (colIndex) {
                    final number =
                        colIndex < rowList.length ? rowList[colIndex] : null;
                    final isFreeSlot = number == null;
                    final isCalled =
                        number != null && _calledNumbers.contains(number);
                    final isMarked = number != null && marked.contains(number);
                    final isTarget =
                        number != null && targetNumbers.contains(number);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onCellTapped(ticketIndex, number),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 38,
                          decoration: BoxDecoration(
                            color: isFreeSlot
                                ? Colors.grey.withOpacity(0.04)
                                : (isMarked
                                    ? const Color(0xFF00B894)
                                    : (isCalled
                                        ? const Color(0xFFFFF3CD)
                                        : (isTarget
                                            ? const Color(0xFFFEF9E7)
                                            : Colors.white))),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isFreeSlot
                                  ? Colors.grey.withOpacity(0.12)
                                  : (isMarked
                                      ? (isCalled
                                          ? const Color(0xFFD4AC0D)
                                          : const Color(0xFF00896F))
                                      : (isCalled
                                          ? const Color(0xFFF39C12)
                                          : (isTarget
                                              ? const Color(0xFFF39C12)
                                              : const Color(0xFF00B894)
                                                  .withOpacity(0.25)))),
                              width:
                                  isMarked || isCalled || isTarget ? 1.8 : 1,
                            ),
                            boxShadow: isMarked
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00B894)
                                          .withOpacity(0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : (isTarget
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFF39C12)
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null),
                          ),
                          child: Center(
                            child: isFreeSlot
                                ? const SizedBox.shrink()
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$number',
                                        style: TextStyle(
                                          color: isMarked
                                              ? Colors.white
                                              : (isCalled
                                                  ? const Color(0xFFB7791F)
                                                  : (isTarget
                                                      ? const Color(0xFFD35400)
                                                      : const Color(
                                                          0xFF2C3E50))),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (isMarked) ...[
                                        const SizedBox(width: 1),
                                        const Icon(Icons.check,
                                            size: 10, color: Colors.white),
                                      ] else if (isTarget && !isCalled) ...[
                                        const SizedBox(width: 1),
                                        const Icon(Icons.gps_fixed,
                                            size: 9,
                                            color: Color(0xFFE67E22)),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),

            // Column 1-9 numbering
            const SizedBox(height: 2),
            Row(
              children: List.generate(9, (index) {
                return Expanded(
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizePanel(PatternAnalysisResult analysis) {
    final prizes = _drawTicket?.prizes ?? TicketModel.defaultPrizes();
    final readyPrizes = analysis.readyToClaim
        .map((r) => r.prize.name.toLowerCase().trim())
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prizes & Instant Claims',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF39C12).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Total: ${_drawTicket?.totalPrize ?? "₹75,000"}',
                style: const TextStyle(
                  color: Color(0xFFD68910),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Prizes close immediately once won by a player. Multiple players can claim simultaneously before verification.',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prizes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.85,
          ),
          itemBuilder: (context, index) {
            final prize = prizes[index];
            final pKey = prize.name.toLowerCase().trim();
            final isAwarded = _awardedPrizes.containsKey(pKey);
            final awardInfo = _awardedPrizes[pKey];
            final isPending = _pendingUserClaims.contains(pKey);
            final isReady = readyPrizes.contains(pKey);

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isAwarded
                    ? Colors.grey.shade100
                    : (isPending
                        ? const Color(0xFFFEF5E7)
                        : (isReady ? const Color(0xFFE8F8F5) : Colors.white)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isAwarded
                      ? Colors.grey.shade300
                      : (isPending
                          ? const Color(0xFFE67E22)
                          : (isReady
                              ? const Color(0xFF00B894)
                              : Colors.grey.withOpacity(0.18))),
                  width: isPending || isReady ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAwarded
                            ? Icons.check_circle_rounded
                            : Icons.emoji_events,
                        color: isAwarded
                            ? Colors.grey.shade500
                            : const Color(0xFFF39C12),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          prize.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isAwarded
                                ? Colors.grey.shade600
                                : const Color(0xFF2C3E50),
                            decoration: isAwarded
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        prize.price,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAwarded
                              ? Colors.grey.shade500
                              : const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                  if (isAwarded) ...[
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'Won: ${awardInfo?['winner_name'] ?? 'Player'} (SL #${awardInfo?['sl_no'] ?? ''})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: null,
                        child: Text(
                          'CLOSED 🔒',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ] else if (isPending) ...[
                    const Text(
                      '⏳ Verifying with Host Admin...',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFD35400),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE67E22),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: null,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'VERIFYING...',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (isReady) ...[
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF39C12),
                            elevation: 2,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _handlePrizeClaim(prize),
                          child: const Text(
                            '⚡ READY! CLAIM NOW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B894),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _handlePrizeClaim(prize),
                        child: const Text(
                          'CLAIM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class ClaimValidationResult {
  final bool isValid;
  final String prizeName;
  final TicketPurchaseModel? winningTicket;
  final List<int> requiredNumbers;
  final List<int> missingNumbers;
  final String explanation;

  ClaimValidationResult({
    required this.isValid,
    required this.prizeName,
    this.winningTicket,
    required this.requiredNumbers,
    required this.missingNumbers,
    required this.explanation,
  });
}

class NearWinAlert {
  final String prizeName;
  final int ticketIndex;
  final int slNo;
  final int missingNumber;
  final String patternType;
  final String message;

  NearWinAlert({
    required this.prizeName,
    required this.ticketIndex,
    required this.slNo,
    required this.missingNumber,
    required this.patternType,
    required this.message,
  });
}

class ReadyToClaimAlert {
  final PrizeItem prize;
  final int ticketIndex;
  final int slNo;
  final TicketPurchaseModel ticket;
  final String patternType;
  final String message;

  ReadyToClaimAlert({
    required this.prize,
    required this.ticketIndex,
    required this.slNo,
    required this.ticket,
    required this.patternType,
    required this.message,
  });
}

class PatternAnalysisResult {
  final List<ReadyToClaimAlert> readyToClaim;
  final List<NearWinAlert> nearWins;
  final Map<int, Set<int>> targetNumbersPerTicket;

  PatternAnalysisResult({
    required this.readyToClaim,
    required this.nearWins,
    required this.targetNumbersPerTicket,
  });
}
