import 'category.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
    required this.timezone,
    required this.language,
    this.categories,
  });

  final int id;
  final String email;
  final String name;
  final bool emailVerified;
  final String timezone;
  final String language;
  final List<CategoryDef>? categories;

  AppUser copyWith({
    String? name,
    bool? emailVerified,
    String? timezone,
    String? language,
    List<CategoryDef>? categories,
  }) =>
      AppUser(
        id: id,
        email: email,
        name: name ?? this.name,
        emailVerified: emailVerified ?? this.emailVerified,
        timezone: timezone ?? this.timezone,
        language: language ?? this.language,
        categories: categories ?? this.categories,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'email_verified': emailVerified,
        'timezone': timezone,
        'language': language,
        if (categories != null)
          'categories': categories!.map((c) => c.toJson()).toList(),
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String,
        name: (j['name'] ?? '') as String,
        emailVerified: (j['email_verified'] ?? false) as bool,
        timezone: (j['timezone'] ?? 'UTC') as String,
        language: (j['language'] ?? 'en') as String,
        categories: (j['categories'] as List?)
            ?.map((e) => CategoryDef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
