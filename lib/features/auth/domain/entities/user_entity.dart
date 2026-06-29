class UserEntity {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String gender; // 'male' | 'female'
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.gender = 'male',
    required this.createdAt,
    required this.updatedAt,
  });
}
