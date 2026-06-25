class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
    required this.timezone,
    required this.language,
  });

  final int id;
  final String email;
  final String name;
  final bool emailVerified;
  final String timezone;
  final String language;

  AppUser copyWith({
    String? name,
    bool? emailVerified,
    String? timezone,
    String? language,
  }) =>
      AppUser(
        id: id,
        email: email,
        name: name ?? this.name,
        emailVerified: emailVerified ?? this.emailVerified,
        timezone: timezone ?? this.timezone,
        language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'email_verified': emailVerified,
        'timezone': timezone,
        'language': language,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String,
        name: (j['name'] ?? '') as String,
        emailVerified: (j['email_verified'] ?? false) as bool,
        timezone: (j['timezone'] ?? 'UTC') as String,
        language: (j['language'] ?? 'en') as String,
      );
}
