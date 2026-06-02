class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Missing authenticated user');
    }

    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Missing authentication token');
    }

    return AuthSession(token: token, user: AuthUser.fromJson(userJson));
  }
}

class AuthUser {
  final String id;
  final String email;
  final String username;
  final String? profileUrl;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    this.profileUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? 'User',
      profileUrl: json['profileURL']?.toString(),
    );
  }
}
