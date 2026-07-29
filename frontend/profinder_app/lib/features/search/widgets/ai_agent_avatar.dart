// // ──────────────────────────────────────────────────────────────────────────
// // PROFINER PREMIUM AI AVATAR SYSTEM — FULL SCREEN DEMO
// // ──────────────────────────────────────────────────────────────────────────

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MaterialApp(
//     home: ProFinderAvatarScreen(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

// // ─── STATES ──────────────────────────────────────────────────────────────
// enum PremiumAvatarState {
//   idle,
//   waving,
//   listening,
//   thinking,
//   searching,
//   results,
//   resultsPointing,
//   sad,
//   error,
//   goodbye,
// }

// // ─── CONTROLLER ──────────────────────────────────────────────────────────
// class PremiumAvatarController {
//   _PremiumAIAvatarState? _state;
//   void _attach(_PremiumAIAvatarState s) => _state = s;
//   void _detach() => _state = null;
//   void wave() => _state?._triggerWave();
// }

// // ─── MAIN SCREEN ──────────────────────────────────────────────────────────
// class ProFinderAvatarScreen extends StatefulWidget {
//   const ProFinderAvatarScreen({super.key});

//   @override
//   State<ProFinderAvatarScreen> createState() => _ProFinderAvatarScreenState();
// }

// class _ProFinderAvatarScreenState extends State<ProFinderAvatarScreen> {
//   PremiumAvatarState _currentState = PremiumAvatarState.idle;
//   final PremiumAvatarController _avatarController = PremiumAvatarController();
//   bool _isSad = false;
//   String? _userName = "Zeeshan"; // Default user name

//   // Helper helper to get state label
//   String get _stateLabel {
//     if (_isSad) return "SAD / LIMIT EXCEEDED";
//     switch (_currentState) {
//       case PremiumAvatarState.idle: return "IDLE (BREATHING)";
//       case PremiumAvatarState.waving: return "WAVING HAND";
//       case PremiumAvatarState.listening: return "LISTENING...";
//       case PremiumAvatarState.thinking: return "THINKING";
//       case PremiumAvatarState.searching: return "SEARCHING DB";
//       case PremiumAvatarState.results: return "RESULTS FOUND";
//       default: return "ACTIVE";
//     }
//   }

//   Color get _statusColor {
//     if (_isSad) return Colors.red;
//     switch (_currentState) {
//       case PremiumAvatarState.thinking:
//       case PremiumAvatarState.searching:
//         return Colors.orange;
//       case PremiumAvatarState.results:
//         return Colors.green;
//       default:
//         return const Color(0xFF0066FF);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC), // Ultra-clean soft grey background
//       appBar: AppBar(
//         title: const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "ProFinder AI",
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
//             ),
//             Text(
//               "Active Agent System",
//               style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
//             onPressed: () {
//               setState(() {
//                 _currentState = PremiumAvatarState.idle;
//                 _isSad = false;
//               });
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 1. Status Indicator Header
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.02),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 10,
//                     height: 10,
//                     decoration: BoxDecoration(
//                       color: _statusColor,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     "STATUS: $_stateLabel",
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: _statusColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // 2. Main Center Avatar Stage
//             Expanded(
//               child: Center(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Interactive Premium Avatar Container
//                       PremiumAIAvatar(
//                         height: 240, // Perfect display height
//                         state: _currentState,
//                         isSad: _isSad,
//                         userName: _userName,
//                         controller: _avatarController,
//                         onTap: () {
//                           // Tap triggers wave by default
//                           _avatarController.wave();
//                         },
//                       ),
//                       const SizedBox(height: 30),
//                       const Text(
//                         "Tap the Avatar to trigger Wave Hand!",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF94A3B8),
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // 3. Controller Panel (Bottom Board)
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(24),
//                   topRight: Radius.circular(24),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black25,
//                     blurRadius: 16,
//                     offset: Offset(0, -4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Test State Transitions:",
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E293B),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   // Quick State Buttons Grid
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       _buildStateButton("Idle", PremiumAvatarState.idle, isSpecial: false),
//                       _buildStateButton("Wave 👋", PremiumAvatarState.waving, isSpecial: false),
//                       _buildStateButton("Thinking 🧠", PremiumAvatarState.thinking, isSpecial: false),
//                       _buildStateButton("Searching 🔍", PremiumAvatarState.searching, isSpecial: false),
//                       _buildStateButton("Results ✨", PremiumAvatarState.results, isSpecial: false),
//                       _buildStateButton(
//                         "Sad / Error ⚠️",
//                         PremiumAvatarState.sad,
//                         isSpecial: true,
//                         onTapOverride: () {
//                           setState(() {
//                             _isSad = true;
//                             _currentState = PremiumAvatarState.sad;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStateButton(
//     String label,
//     PremiumAvatarState targetState, {
//     required bool isSpecial,
//     VoidCallback? onTapOverride,
//   }) {
//     final bool isActive = _isSad ? (targetState == PremiumAvatarState.sad) : (_currentState == targetState);
    
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isActive 
//             ? (isSpecial ? Colors.red : const Color(0xFF0066FF)) 
//             : const Color(0xFFF1F5F9),
//         foregroundColor: isActive ? Colors.white : const Color(0xFF475569),
//         elevation: isActive ? 2 : 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//           side: BorderSide(
//             color: isActive ? Colors.transparent : const Color(0xFFE2E8F0),
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       ),
//       onPressed: onTapOverride ?? () {
//         setState(() {
//           _isSad = false;
//           _currentState = targetState;
//         });
//       },
//       child: Text(
//         label,
//         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//       ),
//     );
//   }
// }

// // ─── PREMIUM AVATAR COMPONENT ─────────────────────────────────────────────
// class PremiumAIAvatar extends StatefulWidget {
//   final double height;
//   final PremiumAvatarState state;
//   final bool isSad;
//   final String? userName;
//   final PremiumAvatarController? controller;
//   final VoidCallback? onTap;

//   const PremiumAIAvatar({
//     super.key,
//     this.height = 200,
//     this.state = PremiumAvatarState.idle,
//     this.isSad = false,
//     this.userName,
//     this.controller,
//     this.onTap,
//   });

//   PremiumAvatarState get _effectiveState =>
//       isSad ? PremiumAvatarState.sad : state;

//   @override
//   State<PremiumAIAvatar> createState() => _PremiumAIAvatarState();
// }

// class _PremiumAIAvatarState extends State<PremiumAIAvatar>
//     with TickerProviderStateMixin {
//   late AnimationController _breatheCtrl;
//   late AnimationController _waveCtrl;
//   late Animation<double> _waveAnim;
//   late AnimationController _entranceCtrl;
//   late Animation<double> _entranceAnim;
//   late AnimationController _pulseCtrl;
//   late AnimationController _glowCtrl;

//   bool _eyesClosed = false;
//   Timer? _blinkTimer;
//   bool _showGreeting = false;
//   Timer? _greetingTimer;

//   @override
//   void initState() {
//     super.initState();
//     widget.controller?._attach(this);

//     _breatheCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2400),
//     )..repeat(reverse: true);

//     _waveCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1600),
//     );
    
//     _waveAnim = TweenSequence<double>([
//       TweenSequenceItem(
//         tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
//         weight: 1.2,
//       ),
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.78), weight: 0.8),
//       TweenSequenceItem(tween: Tween(begin: 0.78, end: 1.0), weight: 0.8),
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.78), weight: 0.8),
//       TweenSequenceItem(
//         tween: Tween(begin: 0.78, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
//         weight: 1.2,
//       ),
//     ]).animate(_waveCtrl);

//     _entranceCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _entranceAnim = CurvedAnimation(
//       parent: _entranceCtrl,
//       curve: Curves.easeOut,
//     );

//     _pulseCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1100),
//     )..repeat();

//     _glowCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1800),
//     )..repeat(reverse: true);

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _entranceCtrl.forward();
//       if (widget._effectiveState != PremiumAvatarState.sad) {
//         Future.delayed(const Duration(milliseconds: 380), _triggerWave);
//       }
//       if (widget.userName != null) _startGreeting();
//     });

//     _scheduleNextBlink();
//   }

//   void _startGreeting() {
//     if (!mounted) return;
//     setState(() => _showGreeting = true);
//     _greetingTimer?.cancel();
//     _greetingTimer = Timer(const Duration(milliseconds: 3800), () {
//       if (mounted) setState(() => _showGreeting = false);
//     });
//   }

//   void _scheduleNextBlink() {
//     _blinkTimer = Timer(
//       Duration(milliseconds: 1800 + Random().nextInt(3200)),
//       () async {
//         if (!mounted) return;
//         final s = widget._effectiveState;
//         final suppress = s == PremiumAvatarState.listening ||
//             s == PremiumAvatarState.searching ||
//             s == PremiumAvatarState.thinking;
//         if (!suppress) {
//           setState(() => _eyesClosed = true);
//           await Future.delayed(const Duration(milliseconds: 130));
//           if (!mounted) return;
//           setState(() => _eyesClosed = false);
//         }
//         _scheduleNextBlink();
//       },
//     );
//   }

//   void _triggerWave() {
//     if (!mounted || widget._effectiveState == PremiumAvatarState.sad) return;
//     _waveCtrl.forward(from: 0);
//   }

//   @override
//   void didUpdateWidget(covariant PremiumAIAvatar old) {
//     super.didUpdateWidget(old);
//     if (widget.controller != old.controller) {
//       old.controller?._detach();
//       widget.controller?._attach(this);
//     }
//     if (widget.userName != old.userName && widget.userName != null) {
//       _startGreeting();
//     }
//   }

//   @override
//   void dispose() {
//     widget.controller?._detach();
//     _breatheCtrl.dispose();
//     _waveCtrl.dispose();
//     _entranceCtrl.dispose();
//     _pulseCtrl.dispose();
//     _glowCtrl.dispose();
//     _blinkTimer?.cancel();
//     _greetingTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final h = widget.height;
//     final state = widget._effectiveState;

//     return AnimatedBuilder(
//       animation: Listenable.merge([
//         _breatheCtrl,
//         _waveCtrl,
//         _entranceCtrl,
//         _pulseCtrl,
//         _glowCtrl,
//       ]),
//       builder: (_, __) {
//         final slideX = (1 - _entranceAnim.value) * h;
//         final breathe = sin(_breatheCtrl.value * pi) * 3.0;
//         final waveT = _waveAnim.value;
//         final pulse = _pulseCtrl.value;
//         final glow = _glowCtrl.value;

//         return Transform.translate(
//           offset: Offset(slideX, 0),
//           child: GestureDetector(
//             onTap: () {
//               _triggerWave();
//               widget.onTap?.call();
//             },
//             behavior: HitTestBehavior.translucent,
//             child: SizedBox(
//               width: h * 0.95,
//               height: h + 20,
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   // 1. Dynamic Greeting Speech Bubble
//                   if (_showGreeting)
//                     Positioned(
//                       left: 0,
//                       top: h * 0.04,
//                       width: h * 0.70,
//                       child: _PremiumGreetingBubble(
//                         name: widget.userName ?? '',
//                         state: state,
//                       ),
//                     ),

//                   // 2. Custom Painter Canvas with dynamic breath
//                   Positioned(
//                     right: 0,
//                     top: 4,
//                     child: Transform.translate(
//                       offset: Offset(0, breathe),
//                       child: CustomPaint(
//                         size: Size(h * 0.75, h),
//                         painter: _PremiumRobotPainter(
//                           eyesClosed: _eyesClosed,
//                           waveT: waveT,
//                           state: state,
//                           pulse: pulse,
//                           glow: glow,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // ─── GREETING SPEECH BUBBLE ──────────────────────────────────────────────
// class _PremiumGreetingBubble extends StatelessWidget {
//   final String name;
//   final PremiumAvatarState state;

//   const _PremiumGreetingBubble({
//     required this.name,
//     required this.state,
//   });

//   String get _title {
//     switch (state) {
//       case PremiumAvatarState.sad:
//       case PremiumAvatarState.error:
//         return '⚠️ Free limit reached';
//       case PremiumAvatarState.results:
//       case PremiumAvatarState.resultsPointing:
//         return '✨ Found results!';
//       default:
//         return name.isEmpty ? '👋 Hi there!' : '👋 Hi, $name!';
//     }
//   }

//   String get _subtitle {
//     switch (state) {
//       case PremiumAvatarState.sad:
//       case PremiumAvatarState.error:
//         return 'Upgrade for unlimited search.';
//       case PremiumAvatarState.results:
//       case PremiumAvatarState.resultsPointing:
//         return 'Tap to view all matches.';
//       default:
//         return 'How can I help you today?';
//     }
//   }

//   Color get _accent {
//     if (state == PremiumAvatarState.sad || state == PremiumAvatarState.error) {
//       return const Color(0xFFEF4444);
//     }
//     return const Color(0xFF0066FF);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: const Color(0xFFEDEFF5), width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.08),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 6,
//                     height: 6,
//                     decoration: BoxDecoration(
//                       color: _accent,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Flexible(
//                     child: Text(
//                       _title,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1E293B),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 _subtitle,
//                 style: const TextStyle(
//                   fontSize: 11,
//                   color: Color(0xFF64748B),
//                   height: 1.3,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           right: 12,
//           bottom: -5,
//           child: Transform.rotate(
//             angle: pi / 4,
//             child: Container(
//               width: 10,
//               height: 10,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 border: Border.all(color: const Color(0xFFEDEFF5), width: 1),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─── PREMIUM VECTOR PAINTER ──────────────────────────────────────────────
// class _PremiumRobotPainter extends CustomPainter {
//   final bool eyesClosed;
//   final double waveT;
//   final PremiumAvatarState state;
//   final double pulse;
//   final double glow;

//   const _PremiumRobotPainter({
//     required this.eyesClosed,
//     required this.waveT,
//     required this.state,
//     required this.pulse,
//     required this.glow,
//   });

//   static const Color _pearlWhite = Color(0xFFF5F8FF);
//   static const Color _outline = Color(0xFFC5D0E8);
//   static const Color _electricBlue = Color(0xFF0066FF);
//   static const Color _darkVisor = Color(0xFF0A0E1A);
//   static const Color _glowBlue = Color(0xFF00CCFF);
//   static const Color _green = Color(0xFF22C55E);
//   static const Color _red = Color(0xFFEF4444);

//   bool get _isThinking => state == PremiumAvatarState.thinking;
//   bool get _isSearching => state == PremiumAvatarState.searching;
//   bool get _isListening => state == PremiumAvatarState.listening;
//   bool get _isSad => state == PremiumAvatarState.sad || state == PremiumAvatarState.error;
//   bool get _isWaving => state == PremiumAvatarState.waving;

//   Color get _eyeColor => _isSad ? _red : _glowBlue;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final w = size.width;
//     final h = size.height;
//     final cx = w / 2;

//     // 1. Ambient Drop Shadow
//     final shadowPaint = Paint()
//       ..color = Colors.black.withOpacity(0.08)
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
//     canvas.drawOval(
//       Rect.fromCenter(
//         center: Offset(cx, h * 0.97),
//         width: w * 0.65,
//         height: h * 0.03,
//       ),
//       shadowPaint,
//     );

//     // 2. Cute Rounded Feet
//     for (final fx in [cx - w * 0.16, cx + w * 0.16]) {
//       _drawOval(canvas, Offset(fx, h * 0.92), w * 0.14, h * 0.06, _pearlWhite);
//     }

//     // 3. Mini Leg Joints
//     for (final lx in [cx - w * 0.11, cx + w * 0.11]) {
//       canvas.drawRect(
//         Rect.fromCenter(center: Offset(lx, h * 0.86), width: w * 0.08, height: h * 0.08),
//         Paint()..color = _electricBlue.withOpacity(0.12),
//       );
//     }

//     // 4. Capsule Body (waist taper)
//     final bodyPath = Path();
//     bodyPath.moveTo(cx - w * 0.35, h * 0.46);
//     bodyPath.quadraticBezierTo(cx - w * 0.38, h * 0.65, cx - w * 0.28, h * 0.80);
//     bodyPath.lineTo(cx + w * 0.28, h * 0.80);
//     bodyPath.quadraticBezierTo(cx + w * 0.38, h * 0.65, cx + w * 0.35, h * 0.46);
//     bodyPath.close();

//     canvas.drawPath(
//       bodyPath,
//       Paint()
//         ..color = _pearlWhite
//         ..shader = const LinearGradient(
//           colors: [Color(0xFFFFFFFF), Color(0xFFECEFFF)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ).createShader(Rect.fromLTWH(0, h * 0.4, w, h * 0.45)),
//     );

//     // Body Contour Border
//     canvas.drawPath(
//       bodyPath,
//       Paint()
//         ..color = _outline
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2.0,
//     );

//     // 5. "Pf" Tummy Badge (Overlap vector graphics layout)
//     _drawTummyBadgeOptimized(canvas, cx, h * 0.64, w * 0.12, w);

//     // 6. Double Limbs (Interactive Wave angle)
//     _drawArm(canvas, w, h, isLeft: true, raiseT: 0);
//     _drawArm(canvas, w, h, isLeft: false, raiseT: _isWaving ? waveT : 0);

//     // 7. Large Rounded Head Block (40% proportional height)
//     final headRect = Rect.fromCenter(center: Offset(cx, h * 0.24), width: w * 0.82, height: h * 0.36);
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.16)),
//       Paint()..color = _pearlWhite,
//     );
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.16)),
//       Paint()
//         ..color = _outline
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2.0,
//     );

//     // 8. Dual Top Antennas with Neon Orbs
//     final antPulse = (_isSearching || _isThinking) ? (0.7 + 0.3 * sin(pulse * 2 * pi)) : 1.0;
//     for (final ax in [cx - w * 0.22, cx + w * 0.22]) {
//       canvas.drawLine(
//         Offset(ax, h * 0.06),
//         Offset(ax, -h * 0.01),
//         Paint()
//           ..color = _outline
//           ..strokeWidth = w * 0.025
//           ..strokeCap = StrokeCap.round,
//       );
//       // Soft ambient aura glow
//       canvas.drawCircle(
//         Offset(ax, -h * 0.02),
//         w * 0.06,
//         Paint()
//           ..color = _eyeColor.withOpacity(0.5 * antPulse)
//           ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02),
//       );
//       // Inner glowing solid core
//       canvas.drawCircle(Offset(ax, -h * 0.02), w * 0.035, Paint()..color = _eyeColor);
//     }

//     // 9. Curved Premium Visor (Black high-gloss glass look)
//     final visorRect = Rect.fromCenter(center: Offset(cx, h * 0.24), width: w * 0.70, height: h * 0.28);
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(visorRect, Radius.circular(w * 0.10)),
//       Paint()..color = _darkVisor,
//     );

//     // Curved shine / Reflection overlay
//     final reflectionPaint = Paint()
//       ..color = Colors.white.withOpacity(0.06)
//       ..style = PaintingStyle.fill;
//     final reflectionPath = Path()
//       ..moveTo(cx - w * 0.35, h * 0.14)
//       ..lineTo(cx + w * 0.35, h * 0.14)
//       ..lineTo(cx + w * 0.35, h * 0.20)
//       ..quadraticBezierTo(cx, h * 0.25, cx - w * 0.35, h * 0.20)
//       ..close();
//     canvas.drawPath(reflectionPath, reflectionPaint);

//     // Dynamic color glow boundary rim
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(visorRect, Radius.circular(w * 0.10)),
//       Paint()
//         ..color = _eyeColor.withOpacity(0.3 + 0.2 * glow)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2.0,
//     );

//     // 10. Cute Animated LED Eyes
//     final eyeY = h * 0.24;
//     final eyeLX = cx - w * 0.16;
//     final eyeRX = cx + w * 0.16;
//     final eyeR = w * 0.07;

//     for (final ex in [eyeLX, eyeRX]) {
//       canvas.drawCircle(
//         Offset(ex, eyeY),
//         eyeR * 1.4,
//         Paint()
//           ..color = _eyeColor.withOpacity(0.20)
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
//       );
//     }

//     if (eyesClosed && !_isThinking && !_isListening) {
//       // Blink bar lines
//       for (final ex in [eyeLX, eyeRX]) {
//         canvas.drawLine(
//           Offset(ex - w * 0.05, eyeY),
//           Offset(ex + w * 0.05, eyeY),
//           Paint()
//             ..color = _eyeColor
//             ..strokeWidth = w * 0.025
//             ..strokeCap = StrokeCap.round,
//         );
//       }
//     } else {
//       // Circle eyes with dynamic shine reflection
//       for (final ex in [eyeLX, eyeRX]) {
//         canvas.drawCircle(Offset(ex, eyeY), eyeR, Paint()..color = _eyeColor);
//         canvas.drawCircle(Offset(ex - 2, eyeY - 2), eyeR * 0.30, Paint()..color = Colors.white);
//       }
//     }
//   }

//   void _drawOval(Canvas canvas, Offset center, double rw, double rh, Color color) {
//     canvas.drawOval(
//       Rect.fromCenter(center: center, width: rw, height: rh),
//       Paint()..color = color,
//     );
//     canvas.drawOval(
//       Rect.fromCenter(center: center, width: rw, height: rh),
//       Paint()
//         ..color = _outline
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.5,
//     );
//   }

//   void _drawArm(Canvas canvas, double w, double h, {required bool isLeft, double raiseT = 0}) {
//     final side = isLeft ? -1.0 : 1.0;
//     final shX = w * (isLeft ? 0.18 : 0.82);
//     final shY = h * 0.50;

//     final restAngle = isLeft ? 0.40 : -0.40;
//     final waveAngle = isLeft ? 2.40 : -2.40;
//     final angle = restAngle + (waveAngle - restAngle) * raiseT * side;

//     final armLen = h * 0.18;
//     final hand = Offset(
//       shX + sin(angle) * armLen,
//       shY + cos(angle) * armLen,
//     );

//     canvas.drawLine(
//       Offset(shX, shY),
//       hand,
//       Paint()
//         ..color = _pearlWhite
//         ..strokeWidth = w * 0.10
//         ..strokeCap = StrokeCap.round,
//     );
//     canvas.drawLine(
//       Offset(shX, shY),
//       hand,
//       Paint()
//         ..color = _outline
//         ..strokeWidth = w * 0.10
//         ..strokeCap = StrokeCap.round
//         ..style = PaintingStyle.stroke,
//     );
//   }

//   void _drawTummyBadgeOptimized(Canvas canvas, double cx, double cy, double radius, double w) {
//     final shadowPaint = Paint()
//       ..color = Colors.black.withOpacity(0.06)
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
//     canvas.drawCircle(Offset(cx, cy + 2), radius, shadowPaint);
    
//     canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = Colors.white);
//     canvas.drawCircle(
//       Offset(cx, cy),
//       radius,
//       Paint()
//         ..color = _outline.withOpacity(0.6)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.2,
//     );

//     // Premium Vector overlapping Brand Letters "Pf"
//     final pPaint = Paint()
//       ..color = _electricBlue
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = w * 0.018;

//     final fPaint = Paint()
//       ..color = _green
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = w * 0.016;

//     // "P"
//     final pPath = Path()
//       ..moveTo(cx - radius * 0.35, cy + radius * 0.35)
//       ..lineTo(cx - radius * 0.35, cy - radius * 0.35)
//       ..arcTo(
//         Rect.fromLTWH(cx - radius * 0.35, cy - radius * 0.35, radius * 0.5, radius * 0.42),
//         -pi / 2,
//         pi,
//         false,
//       );
//     canvas.drawPath(pPath, pPaint);

//     // "f"
//     final fPath = Path()
//       ..moveTo(cx + radius * 0.15, cy + radius * 0.4)
//       ..lineTo(cx + radius * 0.15, cy - radius * 0.25)
//       ..arcTo(
//         Rect.fromLTWH(cx + radius * 0.15, cy - radius * 0.45, radius * 0.32, radius * 0.45),
//         pi,
//         pi / 2,
//         false,
//       );
//     canvas.drawPath(fPath, fPaint);

//     // "f" Bar
//     canvas.drawLine(
//       Offset(cx + radius * 0.01, cy - radius * 0.08),
//       Offset(cx + radius * 0.30, cy - radius * 0.08),
//       fPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _PremiumRobotPainter oldDelegate) {
//     return oldDelegate.eyesClosed != eyesClosed ||
//         oldDelegate.waveT != waveT ||
//         oldDelegate.state != state ||
//         oldDelegate.pulse != pulse ||
//         oldDelegate.glow != glow;
//   }
// }