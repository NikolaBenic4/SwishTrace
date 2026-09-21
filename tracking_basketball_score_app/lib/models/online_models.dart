class ShotLabAccount {
  const ShotLabAccount({
    required this.userId,
    required this.email,
    required this.idToken,
    required this.refreshToken,
  });

  factory ShotLabAccount.fromJson(Map<String, Object?> json) {
    return ShotLabAccount(
      userId: json['userId']! as String,
      email: json['email']! as String,
      idToken: json['idToken']! as String,
      refreshToken: json['refreshToken']! as String,
    );
  }

  final String userId;
  final String email;
  final String idToken;
  final String refreshToken;

  Map<String, Object?> toJson() => {
    'userId': userId,
    'email': email,
    'idToken': idToken,
    'refreshToken': refreshToken,
  };
}

class FriendProfile {
  const FriendProfile({
    required this.userId,
    required this.displayName,
    required this.points,
  });

  factory FriendProfile.fromJson(Map<String, Object?> json) {
    return FriendProfile(
      userId: json['userId']! as String,
      displayName: json['displayName']! as String,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  final String userId;
  final String displayName;
  final int points;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.points,
  });

  factory LeaderboardEntry.fromJson(Map<String, Object?> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['userId']! as String,
      displayName: json['displayName']! as String,
      points: (json['points'] as num).toInt(),
    );
  }

  final int rank;
  final String userId;
  final String displayName;
  final int points;
}
