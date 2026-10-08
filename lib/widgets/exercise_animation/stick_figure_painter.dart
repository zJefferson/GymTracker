import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'pose.dart';

class StickFigurePainter extends CustomPainter {
  final Pose pose;
  final Pose? secondaryLegPose;
  final Color color;

  StickFigurePainter({
    required this.pose,
    required this.color,
    this.secondaryLegPose,
  });

  Offset _limbVector(double angle, double length) {
    return Offset(math.sin(angle) * length, -math.cos(angle) * length);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(3, size.height * 0.045)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final legLength = size.height * 0.16;
    final armLength = size.height * 0.15;
    final torsoLength = size.height * 0.26;
    final headRadius = size.height * 0.065;

    final pelvisBaseY = size.height * 0.60;
    final pelvis = Offset(
      size.width / 2,
      pelvisBaseY + pose.pelvisDrop * legLength * 0.6,
    );

    final neck = pelvis +
        Offset(
          math.sin(pose.torsoTilt) * torsoLength,
          -math.cos(pose.torsoTilt) * torsoLength * (1 + pose.chestExpand * 0.06),
        );
    final headCenter = neck +
        Offset(
          math.sin(pose.torsoTilt) * headRadius * 1.4,
          -math.cos(pose.torsoTilt) * headRadius * 1.4,
        );

    // Ground line.
    final groundY = pelvisBaseY + legLength * 1.85;
    canvas.drawLine(
      Offset(size.width * 0.12, groundY),
      Offset(size.width * 0.88, groundY),
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 2,
    );

    // Torso and head.
    canvas.drawLine(pelvis, neck, paint);
    canvas.drawCircle(headCenter, headRadius, paint);

    // Arm.
    final elbow = neck + _limbVector(pose.shoulderAngle, armLength);
    final wrist = elbow + _limbVector(pose.shoulderAngle + pose.elbowBend, armLength * 0.9);
    canvas.drawLine(neck, elbow, paint);
    canvas.drawLine(elbow, wrist, paint);

    // Primary leg.
    final knee = pelvis + _limbVector(pose.hipAngle, legLength);
    final ankle = knee + _limbVector(pose.hipAngle + pose.kneeBend, legLength * 0.9);
    canvas.drawLine(pelvis, knee, paint);
    canvas.drawLine(knee, ankle, paint);

    // Secondary (opposite-phase) leg, used for alternating cardio patterns.
    final secondary = secondaryLegPose;
    if (secondary != null) {
      final ghostPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = paint.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final knee2 = pelvis + _limbVector(secondary.hipAngle, legLength);
      final ankle2 = knee2 + _limbVector(secondary.hipAngle + secondary.kneeBend, legLength * 0.9);
      canvas.drawLine(pelvis, knee2, ghostPaint);
      canvas.drawLine(knee2, ankle2, ghostPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StickFigurePainter oldDelegate) => true;
}
