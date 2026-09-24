import '../../domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final bool isBiometricsAvailable;
  final bool hasSeenOnboarding;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isBiometricsAvailable = false,
    this.hasSeenOnboarding = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool clearUser = false,
    bool? isBiometricsAvailable,
    bool? hasSeenOnboarding,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isBiometricsAvailable: isBiometricsAvailable ?? this.isBiometricsAvailable,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      errorMessage: errorMessage,
    );
  }
}
