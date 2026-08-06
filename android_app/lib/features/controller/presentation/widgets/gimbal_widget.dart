import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pockettx_app/core/design/theme_tokens.dart';
import 'package:pockettx_app/core/design/spacing.dart';
import 'package:pockettx_app/core/physics/spring_physics.dart';
import 'package:pockettx_app/core/physics/ratchet_physics.dart';
import 'package:pockettx_app/core/physics/i_stick_physics.dart';
import 'package:pockettx_app/core/state/channel_state.dart';
import 'package:pockettx_app/core/state/app_state.dart';
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

    // Update physics (no touch = null target = spring/hold applies)
    _physics.update(target: null, dtSeconds: dt.clamp(0.0001, 0.05));

    // Publish channel output
    _publishChannels();

    if (mounted) setState(() {});
  }

  void _onPanStart(DragStartDetails d) {
    final pos = _touchToNorm(d.localPosition);
    _physics.snapTo(pos);
    HapticService().light();
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final pos = _touchToNorm(d.localPosition);
    _physics.update(target: pos, dtSeconds: 0.016);
    _publishChannels();
  }

  void _onPanEnd(DragEndDetails _) {
    // Physics takes over (spring return or free-stay)
    setState(() {});
  }

  Offset _touchToNorm(Offset local) {
    final half = widget.size / 2;
    return Offset(
      ((local.dx - half) / half).clamp(-1.0, 1.0),
      -((local.dy - half) / half).clamp(-1.0, 1.0), // invert Y: up = positive
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
/// Zero calculations inside.
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
    final trackRadius = size.width / 2 - 8;
    final knobRadius = isPressed ? 18.0 : 14.0;

    // ── Outer ring ─────────────────────────────
    canvas.drawCircle(
      center,
      trackRadius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Crosshair lines ─────────────────────────
    final crossPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, center.dy - trackRadius),
        Offset(center.dx, center.dy + trackRadius), crossPaint);
    canvas.drawLine(Offset(center.dx - trackRadius, center.dy),
        Offset(center.dx + trackRadius, center.dy), crossPaint);

    // ── Knob position ───────────────────────────
    final knobOffset = Offset(
      center.dx + position.dx * trackRadius * 0.8,
      center.dy - position.dy * trackRadius * 0.8,
    );

    // Glow when pressed
    if (isPressed) {
      canvas.drawCircle(
        knobOffset,
        knobRadius + 6,
        Paint()
          ..color = primaryColor.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Knob body
    canvas.drawCircle(
      knobOffset,
      knobRadius,
      Paint()..color = isPressed ? primaryColor : primaryColor.withValues(alpha: 0.7),
    );

    // Knob center dot
    canvas.drawCircle(
      knobOffset,
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_GimbalPainter old) =>
      old.position != position || old.isPressed != isPressed;
}
