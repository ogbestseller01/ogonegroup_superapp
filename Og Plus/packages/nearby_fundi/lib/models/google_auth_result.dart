import 'user.dart';

class GoogleAuthResult {
  final User user;
  final String token;
  final bool isNewUser;

  GoogleAuthResult({
    required this.user,
    required this.token,
    required this.isNewUser,
  });

  factory GoogleAuthResult.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw StateError('Server response did not include a token.');
    }
    final userMap = Map<String, dynamic>.from(json['user'] as Map);
    return GoogleAuthResult(
      user: User.fromJson(userMap, token),
      token: token,
      isNewUser: json['is_new_user'] == true,
    );
  }
}