class UserProfile {
  String name;
  String email;
  String phone;
  String role;
  DateTime memberSince;
  bool isPremium;
  int currentStreak;
  int longestStreak;
  int totalTasksCompletedAllTime;
  int totalFocusSecondsAllTime;

  UserProfile({
    this.name = 'Student',
    this.email = '',
    this.phone = '',
    this.role = 'Student',
    DateTime? memberSince,
    this.isPremium = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalTasksCompletedAllTime = 0,
    this.totalFocusSecondsAllTime = 0,
  }) : memberSince = memberSince ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'memberSince': memberSince.toIso8601String(),
        'isPremium': isPremium,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalTasksCompletedAllTime': totalTasksCompletedAllTime,
        'totalFocusSecondsAllTime': totalFocusSecondsAllTime,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final storedMemberSince = json['memberSince'];
    DateTime? memberSince;
    if (storedMemberSince is String) {
      memberSince = DateTime.tryParse(storedMemberSince);
    }

    String textValue(String key, String fallback) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : fallback;
    }

    int numberValue(String key) {
      final value = json[key];
      return value is num ? value.toInt() : 0;
    }

    return UserProfile(
      name: textValue('name', 'Student'),
      email: textValue('email', ''),
      phone: textValue('phone', ''),
      role: textValue('role', 'Student'),
      memberSince: memberSince ?? DateTime.now(),
      isPremium: json['isPremium'] is bool ? json['isPremium'] as bool : false,
      currentStreak: numberValue('currentStreak'),
      longestStreak: numberValue('longestStreak'),
      totalTasksCompletedAllTime: numberValue('totalTasksCompletedAllTime'),
      totalFocusSecondsAllTime: numberValue('totalFocusSecondsAllTime'),
    );
  }
}
