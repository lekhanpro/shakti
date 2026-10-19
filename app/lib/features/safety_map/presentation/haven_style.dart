import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../domain/entities/entities.dart';

/// Visual identity per haven category. Colour is always paired with a
/// distinct icon so category never depends on colour alone.
extension HavenStyle on HavenCategory {
  Color get color => switch (this) {
        HavenCategory.police => ShaktiColors.police,
        HavenCategory.hospital => ShaktiColors.hospital,
        HavenCategory.pharmacy => ShaktiColors.pharmacy,
        HavenCategory.shelter => ShaktiColors.shelter,
      };

  IconData get icon => switch (this) {
        HavenCategory.police => Icons.local_police_rounded,
        HavenCategory.hospital => Icons.local_hospital_rounded,
        HavenCategory.pharmacy => Icons.medication_rounded,
        HavenCategory.shelter => Icons.night_shelter_rounded,
      };

  String get filterLabel => switch (this) {
        HavenCategory.pharmacy => 'Pharmacy 24/7',
        _ => label,
      };
}
