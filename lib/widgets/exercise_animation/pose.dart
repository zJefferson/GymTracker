import 'dart:ui' show lerpDouble;

/// A simplified stick-figure pose. All angles are in radians, measured from
/// straight down (0) increasing as the limb rotates forward/up.
class Pose {
  final double torsoTilt;
  final double shoulderAngle;
  final double elbowBend;
  final double hipAngle;
  final double kneeBend;
  final double pelvisDrop;
  final double chestExpand;

  const Pose({
    this.torsoTilt = 0,
    this.shoulderAngle = 0.15,
    this.elbowBend = 0,
    this.hipAngle = 0,
    this.kneeBend = 0,
    this.pelvisDrop = 0,
    this.chestExpand = 0,
  });

  static Pose lerp(Pose a, Pose b, double t) {
    return Pose(
      torsoTilt: lerpDouble(a.torsoTilt, b.torsoTilt, t)!,
      shoulderAngle: lerpDouble(a.shoulderAngle, b.shoulderAngle, t)!,
      elbowBend: lerpDouble(a.elbowBend, b.elbowBend, t)!,
      hipAngle: lerpDouble(a.hipAngle, b.hipAngle, t)!,
      kneeBend: lerpDouble(a.kneeBend, b.kneeBend, t)!,
      pelvisDrop: lerpDouble(a.pelvisDrop, b.pelvisDrop, t)!,
      chestExpand: lerpDouble(a.chestExpand, b.chestExpand, t)!,
    );
  }
}
