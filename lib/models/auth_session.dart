class AuthSession {
  final String token;
  final int userId;
  final String username;
  final String email;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'username': username,
    'email': email,
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] ?? '').toString(),
      userId: json['userId'] as int,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}
