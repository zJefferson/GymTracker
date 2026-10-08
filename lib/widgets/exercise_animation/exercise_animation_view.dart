import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'movement_patterns.dart';
import 'pose.dart';
import 'stick_figure_painter.dart';

/// A small illustrative, code-drawn animation of an exercise's movement
/// pattern. This is a stylized loop (not a literal per-exercise recording)
/// used as a lightweight, fully-offline substitute for a demonstration video.
class ExerciseAnimationView extends StatefulWidget {
  final String patternId;
  const ExerciseAnimationView({super.key, required this.patternId});

  @override
  State<ExerciseAnimationView> createState() => _ExerciseAnimationViewState();
}

class _ExerciseAnimationViewState extends State<ExerciseAnimationView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MovementPattern get _pattern =>
      movementPatterns[widget.patternId] ?? movementPatterns['generic']!;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _pattern.cycleDuration);
    _restart();
  }

  void _restart() {
    _controller.duration = _pattern.cycleDuration;
    _controller.reset();
    if (_pattern.alternating) {
      _controller.repeat();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patternId != widget.patternId) {
      _restart();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _pingPong(double t) => t < 0.5 ? t * 2 : (1 - t) * 2;

  Widget _paint(Size size) {
    final color = Theme.of(context).colorScheme.primary;
    final pattern = _pattern;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        Pose pose;
        Pose? secondary;
        if (pattern.alternating) {
          final t = _controller.value;
          pose = Pose.lerp(pattern.start, pattern.end, _pingPong(t));
          secondary =
              Pose.lerp(pattern.start, pattern.end, _pingPong((t + 0.5) % 1.0));
        } else {
          pose = Pose.lerp(pattern.start, pattern.end, _controller.value);
        }
        return CustomPaint(
          size: size,
          painter: StickFigurePainter(
            pose: pose,
            secondaryLegPose: secondary,
            color: color,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _pattern;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (pattern.orientation == RigOrientation.lying) {
          // Rotating a wide box by 90° would overflow its own bounds unless
          // it's square, so constrain to a centered square before rotating.
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: Transform.rotate(
                angle: -math.pi / 2,
                child: _paint(Size(side, side)),
              ),
            ),
          );
        }
        return _paint(Size(constraints.maxWidth, constraints.maxHeight));
      },
    );
  }
}
