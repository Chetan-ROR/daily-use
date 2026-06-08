import 'package:local_auth/local_auth.dart';

class SecurityService {
  SecurityService._();
  static final instance = SecurityService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    return supported && canCheck;
  }

  Future<bool> authenticate() async {
    if (!await canUseBiometrics()) return false;
    return _auth.authenticate(
      localizedReason: 'Unlock Life Manager Pro',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }
}
