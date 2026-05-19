enum AuthMethod {
  biometric,
  pin,
  password,
  none,
}

extension AuthMethodLabel on AuthMethod {
  String get label {
    switch (this) {
      case AuthMethod.biometric:
        return 'BIOMETRIC';
      case AuthMethod.pin:
        return 'PIN';
      case AuthMethod.password:
        return 'PASSWORD';
      case AuthMethod.none:
        return 'NONE';
    }
  }
}
