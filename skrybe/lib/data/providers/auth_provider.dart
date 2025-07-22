// lib/data/providers/auth_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/models/user_model.dart';
import 'package:skrybe/data/repositories/user_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(firebaseAuthProvider)
      .authStateChanges()
      .map((user) => user != null);
});

final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
});

final userModelProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = ref.watch(currentUserProvider).valueOrNull;
  if (firebaseUser == null) return null;

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUserById(firebaseUser.uid);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  AuthNotifier({
    required FirebaseAuth auth,
    required UserRepository userRepository,
  })  : _auth = auth,
        _userRepository = userRepository,
        super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      // Create a user document in Firestore
      final now = DateTime.now();
      final userModel = UserModel(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName ?? '',
        photoUrl: userCredential.user?.photoURL,
        createdAt: now,
        updatedAt: now,
        preferences: {
          'theme': 'system',
          'notifications': true,
        },
      );

      await _userRepository.createUser(userModel);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Future<void> resetPassword(String email) async {
  //   state = const AsyncValue.loading();

  //   try {
  //     await _auth.sendPasswordResetEmail(email: email);
  //     state = const AsyncValue.data(null);
  //   } catch (error, stackTrace) {
  //     state = AsyncValue.error(error, stackTrace);
  //     rethrow;
  //   }
  // }
  Future<void> resetPassword(String email) async {
    try {
      // First, get the user's display name by email
      String? userName;

      // Try to get the user's name from existing users
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        // User exists, try to get their display name
        // Note: This is a workaround since Firebase doesn't directly expose user lookup by email
        userName = await _getUserDisplayName(email);
      }

      // Send password reset email with action code settings
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          // This URL should match your Firebase project settings
          url:
              'https://skrybe-1cb67.firebaseapp.com/__/auth/action?mode=action&oobCode=code', // Replace with your actual URL
          handleCodeInApp: false,
          // Pass custom parameters that can be used in email template
          dynamicLinkDomain: null, // Set if using dynamic links
        ),
      );

      print('Password reset email sent successfully to $email');
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email address.');
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        default:
          throw Exception('Failed to send reset email: ${e.message}');
      }
    } catch (e) {
      print('General Error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Helper method to get user's display name (you'll need to implement this based on your user storage)
  Future<String?> _getUserDisplayName(String email) async {
    // Option 1 : If user names stored on Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        return userDoc.docs.first.data()['displayName'] as String?;
      }
    } catch (e) {
      print('Error fetching user display name: $e');
    }

    // Option 2: If you don't have user storage, return null
    // Firebase will use a default greeting
    return null;
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    required String email,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not found');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update Firestore user document
      await _userRepository.updateUser(
        user.uid,
        {
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          'updatedAt': DateTime.now(),
        },
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return AuthNotifier(
    auth: auth,
    userRepository: userRepository,
  );
});
