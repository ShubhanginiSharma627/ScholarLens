class User {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final AuthProvider provider;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;
  final UserProfile? profile;
  final UserStats? stats;
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isEmailVerified,
    this.profile,
    this.stats,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImageUrl: json['picture'] as String? ?? json['profileImageUrl'] as String?,
      provider: AuthProvider.values.firstWhere(
        (e) => e.name == (json['authProvider'] as String? ?? json['provider'] as String? ?? 'email'),
        orElse: () => AuthProvider.email,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String)
          : json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.parse(json['createdAt'] as String),
      isEmailVerified: json['emailVerified'] as bool? ?? json['isEmailVerified'] as bool? ?? json['isActive'] as bool? ?? false,
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'provider': provider.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'profile': profile?.toJson(),
      'stats': stats?.toJson(),
    };
  }
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    UserProfile? profile,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.profileImageUrl == profileImageUrl &&
        other.provider == provider &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.isEmailVerified == isEmailVerified &&
        other.profile == profile &&
        other.stats == stats;
  }
  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      profileImageUrl,
      provider,
      createdAt,
      lastLoginAt,
      isEmailVerified,
      profile,
      stats,
    );
  }
  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, provider: $provider)';
  }
}
enum AuthProvider {
  email,
  google,
}
class UserProfile {
  final String bio;
  final String avatar;
  final String learningStyle;
  final String preferredLanguage;
  const UserProfile({
    required this.bio,
    required this.avatar,
    required this.learningStyle,
    required this.preferredLanguage,
  });
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      learningStyle: json['learningStyle'] as String? ?? 'visual',
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'avatar': avatar,
      'learningStyle': learningStyle,
      'preferredLanguage': preferredLanguage,
    };
  }
  UserProfile copyWith({
    String? bio,
    String? avatar,
    String? learningStyle,
    String? preferredLanguage,
  }) {
    return UserProfile(
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      learningStyle: learningStyle ?? this.learningStyle,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.bio == bio &&
        other.avatar == avatar &&
        other.learningStyle == learningStyle &&
        other.preferredLanguage == preferredLanguage;
  }
  @override
  int get hashCode {
    return Object.hash(bio, avatar, learningStyle, preferredLanguage);
  }
}
class UserStats {
  final int totalMinutesLearned;
  final int currentStreak;
  final int longestStreak;
  final int quizzesCompleted;
  final double averageScore;
  const UserStats({
    required this.totalMinutesLearned,
    required this.currentStreak,
    required this.longestStreak,
    required this.quizzesCompleted,
    required this.averageScore,
  });
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalMinutesLearned: json['totalMinutesLearned'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      quizzesCompleted: json['quizzesCompleted'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'totalMinutesLearned': totalMinutesLearned,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'quizzesCompleted': quizzesCompleted,
      'averageScore': averageScore,
    };
  }
  UserStats copyWith({
    int? totalMinutesLearned,
    int? currentStreak,
    int? longestStreak,
    int? quizzesCompleted,
    double? averageScore,
  }) {
    return UserStats(
      totalMinutesLearned: totalMinutesLearned ?? this.totalMinutesLearned,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      averageScore: averageScore ?? this.averageScore,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStats &&
        other.totalMinutesLearned == totalMinutesLearned &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.quizzesCompleted == quizzesCompleted &&
        other.averageScore == averageScore;
  }
  @override
  int get hashCode {
    return Object.hash(
      totalMinutesLearned,
      currentStreak,
      longestStreak,
      quizzesCompleted,
      averageScore,
    );
  }
}