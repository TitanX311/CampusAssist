// models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? pictureURL;
  final String? college;
  final String refreshToken;
  final String accessToken;

  factory UserModel.fromResponse(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      pictureURL: map['picture'],
      college: map['college'],
      refreshToken: map['refresh_token'] ?? '',
      accessToken: map['access_token'] ?? '',
    );
  }

  //<editor-fold desc="Data Methods">
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.pictureURL,
    this.college,
    required this.refreshToken,
    required this.accessToken,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          pictureURL == other.pictureURL &&
          college == other.college &&
          refreshToken == other.refreshToken &&
          accessToken == other.accessToken);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      pictureURL.hashCode ^
      college.hashCode ^
      refreshToken.hashCode ^
      accessToken.hashCode;

  @override
  String toString() {
    return 'UserModel{' +
        ' id: $id,' +
        ' name: $name,' +
        ' email: $email,' +
        ' pictureURL: $pictureURL,' +
        ' college: $college,' +
        ' refreshToken: $refreshToken,' +
        ' accessToken: $accessToken,' +
        '}';
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? pictureURL,
    String? college,
    String? refreshToken,
    String? accessToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      pictureURL: pictureURL ?? this.pictureURL,
      college: college ?? this.college,
      refreshToken: refreshToken ?? this.refreshToken,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'email': this.email,
      'pictureURL': this.pictureURL,
      'college': this.college,
      'refreshToken': this.refreshToken,
      'accessToken': this.accessToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      pictureURL: map['pictureURL'] as String?,
      college: map['college'] as String?,
      refreshToken: map['refreshToken'] as String,
      accessToken: map['accessToken'] as String,
    );
  }

  //</editor-fold>
}
