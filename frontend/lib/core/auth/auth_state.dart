import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppAuthState {
  final bool isAuthenticated;

  const AppAuthState._(this.isAuthenticated);

  const AppAuthState.authenticated() : this._(true);

  const AppAuthState.unauthenticated() : this._(false);
}

final appAuthStateProvider = StateProvider<AppAuthState>((ref) {
  return const AppAuthState.unauthenticated();
});
