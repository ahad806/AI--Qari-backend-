import 'package:al_qari/features/auth/data/models/user_model.dart';
import 'package:al_qari/features/auth/domain/entities/user_entity.dart';
import 'package:al_qari/features/auth/domain/failures/auth_failure.dart';
import 'package:al_qari/features/auth/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  static const _usersCollection = 'users';

  // ─── currentUser ────────────────────────────────────────────────────────────

  @override
  UserEntity? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? '',
      phoneNumber: user.phoneNumber ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ─── signIn ─────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      // Fallback – Firestore doc missing but account exists
      return UserModel(
        uid: uid,
        fullName: credential.user?.displayName ?? '',
        email: credential.user?.email ?? '',
        phoneNumber: '',
        createdAt: credential.user?.metadata.creationTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.networkError
          : AuthFailure.unknown;
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  // ─── signUp ─────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String gender,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user!.updateDisplayName(fullName.trim());

      final now = DateTime.now();
      final uid = credential.user!.uid;

      final userModel = UserModel(
        uid: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        gender: gender,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.networkError
          : AuthFailure.unknown;
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  // ─── updateProfile ───────────────────────────────────────────────────────────

  @override
  Future<UserEntity> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String gender,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw AuthFailure.unknown;

      await _auth.currentUser!.updateDisplayName(fullName.trim());

      final now = DateTime.now();
      await _firestore.collection(_usersCollection).doc(uid).update({
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'gender': gender,
        'updatedAt': Timestamp.fromDate(now),
      });

      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.networkError
          : AuthFailure.unknown;
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  // ─── signInWithGoogle ────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Trigger the Google sign-in flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw AuthFailure.unknown; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;
      final uid = firebaseUser.uid;

      // Check if Firestore doc already exists (returning user)
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      // First-time Google sign-in — create Firestore doc
      final now = DateTime.now();
      final userModel = UserModel(
        uid: uid,
        fullName: firebaseUser.displayName ?? googleUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
        gender: 'male', // default; user can update in profile
        createdAt: firebaseUser.metadata.creationTime ?? now,
        updatedAt: now,
      );
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userModel.toFirestore());
      return userModel;
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.networkError
          : AuthFailure.unknown;
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  // ─── sendPasswordResetEmail ──────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      throw e.code == 'unavailable'
          ? AuthFailure.networkError
          : AuthFailure.unknown;
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  // ─── signOut ─────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── authStateChanges ────────────────────────────────────────────────────────

  @override
  Stream<UserEntity?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final doc = await _firestore
            .collection(_usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) return UserModel.fromFirestore(doc);
      } catch (_) {
        // Return minimal entity if Firestore is unreachable
      }

      return UserModel(
        uid: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        phoneNumber: '',
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  // ─── helpers ─────────────────────────────────────────────────────────────────

  AuthFailure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.invalidCredentials;
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse;
      case 'weak-password':
        return AuthFailure.weakPassword;
      case 'invalid-email':
        return AuthFailure.invalidEmail;
      case 'too-many-requests':
        return AuthFailure.tooManyRequests;
      case 'user-disabled':
        return AuthFailure.userDisabled;
      case 'network-request-failed':
        return AuthFailure.networkError;
      case 'operation-not-allowed':
        return AuthFailure.operationNotAllowed;
      default:
        return AuthFailure.unknown;
    }
  }
}
