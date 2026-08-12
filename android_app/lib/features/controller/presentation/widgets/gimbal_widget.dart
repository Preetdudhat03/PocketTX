import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pockettx_app/core/design/theme_tokens.dart';
import 'package:pockettx_app/core/design/spacing.dart';
import 'package:pockettx_app/core/physics/spring_physics.dart';
import 'package:pockettx_app/core/physics/ratchet_physics.dart';
import 'package:pockettx_app/core/physics/i_stick_physics.dart';
import 'package:pockettx_app/core/state/channel_state.dart';
import 'package:pockettx_app/core/services/haptic_service.dart';
import 'package:pockettx_app/core/constants/channel_constants.dart';

/// Pure rendering gimbal widget — all physics is delegated to IStickPhysics.
class GimbalWidget extends ConsumerStatefulWidget {
  final bool isLeft;
  final String semanticLabel;
  final double size;

  const GimbalWidget({
    super.key,
    required this.isLeft,
    required this.semanticLabel,
    this.size = AppSpacing.gimbalSize,
  });

  @override
  ConsumerState<GimbalWidget> createState() => _GimbalWidgetState();
}

class _GimbalWidgetState extends ConsumerState<GimbalWidget>
    with SingleTickerProviderStateMixin {
  late IStickPhysics _physics;
  late Ticker _ticker;
  DateTime _lastTick = DateTime.now();

  /// Active touch target position while thumb is down on screen.
  /// Null when thumb is removed.
  Offset? _activeTouchTarget;

  @override
  void initState() {
    super.initState();
    // Left stick = Throttle+Yaw (ratchet), Right = Pitch+Roll (spring)
    _physics = widget.isLeft
        ? RatchetPhysics(initialPosition: const Offset(0, -1))
        : SpringPhysics();

    // Flutter Ticker for visual rendering — decoupled from TickEngine
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMicroseconds / 1000000.0;
    _lastTick = now;

    // Update physics with active touch target (null when thumb is removed)
    _physics.update(
      target: _activeTouchTarget,
      dtSeconds: dt.clamp(0.0001, 0.05),
    );

    // Publish channel output
    _publishChannels();

    if (mounted) setState(() {});
  }

  void _onPanStart(DragStartDetails d) {
    final pos = _touchToNorm(d.localPosition);
    _activeTouchTarget = pos;
    _physics.snapTo(pos);
    _publishChannels();
    HapticService().light();
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final pos = _touchToNorm(d.localPosition);
    _activeTouchTarget = pos;
    _physics.update(target: pos, dtSeconds: 0.016);
    _publishChannels();
  }

  void _onPanEnd(DragEndDetails _) {
    _activeTouchTarget = null; // Thumb removed: spring physics takes over
    _physics.update(target: null, dtSeconds: 0.016);
    _publishChannels();
    setState(() {});
  }

  void _onPanCancel() {
    _activeTouchTarget = null; // Touch cancelled: spring physics takes over
    _physics.update(target: null, dtSeconds: 0.016);
    _publishChannels();
    setState(() {});
  }

  Offset _touchToNorm(Offset local) {
    final center = widget.size / 2;
    // Map touch radius so touching near visual track edge reaches 100% full 2000us (+1.0) / 1000us (-1.0)
    final usableRadius = (center - 8) * 0.75;
    return Offset(
      ((local.dx - center) / usableRadius).clamp(-1.0, 1.0),
      -((local.dy - center) / usableRadius).clamp(-1.0, 1.0), // invert Y: up = positive
    );
  }

  void _publishChannels() {
    final notifier = ref.read(channelStateProvider.notifier);

    final pos = _physics.position;
    if (widget.isLeft) {
      // Mode 2: Left = Throttle(Y) + Yaw(X)
      notifier.updateChannel(ChannelConstants.chThrottle, pos.dy);
      notifier.updateChannel(ChannelConstants.chYaw, pos.dx);
    } else {
      // Mode 2: Right = Pitch(Y) + Roll(X)
      notifier.updateChannel(ChannelConstants.chPitch, pos.dy);
      notifier.updateChannel(ChannelConstants.chRoll, pos.dx);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: GimbalRenderer(
          position: _physics.position,
          isPressed: _physics.isPressed,
          size: widget.size,
        ),
      ),
    );
  }
}

/// Pure rendering widget — draws the gimbal track and knob.
class GimbalRenderer extends StatelessWidget {
  final Offset position; // -1.0 to +1.0 on both axes
  final bool isPressed;
  final double size;

  const GimbalRenderer({
    super.key,
    required this.position,
    required this.isPressed,
    this.size = AppSpacing.gimbalSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GimbalPainter(
          position: position,
          isPressed: isPressed,
          primaryColor: AppColors.primary,
          trackColor: context.border,
          surfaceColor: context.cardBg,
        ),
      ),
    );
  }
}

class _GimbalPainter extends CustomPainter {
  final Offset position;
  final bool isPressed;
  final Color primaryColor;
  final Color trackColor;
  final Color surfaceColor;

  _GimbalPainter({
    required this.position,
    required this.isPressed,
    required this.primaryColor,
    required this.trackColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    final trackRadius = outerRadius - 10;
    final usableRadius = trackRadius * 0.78;
    final knobRadius = isPressed ? 18.0 : 15.0;

    // ── 1. Recessed 3D Gimbal Well / Cup Shader ─────────────────
    final wellGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: [
        const Color(0xFF0F131C),
        const Color(0xFF181F2E),
        const Color(0xFF232C3F),
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    canvas.drawCircle(
      center,
      trackRadius,
      Paint()..shader = wellGradient.createShader(Rect.fromCircle(center: center, radius: trackRadius)),
    );

    // ── 2. Outer Metallic CNC Aluminum Bezel Ring ────────────────
    final metalRingPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, outerRadius - 2, metalRingPaint);

    final innerHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerRadius - 4, innerHighlightPaint);

    // ── 3. Degree Notches / Angle Ticks (12 ticks: 30° increments) ─
    final tickPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int deg = 0; deg < 360; deg += 30) {
      final rad = deg * (math.pi / 180.0);
      final isMajor = deg % 90 == 0;
      final tickLen = isMajor ? 6.0 : 3.5;
      final p1 = Offset(
        center.dx + (outerRadius - 2) * math.cos(rad),
        center.dy + (outerRadius - 2) * math.sin(rad),
      );
      final p2 = Offset(
        center.dx + (outerRadius - 2 - tickLen) * math.cos(rad),
        center.dy + (outerRadius - 2 - tickLen) * math.sin(rad),
      );
      canvas.drawLine(p1, p2, isMajor ? (tickPaint..strokeWidth = 2.0) : (tickPaint..strokeWidth = 1.2));
    }

    // ── 4. Concentric Travel Rings & Crosshairs ──────────────────
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, usableRadius, ringPaint);
    canvas.drawCircle(center, usableRadius * 0.5, ringPaint);

    final crossPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(center.dx, center.dy - trackRadius + 4),
      Offset(center.dx, center.dy + trackRadius - 4),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - trackRadius + 4, center.dy),
      Offset(center.dx + trackRadius - 4, center.dy),
      crossPaint,
    );

    // Center Neutral Ring (Deadband circle)
    canvas.drawCircle(
      center,
      8.0,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── 5. Stick Head Offset Calculation ──────────────────────────
    final knobOffset = Offset(
      center.dx + position.dx * usableRadius,
      center.dy - position.dy * usableRadius,
    );

    // ── 6. 3D Metal Stick Shaft Line ──────────────────────────────
    final shaftPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, knobOffset, shaftPaint);

    // ── 7. Realistic CNC Knurled Crown Stick Head ───────────────────
    // Ambient Drop Shadow
    canvas.drawCircle(
      knobOffset.translate(0, 3),
      knobRadius + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Pressed Glow Effect
    if (isPressed) {
      canvas.drawCircle(
        knobOffset,
        knobRadius + 8,
        Paint()
          ..color = primaryColor.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Outer CNC Aluminum Ring
    canvas.drawCircle(
      knobOffset,
      knobRadius,
      Paint()..color = const Color(0xFF2A3447),
    );
    canvas.drawCircle(
      knobOffset,
      knobRadius,
      Paint()
        ..color = isPressed ? primaryColor : primaryColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Knurled Crown Teeth Pattern (8 radial teeth)
    final toothPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      final rad = i * (math.pi / 4.0);
      final p1 = Offset(
        knobOffset.dx + (knobRadius - 4) * math.cos(rad),
        knobOffset.dy + (knobRadius - 4) * math.sin(rad),
      );
      final p2 = Offset(
        knobOffset.dx + (knobRadius - 1) * math.cos(rad),
        knobOffset.dy + (knobRadius - 1) * math.sin(rad),
      );
      canvas.drawLine(p1, p2, toothPaint);
    }

    // Inner Metallic Crown Body
    canvas.drawCircle(
      knobOffset,
      knobRadius - 4,
      Paint()..color = isPressed ? primaryColor : const Color(0xFF1E2638),
    );

    // Center Silver Cap Highlight Dot
    canvas.drawCircle(
      knobOffset,
      3.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_GimbalPainter old) =>
      old.position != position || old.isPressed != isPressed;
}

