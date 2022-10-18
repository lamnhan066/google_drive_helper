import 'package:google_drive_helper/src/utils/account_information_model.dart';
import 'package:google_drive_helper/src/google_sign_in_desktop/google_sign_in.dart';
import 'package:google_drive_helper/src/utils/google_auth_client.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'google_drive_helper_interface.dart';

import 'google_drive_helper_stub.dart';
import 'google_sign_in_desktop/google_user_model.dart';

class GoogleDriveHelperDesktop implements GoogleDriveHelperInterface {
  late GoogleSignInDesktop _googleSignIn;
  Stream<bool> get onSignChanged => _googleSignIn.onSignChanged;
  bool get isSigned => _googleSignIn.isSigned;
  AuthClient get authClient => _googleSignIn.authClient;
  GoogleUser get user => _googleSignIn.user;
  Map<String, String> get headers => _googleSignIn.headers;

  bool _isInitialized = false;

  @override
  void initial({String? desktopId, String? desktopSecret}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _googleSignIn.initial();

    assert(desktopId != null, 'desktopId must be non-null on Desktop');

    _googleSignIn = GoogleSignInDesktop(desktopId!, desktopSecret);
    final isSigned = await signInSilently();
    if (isSigned) {
      print('Đã đăng nhập Google tự động');
    } else {
      print('Không thể đăng nhập Google tự động');
    }
  }

  @override
  Future<bool> signIn() async {
    final isSigned = await _googleSignIn.signIn(true);

    if (isSigned) {
      _getDrive =
          GoogleDriveHelperStub(GoogleAuthClient(_googleSignIn.headers));

      return true;
    } else {
      // TODO: Không thể đăng nhập bằng tài khoản này
      return false;
    }
  }

  @override
  Future<bool> signInSilently() async {
    final isSigned = await _googleSignIn.signInSilently();
    if (isSigned) {
      _getDrive =
          GoogleDriveHelperStub(GoogleAuthClient(_googleSignIn.headers));
      print('Đã đăng nhập Google tự động');

      return true;
    } else {
      print('Không thể đăng nhập Google tự động');
    }

    return false;
  }

  @override
  Future<void> signOut() async {
    _isInitialized = false;

    _googleSignIn.dispose();
    await _googleSignIn.signOut();
  }

  @override
  AccountInfo? accountInfo;

  @override
  Future<bool> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  GoogleDriveHelperStub? get getDrive => _getDrive;
  GoogleDriveHelperStub? _getDrive;
}
