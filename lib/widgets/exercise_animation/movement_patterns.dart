import 'pose.dart';

enum RigOrientation { standing, lying }

class MovementPattern {
  final Pose start;
  final Pose end;
  final RigOrientation orientation;
  final bool alternating;
  final Duration cycleDuration;

  const MovementPattern({
    required this.start,
    required this.end,
    this.orientation = RigOrientation.standing,
    this.alternating = false,
    this.cycleDuration = const Duration(milliseconds: 1400),
  });
}

/// Simplified illustrative movement patterns shared across similar
/// exercises. These are stylized stick-figure loops, not literal
/// per-exercise demonstrations.
final Map<String, MovementPattern> movementPatterns = {
  'push_horizontal': const MovementPattern(
    orientation: RigOrientation.lying,
    start: Pose(shoulderAngle: 1.55, elbowBend: 1.9),
    end: Pose(shoulderAngle: 1.45, elbowBend: 0.1),
  ),
  'push_vertical': const MovementPattern(
    start: Pose(shoulderAngle: 1.35, elbowBend: 1.8),
    end: Pose(shoulderAngle: 2.9, elbowBend: 0.1),
  ),
  'fly_chest': const MovementPattern(
    start: Pose(shoulderAngle: 1.75, elbowBend: 0.35),
    end: Pose(shoulderAngle: 0.5, elbowBend: 0.5),
  ),
  'pull_horizontal': const MovementPattern(
    start: Pose(torsoTilt: 0.55, shoulderAngle: 0.75, elbowBend: 0.1),
    end: Pose(torsoTilt: 0.55, shoulderAngle: -0.35, elbowBend: 1.7),
  ),
  'pull_vertical': const MovementPattern(
    start: Pose(shoulderAngle: 3.0, elbowBend: 0.1),
    end: Pose(shoulderAngle: 0.6, elbowBend: 1.6),
  ),
  'bicep_curl': const MovementPattern(
    start: Pose(shoulderAngle: 0.15, elbowBend: 0.05),
    end: Pose(shoulderAngle: 0.15, elbowBend: 2.1),
  ),
  'triceps_extension': const MovementPattern(
    start: Pose(shoulderAngle: 2.7, elbowBend: 1.9),
    end: Pose(shoulderAngle: 2.7, elbowBend: 0.1),
  ),
  'lateral_raise': const MovementPattern(
    start: Pose(shoulderAngle: 0.15, elbowBend: 0.15),
    end: Pose(shoulderAngle: 1.5, elbowBend: 0.15),
  ),
  'squat': const MovementPattern(
    cycleDuration: Duration(milliseconds: 1700),
    start: Pose(hipAngle: 0, kneeBend: 0, pelvisDrop: 0),
    end: Pose(hipAngle: 0.2, kneeBend: 1.3, pelvisDrop: 0.4),
  ),
  'hip_hinge': const MovementPattern(
    cycleDuration: Duration(milliseconds: 1700),
    start: Pose(torsoTilt: 0, hipAngle: 0, kneeBend: 0.15),
    end: Pose(torsoTilt: 0.85, hipAngle: 0.35, kneeBend: 0.25),
  ),
  'calf_raise': const MovementPattern(
    start: Pose(pelvisDrop: 0),
    end: Pose(pelvisDrop: -0.18),
  ),
  'leg_extension': const MovementPattern(
    start: Pose(hipAngle: 1.55, kneeBend: 1.35),
    end: Pose(hipAngle: 1.55, kneeBend: 0.1),
  ),
  'leg_curl': const MovementPattern(
    orientation: RigOrientation.lying,
    start: Pose(hipAngle: 0, kneeBend: 0.1),
    end: Pose(hipAngle: 0, kneeBend: 1.5),
  ),
  'plank_core': const MovementPattern(
    orientation: RigOrientation.lying,
    cycleDuration: Duration(milliseconds: 2200),
    start: Pose(shoulderAngle: 1.5, elbowBend: 1.5, hipAngle: 0.05, chestExpand: 0),
    end: Pose(shoulderAngle: 1.5, elbowBend: 1.5, hipAngle: 0.05, chestExpand: 0.2),
  ),
  'situp_core': const MovementPattern(
    orientation: RigOrientation.lying,
    start: Pose(torsoTilt: 0, hipAngle: 0.65, kneeBend: 1.6),
    end: Pose(torsoTilt: 0.9, hipAngle: 0.65, kneeBend: 1.6),
  ),
  'cardio_generic': const MovementPattern(
    alternating: true,
    cycleDuration: Duration(milliseconds: 900),
    start: Pose(shoulderAngle: -0.6, hipAngle: -0.5, kneeBend: 0.3),
    end: Pose(shoulderAngle: 0.9, hipAngle: 0.7, kneeBend: 1.0),
  ),
  'generic': const MovementPattern(
    start: Pose(shoulderAngle: 0.15, hipAngle: 0),
    end: Pose(shoulderAngle: 0.55, hipAngle: 0.1),
  ),
};
