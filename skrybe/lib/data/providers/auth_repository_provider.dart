// lib/data/providers/auth_repository_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/repositories/auth_repository.dart';

/// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

/// Provider for the Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Stream provider for Firebase Auth state changes
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Provider that returns true if user is authenticated, false otherwise
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authStateAsync = ref.watch(authStateChangesProvider);
  return authStateAsync.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
