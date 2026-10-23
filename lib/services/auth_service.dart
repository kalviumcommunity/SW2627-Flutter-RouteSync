import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserModel.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<UserModel> requireCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      throw const AuthServiceException('No authenticated user is available.');
    }

    final profile = await getCurrentUserProfile();
    if (profile == null) {
      throw const AuthServiceException(
        'The authenticated user profile is missing.',
      );
    }
    if (profile.id != user.uid) {
      throw const AuthServiceException(
        'The user profile does not match the authenticated UID.',
      );
    }
    if (!profile.active) {
      throw const AuthServiceException('This account is inactive.');
    }
    if (!UserRoles.values.contains(profile.role)) {
      throw const AuthServiceException(
        'The user profile has an unsupported role.',
      );
    }
    return profile;
  }

  Stream<List<UserModel>> watchActiveExecutives() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRoles.executive)
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => UserModel.fromMap(document.id, document.data()),
              )
              .toList(growable: false),
        );
  }

  Stream<UserModel?> currentUserProfileChanges() {
    return authStateChanges.asyncMap((_) => getCurrentUserProfile());
  }
}
