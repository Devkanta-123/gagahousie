import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../models/tambola_ticket_model.dart';
import '../services/ticket_service.dart';
import '../services/wallet_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';

/// Available modes to conduct the Tambola draw
enum HousieGameMode {
  systemAuto,
  realLive,
  manual,
}

class AdminHousieGamePage extends StatefulWidget {
  final TicketModel ticket;
  final HousieGameMode initialMode;

  const AdminHousieGamePage({
    super.key,
    required this.ticket,
    this.initialMode = HousieGameMode.systemAuto,
  });

  @override
  State<AdminHousieGamePage> createState() => _AdminHousieGamePageState();
}

class _AdminHousieGamePageState extends State<AdminHousieGamePage>
    with TickerProviderStateMixin {
  late HousieGameMode _activeMode;

  // Numbers State (1 to 90)
  final Set<int> _calledNumbers = {};
  final List<int> _drawHistory = [];
  late List<int> _remainingNumbers;
  int? _currentNumber;

  // Auto Mode State
  bool _isAutoRunning = false;
  Timer? _autoTimer;
  int _intervalSeconds = 5;
  int _countdown = 5;
  Timer? _countdownTimer;

  // Live Video & Mic State
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isCameraInitializing = false;
  bool _cameraPermissionDenied = false;
  bool _isVideoActive = true;
  bool _isMicActive = true;
  Timer? _liveDurationTimer;
  int _liveElapsedSeconds = 0;

  // Manual Mode Quick Input
  final TextEditingController _manualInputController = TextEditingController();

  // Tambola Tickets & Prize Verification
  List<TambolaTicketModel> _tambolaTickets = [];
  bool _isLoadingTickets = true;

  // Voice Announcement (TTS) State
  final FlutterTts _flutterTts = FlutterTts();
  bool _isVoiceEnabled = true;
  bool _isSpeaking = false;
  String? _lastAnnouncementText;
  RealtimeChannel? _broadcastChannel;

  // Audio / Sound Wave Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    40: 'Naughty forty / Life begins',
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
    77: 'Sunset strip / Two hockey sticks',
    78: 'Heaven’s gate',
    79: 'One more time',
    80: 'Blind eighty / Gandhi’s march',
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
    _activeMode = widget.initialMode;
    _remainingNumbers = List<int>.generate(90, (i) => i + 1)..shuffle();

    if (widget.ticket.calledNumbers != null &&
        widget.ticket.calledNumbers!.isNotEmpty) {
      _calledNumbers.addAll(widget.ticket.calledNumbers!);
      _drawHistory.addAll(widget.ticket.calledNumbers!.reversed);
      _remainingNumbers.removeWhere((n) => _calledNumbers.contains(n));
      _currentNumber = widget.ticket.currentNumber ??
          (widget.ticket.calledNumbers!.isNotEmpty
              ? widget.ticket.calledNumbers!.last
              : null);
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initBroadcastChannel();
    _loadTambolaTickets();
    _initTts();
    _sendDrawStartedNotification();

    if (_activeMode == HousieGameMode.realLive) {
      _initCamera();
      _startLiveTimer();
    }
  }

  void _initBroadcastChannel() {
    final client = SupabaseService.instance.client;
    if (client == null) return;
    try {
      _broadcastChannel = client.channel('gaga_broadcast_feed');
      _broadcastChannel?.onBroadcast(
        event: 'prize_claimed',
        callback: (payload) {
          debugPrint('🏆 [ADMIN] Prize claimed event received: $payload');
          final tid = payload['ticket_id']?.toString() ?? '';
          final cleanTid = tid.replaceAll('#', '').trim();
          final currentTid = widget.ticket.ticketId.replaceAll('#', '').trim();
          if (cleanTid.isNotEmpty && cleanTid != currentTid) return;

          final pName = payload['prize_name'] ?? 'Prize';
          final uName = payload['user_name'] ?? 'Player';
          final sl = payload['sl_no']?.toString() ?? '';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF27AE60),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                content: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🎉 $uName (SL #$sl) claimed $pName!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_isVoiceEnabled) {
            _flutterTts.speak('Prize alert! $uName has claimed $pName!');
          }
        },
      );
      _broadcastChannel?.subscribe();
    } catch (e) {
      debugPrint('⚠️ [ADMIN BROADCAST CHANNEL ERROR] $e');
    }
  }

  Future<void> _broadcastNumber(int number) async {
    try {
      final client = SupabaseService.instance.client;
      if (client != null && _broadcastChannel != null) {
        await _broadcastChannel!.sendBroadcastMessage(
          event: 'number_called',
          payload: {
            'ticket_id': widget.ticket.ticketId,
            'number': number,
            'called_numbers': _calledNumbers.toList(),
            'current_number': number,
            'announcement': _lastAnnouncementText,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ [BROADCAST NUMBER ERROR] $e');
    }
  }

  Future<void> _broadcastUnmark(int number) async {
    try {
      final client = SupabaseService.instance.client;
      if (client != null && _broadcastChannel != null) {
        await _broadcastChannel!.sendBroadcastMessage(
          event: 'number_unmarked',
          payload: {
            'ticket_id': widget.ticket.ticketId,
            'number': number,
            'called_numbers': _calledNumbers.toList(),
            'current_number': _currentNumber,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ [BROADCAST UNMARK ERROR] $e');
    }
  }

  Future<void> _broadcastReset() async {
    try {
      final client = SupabaseService.instance.client;
      if (client != null && _broadcastChannel != null) {
        await _broadcastChannel!.sendBroadcastMessage(
          event: 'draw_reset',
          payload: {
            'ticket_id': widget.ticket.ticketId,
            'called_numbers': <int>[],
            'current_number': null,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ [BROADCAST RESET ERROR] $e');
    }
  }

  Future<void> _syncDrawStateToDb() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;
      final cleanId = widget.ticket.ticketId.startsWith('#')
          ? widget.ticket.ticketId.substring(1).trim()
          : widget.ticket.ticketId.trim();

      await client.from('tickets').update({
        'called_numbers': _calledNumbers.toList(),
        'current_number': _currentNumber,
      }).eq('ticket_id', cleanId);
    } catch (e) {
      debugPrint('⚠️ [SYNC DRAW STATE DB ERROR] $e');
    }
  }

  /// Sends real-time notification & broadcast alert to all registered buyers of this draw
  Future<void> _sendDrawStartedNotification() async {
    try {
      final ticketId = widget.ticket.ticketId;
      final ticketTitle = widget.ticket.ticketTitle;
      debugPrint(
          '📢 [DRAW START NOTIFICATION] Fetching registered buyers for draw $ticketId...');

      final buyers = await TicketService.instance.fetchBuyersForDraw(ticketId);
      final Set<dynamic> buyerUserIds = buyers
          .where((b) => b.userId != null && b.userId != 0)
          .map((b) => b.userId)
          .toSet();

      debugPrint(
          '📢 [DRAW START NOTIFICATION] Found ${buyerUserIds.length} buyers for draw $ticketId: $buyerUserIds');

      final client = SupabaseService.instance.client;

      // 1. Insert DB notification for each buyer in user_notifications table
      for (final uid in buyerUserIds) {
        await WalletService.instance.createNotification(
          userId: uid,
          title: '🎯 Housie Draw Started!',
          message:
              'The draw for $ticketTitle (Draw #$ticketId) has officially started! Check your numbers now.',
          type: 'draw_started',
          metadata: {
            'ticket_id': ticketId,
            'ticket_title': ticketTitle,
            'mode': _activeMode.name,
          },
        );
      }

      // 2. Broadcast instant peer-to-peer WebSocket event across all connected clients
      if (client != null) {
        final broadcastChannel = client.channel('gaga_broadcast_feed');
        await broadcastChannel.sendBroadcastMessage(
          event: 'draw_started',
          payload: {
            'ticket_id': ticketId,
            'ticket_title': ticketTitle,
            'title': '🎯 Housie Draw Started!',
            'message':
                'The draw for $ticketTitle has officially started! Check your numbers now.',
            'user_ids': buyerUserIds.map((id) => id.toString()).toList(),
            'notification_id': DateTime.now().millisecondsSinceEpoch,
          },
        );
        debugPrint(
            '✅ [DRAW START NOTIFICATION] Realtime broadcast sent for draw $ticketId');
      }
    } catch (e) {
      debugPrint('⚠️ [DRAW START NOTIFICATION ERROR] $e');
    }
  }

  @override
  void dispose() {
    _broadcastChannel?.unsubscribe();
    _flutterTts.stop();
    _autoTimer?.cancel();
    _countdownTimer?.cancel();
    _liveDurationTimer?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.46);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint('🎙️ [TTS INIT ERROR] $e');
    }
  }

  String _generateAnnouncementText(int number) {
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

    if (slang != null && slang.isNotEmpty) {
      return 'Pick up number is $number! $digitDetail. $slang, $number!';
    } else {
      return 'Pick up number is $number! $digitDetail!';
    }
  }

  Future<void> _announceNumber(int number) async {
    final text = _generateAnnouncementText(number);
    if (mounted) {
      setState(() {
        _lastAnnouncementText = text;
      });
    }

    if (!_isVoiceEnabled) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('🎙️ [TTS SPEAK ERROR] $e');
    }
  }

  void _repeatAnnouncement() {
    if (_currentNumber != null) {
      _announceNumber(_currentNumber!);
    }
  }

  Future<void> _loadTambolaTickets() async {
    try {
      final list = await TicketService.instance
          .fetchTambolaTickets(widget.ticket.ticketId);
      if (mounted) {
        setState(() {
          _tambolaTickets = list;
          _isLoadingTickets = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

  // ===========================================================================
  // CAMERA & MIC MANAGEMENT (Mode 2)
  // ===========================================================================
  Future<void> _initCamera() async {
    if (_isCameraInitializing) return;
    setState(() {
      _isCameraInitializing = true;
      _cameraPermissionDenied = false;
    });

    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.isNotEmpty) {
        // Default to back camera initially if not already explicitly selected
        if (_cameraController == null && _selectedCameraIndex == 0) {
          final backIdx = _availableCameras
              .indexWhere((c) => c.lensDirection == CameraLensDirection.back);
          if (backIdx != -1) {
            _selectedCameraIndex = backIdx;
          }
        }

        final cam = _availableCameras[_selectedCameraIndex.clamp(
            0, _availableCameras.length - 1)];

        final oldController = _cameraController;
        _cameraController = null;
        if (mounted) {
          setState(() {
            _isCameraReady = false;
          });
        }
        await oldController?.dispose();

        final controller = CameraController(
          cam,
          ResolutionPreset.medium,
          enableAudio: _isMicActive,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await controller.initialize();
        if (mounted) {
          setState(() {
            _cameraController = controller;
            _isCameraReady = true;
            _isCameraInitializing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isCameraReady = false;
            _isCameraInitializing = false;
          });
        }
      }
    } catch (e) {
      debugPrint('📹 [CAMERA INIT ERROR] $e');
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _isCameraInitializing = false;
          _cameraPermissionDenied = true;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_isCameraInitializing) return;

    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only 1 camera found on this device'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Determine current lens direction and find the opposite lens
      final currentLens = _cameraController?.description.lensDirection ??
          _availableCameras[_selectedCameraIndex.clamp(0, _availableCameras.length - 1)].lensDirection;
      final oppositeLens = (currentLens == CameraLensDirection.back)
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      final targetCam = _availableCameras.firstWhere(
        (c) => c.lensDirection == oppositeLens,
        orElse: () => _availableCameras[(_selectedCameraIndex + 1) % _availableCameras.length],
      );
      final newIndex = _availableCameras.indexOf(targetCam);
      _selectedCameraIndex = newIndex != -1 ? newIndex : 0;

      if (mounted) {
        setState(() {
          _isCameraInitializing = true;
        });
      }

      // 1. Try fast switch using setDescription
      bool switched = false;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          await _cameraController!.setDescription(targetCam);
          switched = true;
        } catch (e) {
          debugPrint('📹 [setDescription fallback] $e');
          switched = false;
        }
      }

      // 2. Fallback to clean controller disposal and re-initialization
      if (!switched) {
        final oldController = _cameraController;
        _cameraController = null;
        if (mounted) {
          setState(() {
            _isCameraReady = false;
          });
        }
        await oldController?.dispose();

        final newController = CameraController(
          targetCam,
          ResolutionPreset.medium,
          enableAudio: _isMicActive,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await newController.initialize();
        if (mounted) {
          _cameraController = newController;
        }
      }

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _isCameraInitializing = false;
        });

        final lensName = targetCam.lensDirection == CameraLensDirection.front
            ? 'Front Camera'
            : 'Back Camera';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $lensName'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('📹 [SWITCH CAMERA ERROR] $e');
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera flip error: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicActive = !_isMicActive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMicActive
            ? '🎙️ Host Microphone Unmuted (Broadcasting)'
            : '🔇 Host Microphone Muted'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleVideo() {
    setState(() {
      _isVideoActive = !_isVideoActive;
    });
  }

  void _startLiveTimer() {
    _liveDurationTimer?.cancel();
    _liveDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _liveElapsedSeconds++;
        });
      }
    });
  }

  String _formatLiveDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ===========================================================================
  // GAME CALLER LOGIC
  // ===========================================================================
  void _drawNextNumber() {
    if (_remainingNumbers.isEmpty) {
      _pauseAuto();
      _showGameOverDialog();
      return;
    }

    final next = _remainingNumbers.removeAt(0);
    setState(() {
      _currentNumber = next;
      _calledNumbers.add(next);
      _drawHistory.insert(0, next);
      _countdown = _intervalSeconds;
    });

    _broadcastNumber(next);
    _syncDrawStateToDb();

    // Voice announcement for every new pick up
    _announceNumber(next);
  }

  void _markNumber(int number) {
    if (number < 1 || number > 90) return;
    if (_calledNumbers.contains(number)) {
      // Unmark
      setState(() {
        _calledNumbers.remove(number);
        _drawHistory.remove(number);
        _remainingNumbers.add(number);
        _remainingNumbers.shuffle();
        if (_currentNumber == number) {
          _currentNumber = _drawHistory.isNotEmpty ? _drawHistory.first : null;
        }
      });
      _broadcastUnmark(number);
      _syncDrawStateToDb();
    } else {
      // Mark as called
      setState(() {
        _calledNumbers.add(number);
        _drawHistory.insert(0, number);
        _remainingNumbers.remove(number);
        _currentNumber = number;
      });

      _broadcastNumber(number);
      _syncDrawStateToDb();

      // Voice announcement for newly marked pick up
      _announceNumber(number);
    }
  }

  void _undoLastNumber() {
    if (_drawHistory.isEmpty) return;
    final last = _drawHistory.removeAt(0);
    setState(() {
      _calledNumbers.remove(last);
      _remainingNumbers.add(last);
      _remainingNumbers.shuffle();
      _currentNumber = _drawHistory.isNotEmpty ? _drawHistory.first : null;
    });
    _broadcastUnmark(last);
    _syncDrawStateToDb();
  }

  void _resetGame() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Tambola Draw?'),
        content: const Text(
          'This will clear all called numbers and restore all 90 numbers to the pool.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _pauseAuto();
              setState(() {
                _calledNumbers.clear();
                _drawHistory.clear();
                _remainingNumbers =
                    List<int>.generate(90, (i) => i + 1)..shuffle();
                _currentNumber = null;
                _countdown = _intervalSeconds;
              });
              _broadcastReset();
              _syncDrawStateToDb();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AUTO DRAW TIMER MANAGEMENT
  // ===========================================================================
  void _toggleAuto() {
    if (_isAutoRunning) {
      _pauseAuto();
    } else {
      _startAuto();
    }
  }

  void _startAuto() {
    if (_remainingNumbers.isEmpty) {
      _showGameOverDialog();
      return;
    }

    setState(() {
      _isAutoRunning = true;
      _countdown = _intervalSeconds;
    });

    if (_currentNumber == null) {
      _drawNextNumber();
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _countdown = _intervalSeconds;
        });
        _drawNextNumber();
      }
    });
  }

  void _pauseAuto() {
    _countdownTimer?.cancel();
    _autoTimer?.cancel();
    if (mounted) {
      setState(() {
        _isAutoRunning = false;
      });
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emoji_events_rounded, color: Color(0xFFF7971E), size: 28),
            SizedBox(width: 8),
            Text('Draw Complete!'),
          ],
        ),
        content: const Text(
          'All 90 Tambola numbers have been drawn for this ticket!',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('View Board', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: SafeArea(
        child: Column(
          children: [
            // Branded Top Header
            GaGaAppHeader(
              compact: true,
              showBackButton: true,
              title: 'Tambola Live Host',
              subtitle:
                  '${widget.ticket.ticketTitle} • ${widget.ticket.ticketId}',
              showSearch: false,
              showBalance: false,
            ),

            // Mode Selector Bar (Auto / Real Live / Manual)
            _buildModeSelector(),

            // Voice Announcement (TTS) Control Bar
            _buildVoiceAnnouncementBar(),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode-Specific Hero Section
                    if (_activeMode == HousieGameMode.realLive)
                      _buildLiveCameraSection()
                    else if (_activeMode == HousieGameMode.systemAuto)
                      _buildAutoHeroSection()
                    else
                      _buildManualHeroSection(),

                    const SizedBox(height: 12),

                    // Recent Calls Strip
                    _buildRecentCallsStrip(),

                    const SizedBox(height: 12),

                    // 1-90 Master Tambola Board
                    _buildMasterBoard(),

                    const SizedBox(height: 14),

                    // Prize Tiers & Winner Verification Card
                    _buildPrizesAndWinnersCard(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODE SELECTOR BAR
  // ===========================================================================
  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              mode: HousieGameMode.systemAuto,
              icon: Icons.smart_toy_rounded,
              label: 'System Auto',
              activeColor: const Color(0xFF00B894),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeTab(
              mode: HousieGameMode.realLive,
              icon: Icons.videocam_rounded,
              label: 'Real Live',
              activeColor: const Color(0xFFE74C3C),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeTab(
              mode: HousieGameMode.manual,
              icon: Icons.touch_app_rounded,
              label: 'Manual Mark',
              activeColor: const Color(0xFF3498DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required HousieGameMode mode,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _activeMode == mode;
    return InkWell(
      onTap: () {
        if (_activeMode != mode) {
          setState(() {
            _activeMode = mode;
          });
          if (mode == HousieGameMode.realLive && !_isCameraReady) {
            _initCamera();
            _startLiveTimer();
          } else if (mode != HousieGameMode.systemAuto) {
            _pauseAuto();
          }
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isSelected ? activeColor : Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeColor : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VOICE ANNOUNCEMENT BAR
  // ===========================================================================
  Widget _buildVoiceAnnouncementBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _isVoiceEnabled
            ? const Color(0xFF00B894).withOpacity(0.08)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isVoiceEnabled
              ? const Color(0xFF00B894).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _isVoiceEnabled
                  ? const Color(0xFF00B894).withOpacity(0.18)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isVoiceEnabled
                  ? Icons.record_voice_over_rounded
                  : Icons.voice_over_off_rounded,
              size: 15,
              color: _isVoiceEnabled
                  ? const Color(0xFF00B894)
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _isVoiceEnabled
                            ? 'Voice Announcement: ACTIVE'
                            : 'Voice Announcement: MUTED',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _isVoiceEnabled
                              ? const Color(0xFF00B894)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (_isSpeaking) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'SPEAKING...',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _isVoiceEnabled
                      ? (_lastAnnouncementText != null
                          ? '📢 $_lastAnnouncementText'
                          : 'Voice speaks every newly picked number aloud')
                      : 'Tap switch to enable voice announcements',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_isVoiceEnabled && _currentNumber != null) ...[
            InkWell(
              onTap: _repeatAnnouncement,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.replay_rounded,
                        size: 11, color: Color(0xFF00B894)),
                    SizedBox(width: 2),
                    Text(
                      'Replay',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00B894),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Transform.scale(
            scale: 0.72,
            child: Switch(
              value: _isVoiceEnabled,
              activeColor: const Color(0xFF00B894),
              onChanged: (val) {
                setState(() {
                  _isVoiceEnabled = val;
                });
                if (!val) {
                  _flutterTts.stop();
                } else if (_currentNumber != null) {
                  _announceNumber(_currentNumber!);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODE 1: SYSTEM AUTO HERO SECTION
  // ===========================================================================
  Widget _buildAutoHeroSection() {
    final slang = _currentNumber != null ? _tambolaSlang[_currentNumber] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C5364).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.autorenew_rounded,
                          color: Color(0xFF00E676), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _isAutoRunning ? 'CALLING EVERY ${_intervalSeconds}S' : 'AUTO PAUSED',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Called: ${_calledNumbers.length}/90',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Big Number Ball
          ScaleTransition(
            scale: _isAutoRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFF275), Color(0xFFFF8C00)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C00).withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentNumber != null ? '$_currentNumber' : '--',
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Slang / Announcement text with Voice indicator
          if (_currentNumber != null)
            InkWell(
              onTap: _repeatAnnouncement,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSpeaking
                          ? Icons.volume_up_rounded
                          : Icons.record_voice_over_rounded,
                      color: const Color(0xFFFFD54F),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '📢 "Pick up number is $_currentNumber! ${slang ?? ""}"',
                        style: const TextStyle(
                          color: Color(0xFFFFEAA7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.replay_rounded,
                        color: Colors.white54, size: 13),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),

          // Play / Pause and Call Next Controls
          Row(
            children: [
              // Play/Pause Big Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _toggleAuto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isAutoRunning ? Colors.amber.shade700 : const Color(0xFF00B894),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_isAutoRunning
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_fill_rounded),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isAutoRunning
                          ? 'Pause Auto ($_countdown s)'
                          : 'Resume / Start Auto',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Force Next Number Button
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _drawNextNumber,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70, width: 1.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Next Now',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Interval Speed Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Speed: ',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              for (final sec in [3, 5, 8, 10]) ...[
                InkWell(
                  onTap: () {
                    setState(() {
                      _intervalSeconds = sec;
                      _countdown = sec;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _intervalSeconds == sec
                          ? const Color(0xFF00B894)
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${sec}s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: _intervalSeconds == sec
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODE 2: REAL LIVE VIDEO & MIC HERO SECTION
  // ===========================================================================
  Widget _buildLiveCameraSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Camera Stream Area with HUD Overlays
          Stack(
            children: [
              // Live Video Frame / Camera Preview
              SizedBox(
                height: 250,
                width: double.infinity,
                child: _buildCameraPreviewWidget(),
              ),

              // HUD: Top Live Badge & Controls
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LIVE Pulsing Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'LIVE ${_formatLiveDuration(_liveElapsedSeconds)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Quick Stream Toggles (Flip Camera, Mic, Video)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRoundLiveControl(
                          icon: _isMicActive ? Icons.mic : Icons.mic_off,
                          active: _isMicActive,
                          onTap: _toggleMic,
                        ),
                        const SizedBox(width: 5),
                        _buildRoundLiveControl(
                          icon: _isVideoActive
                              ? Icons.videocam
                              : Icons.videocam_off,
                          active: _isVideoActive,
                          onTap: _toggleVideo,
                        ),
                        const SizedBox(width: 5),
                        _buildRoundLiveControl(
                          icon: Icons.flip_camera_ios_rounded,
                          active: true,
                          onTap: _switchCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // HUD: Bottom Floating Current Called Number
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    // Large Live Number Overlay
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'PICK UP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentNumber != null ? '$_currentNumber' : '--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Slang Tag with Voice Replay
                    if (_currentNumber != null)
                      Expanded(
                        child: InkWell(
                          onTap: _repeatAnnouncement,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFFFD54F).withOpacity(0.5),
                                  width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isSpeaking
                                      ? Icons.volume_up_rounded
                                      : Icons.record_voice_over_rounded,
                                  color: const Color(0xFFFFD54F),
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '📢 "Pick up number is $_currentNumber! ${_tambolaSlang[_currentNumber] ?? ""}"',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Host Action Panel below Video
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: const Color(0xFF1E272C),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _drawNextNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B894),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.campaign_rounded, size: 19),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Announce & Draw Next',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _undoLastNumber,
                  icon: const Icon(Icons.undo_rounded, color: Colors.white70, size: 20),
                  tooltip: 'Undo Last Call',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreviewWidget() {
    if (!_isVideoActive) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.videocam_off, size: 42, color: Colors.white38),
              SizedBox(height: 8),
              Text(
                'Host Camera Paused',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_isCameraInitializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00B894),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized) {
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize != null
                  ? _cameraController!.value.previewSize!.height
                  : 1,
              height: _cameraController!.value.previewSize != null
                  ? _cameraController!.value.previewSize!.width
                  : 1,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    // Graceful Simulated Live Host Preview (works on desktop Linux/emulators where physical camera isn't attached)
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_pin_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _cameraPermissionDenied
                  ? 'Camera/Mic Access Required'
                  : 'Live Host Studio Broadcast',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _cameraPermissionDenied
                  ? 'Tap "Grant Permission" to enable real camera feed'
                  : 'Broadcasting live video & audio to players',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _initCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Connect Camera / Mic',
                  style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundLiveControl({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active
              ? Colors.black.withOpacity(0.65)
              : Colors.red.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // ===========================================================================
  // MODE 3: MANUAL MARK HERO SECTION
  // ===========================================================================
  Widget _buildManualHeroSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3498DB).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3498DB).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.touch_app_rounded,
                      color: Color(0xFF2980B9), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Manual Host Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              Text(
                'Called: ${_calledNumbers.length}/90',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Draw a coin from your physical bag and tap the number on the board below, or enter it directly:',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF555555)),
          ),

          // Last Picked Number Announcement in Manual Mode
          if (_currentNumber != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: _repeatAnnouncement,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2980B9), Color(0xFF3498DB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3498DB).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_currentNumber',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2980B9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isSpeaking
                                    ? Icons.volume_up_rounded
                                    : Icons.record_voice_over_rounded,
                                color: const Color(0xFFFFD54F),
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'VOICE ANNOUNCED',
                                style: TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pick up number is $_currentNumber! ${_tambolaSlang[_currentNumber] ?? ""}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.replay_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Quick Number Input Row (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              return Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _manualInputController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText:
                              isNarrow ? 'No. (1-90)' : 'Enter Number (1-90)',
                          hintStyle: const TextStyle(fontSize: 11),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF3498DB), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () {
                      final val =
                          int.tryParse(_manualInputController.text.trim());
                      if (val != null && val >= 1 && val <= 90) {
                        _markNumber(val);
                        _manualInputController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 10 : 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Mark',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _drawNextNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B894),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 8 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.casino_rounded, size: 15),
                    label: Text(
                      isNarrow ? 'Draw' : 'Draw Coin',
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          // Actions: Undo & Reset (Responsive Wrap)
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: _undoLastNumber,
                icon: const Icon(Icons.undo_rounded, size: 15),
                label: const Text('Undo Last Call',
                    style: TextStyle(fontSize: 11.5)),
              ),
              TextButton.icon(
                onPressed: _resetGame,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.restart_alt_rounded, size: 15),
                label: const Text('Reset Board',
                    style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RECENT CALLS STRIP
  // ===========================================================================
  Widget _buildRecentCallsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Text(
            'Recent: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: _drawHistory.isEmpty
                ? const Text(
                    'No numbers called yet',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  )
                : SizedBox(
                    height: 28,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: min(10, _drawHistory.length),
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (ctx, i) {
                        final num = _drawHistory[i];
                        final isLatest = i == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLatest
                                ? const Color(0xFF00B894)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLatest
                                  ? const Color(0xFF00B894)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            '$num',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLatest
                                  ? Colors.white
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1-90 MASTER TAMBOLA BOARD
  // ===========================================================================
  Widget _buildMasterBoard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tambola Master Board (1–90)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              if (_activeMode == HousieGameMode.manual)
                const Text(
                  '💡 Tap any tile to call/unmark',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 10 Columns x 9 Rows = 90 Tiles Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 90,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final number = index + 1;
              final isCalled = _calledNumbers.contains(number);
              final isCurrent = _currentNumber == number;

              return InkWell(
                onTap: () {
                  if (_activeMode == HousieGameMode.manual) {
                    _markNumber(number);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isCalled
                        ? (isCurrent
                            ? const Color(0xFFFF9F43)
                            : const Color(0xFF00B894))
                        : const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.orange.shade800
                          : (isCalled
                              ? const Color(0xFF00B894)
                              : Colors.grey.shade300),
                      width: isCurrent ? 1.8 : 0.8,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isCalled ? FontWeight.bold : FontWeight.w500,
                          color: isCalled ? Colors.white : const Color(0xFF2F3542),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIZES & WINNER VERIFICATION CARD
  // ===========================================================================
  Widget _buildPrizesAndWinnersCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.military_tech_rounded,
                      color: Color(0xFFF39C12), size: 18),
                  SizedBox(width: 5),
                  Text(
                    'Prize Tiers & Claims',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingTickets)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      '${_tambolaTickets.length} Tickets • ',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  Text(
                    'Pool: ${widget.ticket.totalPrize}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B894),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Prize items list
          for (final prize in widget.ticket.prizes) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF1C40F), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            prize.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        prize.price,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _checkWinnersForPrize(prize.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B894).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Check',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF00B894),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _checkWinnersForPrize(String prizeName) {
    if (_tambolaTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No player tickets loaded for this draw yet.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final winningTickets = <Map<String, dynamic>>[];

    for (final ticket in _tambolaTickets) {
      final numbers =
          ticket.ticketData.expand((r) => r).whereType<int>().toList();
      if (numbers.isEmpty) continue;

      bool won = false;
      final nameLower = prizeName.toLowerCase();

      final row0 = ticket.ticketData.isNotEmpty
          ? ticket.ticketData[0].whereType<int>().toList()
          : <int>[];
      final row1 = ticket.ticketData.length > 1
          ? ticket.ticketData[1].whereType<int>().toList()
          : <int>[];
      final row2 = ticket.ticketData.length > 2
          ? ticket.ticketData[2].whereType<int>().toList()
          : <int>[];

      if (nameLower.contains('housefull')) {
        // All 15 numbers called
        won = numbers.every((n) => _calledNumbers.contains(n));
      } else if (nameLower.contains('quick') || nameLower.contains('five')) {
        // Any 5 numbers called
        final calledCount =
            numbers.where((n) => _calledNumbers.contains(n)).length;
        won = calledCount >= 5;
      } else if (nameLower.contains('1st line') || nameLower.contains('top')) {
        won = row0.isNotEmpty && row0.every((n) => _calledNumbers.contains(n));
      } else if (nameLower.contains('2nd line') ||
          nameLower.contains('middle')) {
        won = row1.isNotEmpty && row1.every((n) => _calledNumbers.contains(n));
      } else if (nameLower.contains('3rd line') ||
          nameLower.contains('bottom')) {
        won = row2.isNotEmpty && row2.every((n) => _calledNumbers.contains(n));
      } else if (nameLower.contains('corner')) {
        // Corners: first & last of top & bottom rows
        if (row0.length >= 2 && row2.length >= 2) {
          final corners = [row0.first, row0.last, row2.first, row2.last];
          won = corners.every((n) => _calledNumbers.contains(n));
        }
      }

      if (won) {
        winningTickets.add({
          'player': ticket.playerName,
          'slNo': ticket.slNo,
          'code': ticket.uniqueCode,
          'serial': ticket.serialNumber,
        });
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFF39C12)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$prizeName Claims',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: winningTickets.isEmpty
            ? Text(
                'No tickets have completed "$prizeName" yet with the current ${_calledNumbers.length} called numbers.',
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: winningTickets.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final item = winningTickets[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF00B894),
                        child: Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                      title: Text(
                        '${item['player']} (SL #${item['slNo']})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${item['serial']} • ${item['code']}'),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
