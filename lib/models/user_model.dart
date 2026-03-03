// models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String college;

  //<editor-fold desc="Data Methods">
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.college,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          college == other.college);

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ email.hashCode ^ college.hashCode;

  @override
  String toString() {
    return 'UserModel{' +
        ' id: $id,' +
        ' name: $name,' +
        ' email: $email,' +
        ' college: $college,' +
        '}';
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? college,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      college: college ?? this.college,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'email': this.email,
      'college': this.college,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      college: map['college'] as String,
    );
  }

  //</editor-fold>
}
