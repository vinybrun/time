import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The fixed set of life areas. Keys match the backend `CATEGORIES` list.
enum TimeCategory {
  work('work', Color(0xFF4F7CAC)),
  personalChores('personal_chores', Color(0xFFC58940)),
  personalProjects('personal_projects', Color(0xFF8E6BBF)),
  leisure('leisure', Color(0xFF45B69C)),
  relationships('relationships', Color(0xFFE3866B)),
  selfMaintenance('self_maintenance', Color(0xFF6FB1E0)),
  growth('growth', Color(0xFF7FA650)),
  sleep('sleep', Color(0xFFA8A29A)),
  uncategorized('uncategorized', Color(0xFFD8D2C6));

  const TimeCategory(this.key, this.color);

  final String key;
  final Color color;

  static TimeCategory fromKey(String key) {
    return TimeCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => TimeCategory.uncategorized,
    );
  }

  String label(AppL10n l) {
    switch (this) {
      case TimeCategory.work:
        return l.catWork;
      case TimeCategory.personalChores:
        return l.catPersonalChores;
      case TimeCategory.personalProjects:
        return l.catPersonalProjects;
      case TimeCategory.leisure:
        return l.catLeisure;
      case TimeCategory.relationships:
        return l.catRelationships;
      case TimeCategory.selfMaintenance:
        return l.catSelfMaintenance;
      case TimeCategory.growth:
        return l.catGrowth;
      case TimeCategory.sleep:
        return l.catSleep;
      case TimeCategory.uncategorized:
        return l.catUncategorized;
    }
  }

  /// Readable text colour for a chip filled with [color].
  Color get onColor {
    return color.computeLuminance() > 0.6 ? const Color(0xFF3A372F) : Colors.white;
  }
}
