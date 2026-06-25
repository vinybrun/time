import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The nine built-in life areas (key -> default colour). Users may rename,
/// recolor, disable, or add to these; entries reference a category by [key].
const Map<String, int> kNativeColors = {
  'work': 0xFF4F7CAC,
  'personal_chores': 0xFFC58940,
  'personal_projects': 0xFF8E6BBF,
  'leisure': 0xFF45B69C,
  'relationships': 0xFFE3866B,
  'self_maintenance': 0xFF6FB1E0,
  'growth': 0xFF7FA650,
  'sleep': 0xFFA8A29A,
  'uncategorized': 0xFFD8D2C6,
};

/// The conceptual default focus a day starts with at 00:00.
const String kDefaultCategoryKey = 'sleep';

String localizedNativeLabel(String key, AppL10n l) {
  switch (key) {
    case 'work':
      return l.catWork;
    case 'personal_chores':
      return l.catPersonalChores;
    case 'personal_projects':
      return l.catPersonalProjects;
    case 'leisure':
      return l.catLeisure;
    case 'relationships':
      return l.catRelationships;
    case 'self_maintenance':
      return l.catSelfMaintenance;
    case 'growth':
      return l.catGrowth;
    case 'sleep':
      return l.catSleep;
    case 'uncategorized':
      return l.catUncategorized;
    default:
      return key;
  }
}

/// A category definition. For native categories an empty [label] means "use the
/// localized default" (so built-ins stay translated unless the user renames).
class CategoryDef {
  CategoryDef({
    required this.key,
    this.label = '',
    required this.color,
    this.native = false,
    this.enabled = true,
    this.order = 0,
  });

  final String key;
  final String label;
  final Color color;
  final bool native;
  final bool enabled;
  final int order;

  String displayLabel(AppL10n l) {
    if (label.isNotEmpty) return label;
    if (native) return localizedNativeLabel(key, l);
    return key;
  }

  Color get onColor =>
      color.computeLuminance() > 0.6 ? const Color(0xFF3A372F) : Colors.white;

  CategoryDef copyWith({
    String? label,
    Color? color,
    bool? enabled,
    int? order,
  }) =>
      CategoryDef(
        key: key,
        label: label ?? this.label,
        color: color ?? this.color,
        native: native,
        enabled: enabled ?? this.enabled,
        order: order ?? this.order,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'color': color.toARGB32(),
        'native': native,
        'enabled': enabled,
        'order': order,
      };

  factory CategoryDef.fromJson(Map<String, dynamic> j) => CategoryDef(
        key: j['key'] as String,
        label: (j['label'] ?? '') as String,
        color: Color((j['color'] as num).toInt()),
        native: (j['native'] ?? false) as bool,
        enabled: (j['enabled'] ?? true) as bool,
        order: (j['order'] ?? 0) as int,
      );
}

/// The default set: the nine built-ins in a sensible order, all enabled.
List<CategoryDef> defaultCategories() {
  final keys = kNativeColors.keys.toList();
  return [
    for (var i = 0; i < keys.length; i++)
      CategoryDef(
        key: keys[i],
        color: Color(kNativeColors[keys[i]]!),
        native: true,
        enabled: true,
        order: i,
      ),
  ];
}

/// Fallback def for an entry whose category was deleted/unknown.
CategoryDef unknownCategory(String key) => CategoryDef(
      key: key,
      label: key,
      color: const Color(0xFFD8D2C6),
      native: false,
      enabled: false,
    );
