import 'dart:convert';

class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map) {
      throw const FormatException('Missing authenticated user');
    }

    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Missing authentication token');
    }

    return AuthSession(
      token: token,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }

  factory AuthSession.fromToken(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw const FormatException('Invalid authentication token');
    }

    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid authentication token payload');
    }

    return AuthSession(token: token, user: AuthUser.fromJson(decoded));
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
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
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? 'User',
      profileUrl:
          json['profileURL']?.toString() ?? json['profileUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'username': username,
      'profileURL': profileUrl,
    };
  }
}
