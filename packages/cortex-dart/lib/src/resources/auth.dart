/// Auth resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to authentication endpoints.
class AuthResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates an [AuthResource].
  AuthResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Logs in with email and password.
  ///
  /// Returns an [AuthTokenResponse] containing the token and user info.
  Future<AuthTokenResponse> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) {
      throw const CortexValidationException(
        message: 'Email must not be empty.',
        parameter: 'email',
      );
    }
    if (password.isEmpty) {
      throw const CortexValidationException(
        message: 'Password must not be empty.',
        parameter: 'password',
      );
    }

    final json = await _client.post(
      '$_baseUrl/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthTokenResponse.fromJson(json);
  }

  /// Signs up a new user.
  ///
  /// Returns an [AuthTokenResponse] containing the token and user info.
  Future<AuthTokenResponse> signup({
    required String email,
    required String password,
    String? name,
  }) async {
    if (email.isEmpty) {
      throw const CortexValidationException(
        message: 'Email must not be empty.',
        parameter: 'email',
      );
    }
    if (password.isEmpty) {
      throw const CortexValidationException(
        message: 'Password must not be empty.',
        parameter: 'password',
      );
    }

    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (name != null) body['name'] = name;

    final json = await _client.post('$_baseUrl/auth/signup', body: body);
    return AuthTokenResponse.fromJson(json);
  }

  /// Gets the current user's profile.
  Future<AuthUser> me() async {
    final json = await _client.get('$_baseUrl/auth/me');
    return AuthUser.fromJson(json);
  }

  /// Updates the current user's profile.
  ///
  /// [name] is the new display name (optional).
  /// [email] is the new email (optional).
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;

    final json = await _client.patch('$_baseUrl/auth/me', body: body);
    return AuthUser.fromJson(json);
  }

  /// Changes the current user's password.
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty) {
      throw const CortexValidationException(
        message: 'Current password must not be empty.',
        parameter: 'currentPassword',
      );
    }
    if (newPassword.isEmpty) {
      throw const CortexValidationException(
        message: 'New password must not be empty.',
        parameter: 'newPassword',
      );
    }

    return _client.post(
      '$_baseUrl/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
