// lib/data/providers/auth_provider.dart
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
      throw error;
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
      throw error;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      throw error;
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      throw error;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
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
      throw error;
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

// // lib/data/providers/auth_provider.dart
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:skrybe/data/models/user_model.dart';
// import 'package:skrybe/data/repositories/auth_repository.dart';
// import 'package:skrybe/data/repositories/user_repository.dart';

// // Define userRepositoryProvider since it's referenced but not defined
// final userRepositoryProvider = Provider<UserRepository>((ref) {
//   return UserRepository();
// });

// final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
//   return FirebaseAuth.instance;
// });

// final authStateProvider = StreamProvider<bool>((ref) {
//   return ref
//       .watch(firebaseAuthProvider)
//       .authStateChanges()
//       .map((user) => user != null);
// });

// final currentUserProvider = StreamProvider<User?>((ref) {
//   return ref.watch(firebaseAuthProvider).authStateChanges();
// });

// final userModelProvider = FutureProvider<UserModel?>((ref) async {
//   final firebaseUser = ref.watch(currentUserProvider).valueOrNull;
//   if (firebaseUser == null) return null;

//   final userRepository = ref.watch(userRepositoryProvider);
//   return userRepository.getUserById(firebaseUser.uid);
// });

// class AuthNotifier extends StateNotifier<AsyncValue<void>> {
//   final FirebaseAuth _auth;
//   final UserRepository _userRepository;

//   AuthNotifier({
//     required FirebaseAuth auth,
//     required UserRepository userRepository,
//   })  : _auth = auth,
//         _userRepository = userRepository,
//         super(const AsyncValue.data(null));

//   Future<void> signUp({
//     required String email,
//     required String password,
//     String? displayName,
//   }) async {
//     state = const AsyncValue.loading();

//     try {
//       // Create user in firebase auth
//       final userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // Update display name if provided
//       if (displayName != null && userCredential.user != null) {
//         await userCredential.user!.updateDisplayName(displayName);
//       }

//       // Create user document in Firestore
//       final now = DateTime.now();
//       final userModel = UserModel(
//         id: userCredential.user!.uid,
//         email: email,
//         displayName: displayName ?? '',
//         photoURL: userCredential.user?.photoURL,
//         createdAt: now,
//         updatedAt: now,
//         preferences: {
//           'theme': 'system',
//           'notifications': true,
//         },
//       );

//       await _userRepository
//           .saveUser(userModel); // Changed from createUser to saveUser
//       state = const AsyncValue.data(null);
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e, stackTrace);
//       rethrow; // Changed from throw e to rethrow
//     }
//   }

//   Future<void> signIn({
//     required String email,
//     required String password,
//   }) async {
//     state = const AsyncValue.loading();

//     try {
//       await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }

//   Future<void> signOut() async {
//     state = const AsyncValue.loading();

//     try {
//       await _auth.signOut();
//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }

//   Future<void> resetPassword(String email) async {
//     state = const AsyncValue.loading();

//     try {
//       await _auth.sendPasswordResetEmail(email: email);
//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }

//   Future<void> updateProfile({
//     String? displayName,
//     String? photoURL,
//   }) async {
//     state = const AsyncValue.loading();

//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw 'User not authenticated';
//       }

//       // Update Firebase Auth profile
//       if (displayName != null) {
//         await user.updateDisplayName(displayName);
//       }

//       if (photoURL != null) {
//         await user.updatePhotoURL(photoURL);
//       }

//       // Update Firestore user document
//       await _userRepository.saveUserData(user.uid, {
//         // Changed from updateUser to saveUserData
//         if (displayName != null) 'displayName': displayName,
//         if (photoURL != null) 'photoURL': photoURL,
//         'updatedAt': DateTime.now(),
//       });

//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }

//   Future<void> updateEmail(String newEmail) async {
//     state = const AsyncValue.loading();

//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw 'User not authenticated';
//       }

//       // Using verifyBeforeUpdateEmail instead of deprecated updateEmail
//       await user.verifyBeforeUpdateEmail(newEmail);

//       // Update Firestore user document
//       await _userRepository.saveUserData(user.uid, {
//         // Changed from updateUser to saveUserData
//         'email': newEmail,
//         'updatedAt': DateTime.now(),
//       });

//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }

//   Future<void> updatePassword(String newPassword) async {
//     state = const AsyncValue.loading();

//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw 'User not authenticated';
//       }
//       await user.updatePassword(newPassword);
//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }

//   Future<void> deleteAccount() async {
//     state = const AsyncValue.loading();

//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw 'User not authenticated';
//       }

//       // Delete Firestore user document first
//       await _userRepository
//           .removeUser(user.uid); // Changed from deleteUser to removeUser

//       // Then delete Firebase Auth user
//       await user.delete();

//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }

//   Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
//     state = const AsyncValue.loading();

//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw 'User not authenticated';
//       }

//       await _userRepository.savePreferences(user.uid,
//           preferences); // Changed from updateUserPreferences to savePreferences
//       state = const AsyncValue.data(null);
//     } catch (error, stackTrace) {
//       state = AsyncValue.error(error, stackTrace);
//       rethrow; // Changed from throw error to rethrow
//     }
//   }
// }

// final authNotifierProvider =
//     StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
//   final auth = ref.watch(firebaseAuthProvider);
//   final userRepository = ref.watch(userRepositoryProvider);

//   return AuthNotifier(
//     auth: auth,
//     userRepository: userRepository,
//   );
// });

// // If you're using AuthNotifier, consider removing this section
// final authControllerProvider =
//     StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
//   final firebaseAuth = ref.watch(firebaseAuthProvider);
//   final authRepository = AuthRepository(firebaseAuth);
//   return AuthController(authRepository: authRepository);
// });

// class AuthController extends StateNotifier<AsyncValue<void>> {
//   final AuthRepository _authRepository;

//   AuthController({
//     required AuthRepository authRepository,
//   })  : _authRepository = authRepository,
//         super(const AsyncValue.data(null));

//   Future<void> signUp({
//     required String email,
//     required String password,
//     required String displayName,
//   }) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() => _authRepository.signUp(
//           email: email,
//           password: password,
//           displayName: displayName,
//         ));
//   }
// }


// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:skrybe/data/models/user_model.dart';
// // import 'package:skrybe/data/repositories/auth_repository.dart';
// // import 'package:skrybe/data/repositories/user_repository.dart';

// // final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
// //   return FirebaseAuth.instance;
// // });

// // final authStateProvider = StreamProvider<bool>((ref) {
// //   return ref
// //       .watch(firebaseAuthProvider)
// //       .authStateChanges()
// //       .map((user) => user != null);
// // });

// // final currentUserProvider = StreamProvider<User?>((ref) {
// //   return ref.watch(firebaseAuthProvider).authStateChanges();
// // });

// // final userModelProvider = FutureProvider<UserModel?>((ref) async {
// //   final firebaseUser = ref.watch(currentUserProvider).valueOrNull;
// //   if (firebaseUser == null) return null;

// //   final userRepository = ref.watch(userRepositoryProvider);
// //   return userRepository.getUserById(firebaseUser.uid);
// // });

// // class AuthNotifier extends StateNotifier<AsyncValue<void>> {
// //   final FirebaseAuth _auth;
// //   final UserRepository _userRepository;

// //   AuthNotifier({
// //     required FirebaseAuth auth,
// //     required UserRepository userRepository,
// //   })  : _auth = auth,
// //         _userRepository = userRepository,
// //         super(const AsyncValue.data(null));

// //   Future<void> signUp({
// //     required String email,
// //     required String password,
// //     String? displayName,
// //   }) async {
// //     state = const AsyncValue.loading();

// //     try {
// //       // Create user in firebase auth
// //       final userCredential = await _auth.createUserWithEmailAndPassword(
// //         email: email,
// //         password: password,
// //       );

// //       // Update display name if provided
// //       if (displayName != null && userCredential.user != null) {
// //         await userCredential.user!.updateDisplayName(displayName);
// //       }

// //       // Create user document in Firestore
// //       final now = DateTime.now();
// //       final userModel = UserModel(
// //         id: userCredential.user!.uid,
// //         email: email,
// //         displayName: displayName ?? '',
// //         photoURL: userCredential.user?.photoURL,
// //         createdAt: now,
// //         updatedAt: now,
// //         preferences: {
// //           'theme': 'system',
// //           'notifications': true,
// //         },
// //       );

// //       await _userRepository.createUser(userModel);
// //       state = const AsyncValue.data(null);
// //     } catch (e, stackTrace) {
// //       state = AsyncValue.error(e, stackTrace);
// //       throw e;
// //     }
// //   }

// //   Future<void> signIn({
// //     required String email,
// //     required String password,
// //   }) async {
// //     state = const AsyncValue.loading();

// //     try {
// //       await _auth.signInWithEmailAndPassword(
// //         email: email,
// //         password: password,
// //       );
// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }

// //   Future<void> signOut() async {
// //     state = const AsyncValue.loading();

// //     try {
// //       await _auth.signOut();
// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }

// //   Future<void> resetPassword(String email) async {
// //     state = const AsyncValue.loading();

// //     try {
// //       await _auth.sendPasswordResetEmail(email: email);
// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }

// //   Future<void> updateProfile({
// //     String? displayName,
// //     String? photoURL,
// //   }) async {
// //     state = const AsyncValue.loading();

// //     try {
// //       final user = _auth.currentUser;
// //       if (user == null) {
// //         throw 'User not authenticated';
// //       }

// //       // Update Firebase Auth profile
// //       if (displayName != null) {
// //         await user.updateDisplayName(displayName);
// //       }

// //       if (photoURL != null) {
// //         await user.updatePhotoURL(photoURL);
// //       }

// //       // Update Firestore user document
// //       await _userRepository.updateUser(user.uid, {
// //         if (displayName != null) 'displayName': displayName,
// //         if (photoURL != null) 'photoURL': photoURL,
// //         'updatedAt': DateTime.now(),
// //       });

// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }

// //   Future<void> updateEmail(String newEmail) async {
// //     state = const AsyncValue.loading();

// //     try {
// //       final user = _auth.currentUser;
// //       if (user == null) {
// //         throw 'User not authenticated';
// //       }
// //       await user.updateEmail(newEmail);

// //       // Update Firestore user document
// //       await _userRepository.updateUser(user.uid, {
// //         'email': newEmail,
// //         'updatedAt': DateTime.now(),
// //       });

// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }

// //   Future<void> updatePassword(String newPassword) async {
// //     state = const AsyncValue.loading();

// //     try {
// //       final user = _auth.currentUser;
// //       if (user == null) {
// //         throw 'User not authenticated';
// //       }
// //       await user.updatePassword(newPassword);
// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }

// //   Future<void> deleteAccount() async {
// //     state = const AsyncValue.loading();

// //     try {
// //       final user = _auth.currentUser;
// //       if (user == null) {
// //         throw 'User not authenticated';
// //       }

// //       // Delete Firestore user document first
// //       await _userRepository.deleteUser(user.uid);

// //       // Then delete Firebase Auth user
// //       await user.delete();

// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }

// //   Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
// //     state = const AsyncValue.loading();

// //     try {
// //       final user = _auth.currentUser;
// //       if (user == null) {
// //         throw 'User not authenticated';
// //       }

// //       await _userRepository.updateUserPreferences(user.uid, preferences);
// //       state = const AsyncValue.data(null);
// //     } catch (error, stackTrace) {
// //       state = AsyncValue.error(error, stackTrace);
// //       throw error;
// //     }
// //   }
// // }

// // final authNotifierProvider =
// //     StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
// //   final auth = ref.watch(firebaseAuthProvider);
// //   final userRepository = ref.watch(userRepositoryProvider);

// //   return AuthNotifier(
// //     auth: auth,
// //     userRepository: userRepository,
// //   );
// // });


// // // This can be removed if you're using AuthNotifier (recommended)
// // // Keeping it here only for reference
// // // final authControllerProvider =
// // //     StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
// // //   final firebaseAuth = ref.watch(firebaseAuthProvider);
// // //   final authRepository = AuthRepository(firebaseAuth);
// // //   return AuthController(authRepository: authRepository);
// // // });


// // // class AuthController extends StateNotifier<AsyncValue<void>> {
// // //   final AuthRepository _authRepository;


// // //   AuthController({
// // //     required AuthRepository authRepository,
// // //   })  : _authRepository = authRepository,
// // //         super(const AsyncValue.data(null));


// // //   Future<void> signUp({
// // //     required String email,
// // //     required String password,
// // //     required String displayName,
// // //   }) async {
// // //     state = const AsyncValue.loading();
// // //     state = await AsyncValue.guard(() => _authRepository.signUp(
// // //           email: email,
// // //           password: password,
// // //           displayName: displayName,
// // //         ));
// // //   }
// // // }


// // // // lib/data/providers/auth_provider.dart

// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // import 'package:skrybe/data/models/user_model.dart';
// // // import 'package:skrybe/data/repositories/auth_repository.dart';
// // // import 'package:skrybe/data/repositories/user_repository.dart';

// // // final FirebaseAuthProvider = Provider<FirebaseAuth>((ref) {
// // //   return FirebaseAuth.instance;
// // // });

// // // //
// // // final authStateProvider = StreamProvider<bool>((ref) {
// // //   return ref
// // //       .watch(FirebaseAuthProvider)
// // //       .authStateChanges()
// // //       .map((user) => user != null);
// // // });

// // // final currentUserProvider = StreamProvider<User?>((ref) {
// // //   return ref.watch(FirebaseAuthProvider).authStateChanges();
// // // });

// // // final userModelProvider = FutureProvider<UserModel?>((ref) async {
// // //   final firebaseUser = ref.watch(currentUserProvider).valueOrNull;
// // //   if (firebaseUser == null) return null;

// // //   final userRepository = ref.watch(userRepositoryProvider);
// // //   return userRepository.getUserById(firebaseUser.uid);
// // // });

// // // class AuthNotifier extends StateNotifier<AsyncValue<void>> {
// // //   final FirebaseAuth _auth;
// // //   final UserRepository _userRepository;

// // //   AuthNotifier({
// // //     required FirebaseAuth auth,
// // //     required UserRepository userRepository,
// // //   })  : _auth = auth,
// // //         _userRepository = userRepository,
// // //         super(const AsyncValue.data(null));

// // //   Future<void> signUp({
// // //     required String email,
// // //     required String password,
// // //     String? displayName,
// // //   }) async {
// // //     state = const AsyncValue.loading();

// // //     try {
// // //       // Create user in firebase auth
// // //       final userCredential = await _auth.createUserWithEmailAndPassword(
// // //         email: email,
// // //         password: password,
// // //       );

// // //       // Update display name if provided
// // //       if (displayName != null && userCredential.user != null) {
// // //         await userCredential.user?.updateDisplayName(displayName);
// // //         await userCredential.user?.updateProfile(
// // //           displayName: displayName,
// // //         );
// // //       }

// // //       // Create user document in Firestore      await userCredential.user?.updateDisplayName(displayName);
// // //       final now = DateTime.now();
// // //       final userModel = UserModel(
// // //           id: userCredential.user!.uid,
// // //           email: email,
// // //           displayName: displayName ?? '',
// // //           photoURL: userCredential.user?.photoURL,
// // //           // photoURL: null,
// // //           createdAt: now,
// // //           updatedAt: now,
// // //           preferences: {
// // //             'theme': 'system',
// // //             'notifications': true,
// // //           });

// // //       await _userRepository.createUser(userModel);
// // //       state = const AsyncValue.data(null);
// // //     } on FirebaseAuthException catch (e) {
// // //       state = await AsyncValue.guard(() => _auth.signInWithEmailAndPassword(
// // //             email: email,
// // //             password: password,
// // //           ));
// // //     } catch (e) {
// // //       state = AsyncValue.error(e, StackTrace.current);
// // //     }

// // //     Future<void> signIn(
// // //         {required String email, required String password}) async {
// // //       state = const AsyncValue.loading();

// // //       try {
// // //         await _auth.signInWithEmailAndPassword(
// // //           email: email,
// // //           password: password,
// // //         );
// // //         state = const AsyncValue.data(null);
// // //       } catch (error, stackTrace) {
// // //         state = AsyncValue.error(error, stackTrace);
// // //         throw error;
// // //       }

// // //       Future<void> signOut() async {
// // //         state = const AsyncValue.loading();

// // //         try {
// // //           await _auth.signOut();
// // //           state = const AsyncValue.data(null);
// // //         } catch (error, stackTrace) {
// // //           state = AsyncValue.error(error, stackTrace);
// // //           throw error;
// // //         }
// // //       }
// // //     }

// // //     Future<void> resetPassword(String email) async {
// // //       state = const AsyncValue.loading();

// // //       try {
// // //         await _auth.sendPasswordResetEmail(email: email);
// // //         state = const AsyncValue.data(null);
// // //       } catch (error, stackTrace) {
// // //         state = AsyncValue.error(error, stackTrace);
// // //         throw error;
// // //       }
// // //     }

// // //     Future<void> updateProfile({
// // //       String? displayName,
// // //       String? photoURL,
// // //     }) async {
// // //       state = const AsyncValue.loading();

// // //       try {
// // //         final user = _auth.currentUser;
// // //         if (user == null) {
// // //           throw 'User not authenticated';
// // //         }

// // //         // Update Firebase Auth profile
// // //         if (displayName != null) {
// // //           await user.updateDisplayName(displayName);
// // //         }

// // //         if (photoURL != null) {
// // //           await user.updatePhotoURL(photoURL);
// // //         }

// // //         // Update Firestore user document
// // //         await _userRepository.updateUser(user.uid, {
// // //           if (displayName != null) 'displayName': displayName,
// // //           if (photoURL != null) 'photoURL': photoURL,
// // //           'updatedAt': DateTime.now(),
// // //         });

// // //         state = const AsyncValue.data(null);
// // //       } catch (error, stackTrace) {
// // //         state = AsyncValue.error(error, stackTrace);
// // //         throw error;
// // //       }
// // //     }

// // //     Future<void> updateEmail(String newEmail) async {
// // //       state = const AsyncValue.loading();
// // //       state =
// // //           await AsyncValue.guard(() => _authRepository.updateEmail(newEmail));
// // //     }

// // //     Future<void> updatePassword(String newPassword) async {
// // //       state = const AsyncValue.loading();
// // //       state = await AsyncValue.guard(
// // //           () => _authRepository.updatePassword(newPassword));
// // //     }

// // //     Future<void> deleteAccount() async {
// // //       state = const AsyncValue.loading();
// // //       state = await AsyncValue.guard(() => _authRepository.deleteAccount());
// // //     }

// // //     Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
// // //       state = const AsyncValue.loading();
// // //       state = await AsyncValue.guard(
// // //           () => _userRepository.updateUserPreferences(preferences));
// // //     }

// // //     Future<void> deleteUserPreferences() async {
// // //       state = const AsyncValue.loading();
// // //       state =
// // //           await AsyncValue.guard(() => _userRepository.deleteUserPreferences());
// // //     }

// // //     final authNotifierProvider =
// // //         StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
// // //       final auth = ref.watch(FirebaseAuthProvider);
// // //       final userRepository = ref.watch(userRepositoryProvider);

// // //       return AuthNotifier(
// // //         auth: auth,
// // //         userRepository: userRepository,
// // //       );
// // //     });
// // //   }
// // // }

// // // // final authControllerProvider =
// // // //     StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
// // // //   final firebaseAuth = ref.watch(FirebaseAuthProvider);
// // // //   final authRepository = AuthRepository(firebaseAuth);
// // // //   return AuthController(authRepository: authRepository);
// // // // });

// // // // class AuthController extends StateNotifier<AsyncValue<void>> {
// // // //   final AuthRepository _authRepository;

// // // //   AuthController({
// // // //     required AuthRepository authRepository,
// // // //   })  : _authRepository = authRepository,
// // // //         super(const AsyncValue.data(null));

// // // //   Future<void> signUp({
// // // //     required String email,
// // // //     required String password,
// // // //     required String displayName,
// // // //   }) async {
// // // //     state = const AsyncValue.loading();
// // // //     state = await AsyncValue.guard(() => _authRepository.signUp(
// // // //           email: email,
// // // //           password: password,
// // // //           displayName: displayName,
// // // //         ));
// // // //   }
// // // // }
