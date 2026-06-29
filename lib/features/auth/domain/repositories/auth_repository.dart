import 'package:al_qari/features/auth/domain/entities/user_entity.dart';
import 'package:al_qari/features/auth/domain/failures/auth_failure.dart';

abstract class AuthRepository {
  /// Returns the currently signed-in [UserEntity], or null if no user.
  UserEntity? get currentUser;

  /// Signs in with [email] and [password].
  /// Throws [AuthFailure] on error.
  Future<UserEntity> signIn({required String email, required String password});

  /// Creates a new account, stores the user profile in Firestore, and
  /// returns the newly created [UserEntity].
  /// Throws [AuthFailure] on error.
  Future<UserEntity> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String gender,
    required String password,
  });

  /// Updates the user's profile (fullName, phoneNumber, gender) in Firestore.
  /// Returns the updated [UserEntity]. Throws [AuthFailure] on error.
  Future<UserEntity> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String gender,
  });

  /// Signs in (or signs up) via Google OAuth.
  /// Creates a Firestore user doc on first sign-in.
  /// Throws [AuthFailure] on error.
  Future<UserEntity> signInWithGoogle();

  /// Sends a password-reset email to [email].
  /// Throws [AuthFailure] on error.
  Future<void> sendPasswordResetEmail({required String email});

  /// Signs the current user out.
  Future<void> signOut();

  /// Stream of auth-state changes.
  Stream<UserEntity?> authStateChanges();
}
