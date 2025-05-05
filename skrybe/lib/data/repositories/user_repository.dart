// lib/data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrybe/data/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Get a user by ID
  Future<UserModel?> getUserById(String userId) async {
    final docSnapshot = await _usersCollection.doc(userId).get();
    if (!docSnapshot.exists) return null;
    return UserModel.fromFirestore(docSnapshot);
  }

  // Create a new user
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.id).set(user.toFirestore());
  }

  // Update a user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _usersCollection.doc(userId).update(data);
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserRepository(firestore: firestore);
});

// // Added this class to avoid "undefined" errors
// import 'package:skrybe/data/models/user_model.dart';

// class UserRepository {
//   // User methods
//   Future<UserModel> getUserById(String uid) async {
//     // Implement this method to fetch user from Firestore
//     throw UnimplementedError("getUserById not implemented");
//   }

//   Future<void> saveUser(UserModel user) async {
//     // Implement this method to save a user to Firestore
//     throw UnimplementedError("saveUser not implemented");
//   }

//   Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
//     // Implement this method to update user fields
//     throw UnimplementedError("saveUserData not implemented");
//   }

//   Future<void> removeUser(String uid) async {
//     // Implement this method to delete a user from Firestore
//     throw UnimplementedError("removeUser not implemented");
//   }

//   Future<void> savePreferences(
//       String uid, Map<String, dynamic> preferences) async {
//     // Implement this method to update user preferences
//     throw UnimplementedError("savePreferences not implemented");
//   }
// }
