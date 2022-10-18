import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:encrypt/encrypt.dart' as en;
import 'package:path/path.dart' as path;
import 'package:hive/src/hive_impl.dart';

import 'google_user_model.dart';

class GoogleSignInDesktop {
  /// Id desktop
  final String _id;
  final String? _secret;

  GoogleSignInDesktop(this._id, this._secret);

  bool get isSigned => _authClient != null;
  auth.AuthClient get authClient => _authClient!;
  GoogleUser get user => _user!;
  Map<String, String> get headers => _getHeaders();

  auth.AuthClient? _authClient;
  GoogleUser? _user;
  auth.AccessCredentials? _credentials;

  Stream<bool> get onSignChanged => _onSignedInController.stream;
  final StreamController<bool> _onSignedInController =
      StreamController.broadcast();

  static const _isPersistedKey = 'PersistedLoginState';

  /// Tạo Key và IV ngẫu nhiên
  /// apHBDDKpEDXHhrQxpMRlkDmXwqV2
  static en.Key get key => en.Key.fromBase64('w1C41T9wNk1UvRzP07tf1Q==');
  static en.IV get iv => en.IV.fromBase64('ywR9SusJUxsKmWSz9B05rw==');
  static en.Encrypter encrypter = en.Encrypter(en.AES(key));

  static final hiveImpl = HiveImpl();
  static late Box _hiveConfig;
  static String get _hiveKey => 'KeyForGoogleDriveCredential';

  static bool _isInitialzed = false;

  Future<void> initial() async {
    if (!_isInitialzed) return;
    _isInitialzed = true;

    if (!kIsWeb) {
      var hivePath = (await getApplicationSupportDirectory()).path;

      final finalPath = path.join(hivePath, 'GoogleSignInDesktop');
      print('Đường dẫn lưu dữ liệu: $finalPath');
      hiveImpl.init(finalPath);
    }

    _hiveConfig = await hiveImpl.openBox('Box');
  }

  Future<bool> signIn(bool isPersisted) async {
    await initial();

    if (_authClient != null) return true;

    _setPersistState(isPersisted);
    final client = http.Client();
    final clientId = auth.ClientId(_id, _secret);
    try {
      _credentials = await auth.obtainAccessCredentialsViaUserConsent(
        clientId,
        [DriveApi.driveAppdataScope, 'profile', 'email'],
        client,
        _prompt,
      );

      print('No Silence ${_credentials!.toJson()}');

      // _authClient = auth.authenticatedClient(client, _credentials);
      _authClient = auth.autoRefreshingClient(clientId, _credentials!, client);

      final googleAuthCredentials = GoogleAuthProvider.credential(
        accessToken: _credentials!.accessToken.data,
        idToken: _credentials!.idToken,
      );
      final firebaseUser = await FirebaseAuth.instance
          .signInWithCredential(googleAuthCredentials);

      _user = await getUserInfo(firebaseUser.user!.uid);

      if (isPersisted) {
        final combinedJson = _user!.toMap()..addAll(_credentials!.toJson());
        _hiveConfig.put(
          _hiveKey,
          encrypter.encrypt(jsonEncode(combinedJson), iv: iv).base64,
        );
      } else {
        _hiveConfig.put(_hiveKey, '');
      }

      _onSignedInController.sink.add(true);
      return true;
    } catch (e) {
      print('LogIn error: $e');
    }

    _onSignedInController.sink.add(false);
    return false;
  }

  Future<bool> signInSilently() async {
    await initial();

    if (!_getPersistState() || FirebaseAuth.instance.currentUser == null) {
      return false;
    }

    final clientId = auth.ClientId(_id, _secret);
    final credentialConfigEncrypted = _hiveConfig.get(_hiveKey);
    if (credentialConfigEncrypted != null && credentialConfigEncrypted != '') {
      try {
        final credentialConfig = encrypter.decrypt(
            en.Encrypted.fromBase64(credentialConfigEncrypted),
            iv: iv);
        final client = http.Client();

        final tempCredentials =
            auth.AccessCredentials.fromJson(jsonDecode(credentialConfig));

        _credentials =
            await auth.refreshCredentials(clientId, tempCredentials, client);

        final combinedJson = jsonDecode(credentialConfig)
          ..addAll(_credentials!.toJson());
        _hiveConfig.put(_hiveKey,
            encrypter.encrypt(jsonEncode(combinedJson), iv: iv).base64);

        _authClient =
            auth.autoRefreshingClient(clientId, _credentials!, client);

        _user = GoogleUser.fromMap(combinedJson);

        _onSignedInController.sink.add(true);
        return true;
      } catch (e) {
        /// Không thể refresh được credential thì xoá dữ liệu local và buộc
        /// người dùng phải authenticate lại
        _hiveConfig.put(_hiveKey, '');
      }
    }

    _onSignedInController.sink.add(false);
    return false;
  }

  void dispose() {
    _onSignedInController.sink.add(false);
    _authClient?.close();
    _authClient = null;
    _credentials = null;
    _user = null;
  }

  Future<void> signOut() async {
    await initial();

    _onSignedInController.sink.add(false);
    dispose();
    await _hiveConfig.put(_hiveKey, '');
    await _hiveConfig.close();
    await FirebaseAuth.instance.signOut();
  }

  Future getUserInfo(String firebaseId) async {
    final response = await _authClient!
        .get(Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'));

    return GoogleUser.fromJson(response.body).copyWith(firebaseId: firebaseId);
  }

  void _setPersistState(bool isPersisted) {
    _hiveConfig.put(_isPersistedKey, isPersisted);
  }

  bool _getPersistState() {
    return _hiveConfig.get(_isPersistedKey) ?? false;
  }

  Map<String, String> _getHeaders() {
    return {'Authorization': 'Bearer  ${_credentials!.accessToken.data}'};
  }

  void _prompt(String url) {
    _lauchAuthInBrowser(url);
  }

  void _lauchAuthInBrowser(String url) async {
    await canLaunchUrlString(url)
        ? await launchUrlString(url)
        : throw 'Could not lauch $url';
  }
}
