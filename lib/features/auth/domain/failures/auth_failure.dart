enum AuthFailure {
  /// Email or password is incorrect
  invalidCredentials,

  /// No user found with this email
  userNotFound,

  /// Email already registered
  emailAlreadyInUse,

  /// Password is too weak
  weakPassword,

  /// Email format is invalid
  invalidEmail,

  /// Too many failed attempts – account temporarily locked
  tooManyRequests,

  /// Network error
  networkError,

  /// User account has been disabled
  userDisabled,

  /// Operation timed out
  operationNotAllowed,

  /// An unexpected server or unknown error
  unknown,
}

extension AuthFailureMessage on AuthFailure {
  String get message {
    switch (this) {
      case AuthFailure.invalidCredentials:
        return 'Incorrect email or password. Please try again.';
      case AuthFailure.userNotFound:
        return 'No account found with this email.';
      case AuthFailure.emailAlreadyInUse:
        return 'This email is already registered. Please log in.';
      case AuthFailure.weakPassword:
        return 'Password must be at least 8 characters.';
      case AuthFailure.invalidEmail:
        return 'Please enter a valid email address.';
      case AuthFailure.tooManyRequests:
        return 'Too many attempts. Please wait a moment and try again.';
      case AuthFailure.networkError:
        return 'Network error. Please check your connection.';
      case AuthFailure.userDisabled:
        return 'This account has been disabled. Contact support.';
      case AuthFailure.operationNotAllowed:
        return 'This sign-in method is not enabled.';
      case AuthFailure.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
