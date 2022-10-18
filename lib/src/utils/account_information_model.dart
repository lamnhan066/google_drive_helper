import 'dart:convert';

class AccountInfo {
  String? name;
  String? email;
  String? photoUrl;
  AccountInfo({
    this.name,
    this.email,
    this.photoUrl,
  });

  AccountInfo copyWith({
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return AccountInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  factory AccountInfo.fromMap(Map<String, dynamic> map) {
    return AccountInfo(
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AccountInfo.fromJson(String source) =>
      AccountInfo.fromMap(json.decode(source));

  @override
  String toString() =>
      'AccountInfo(name: $name, email: $email, photoUrl: $photoUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AccountInfo &&
        other.name == name &&
        other.email == email &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => name.hashCode ^ email.hashCode ^ photoUrl.hashCode;
}
