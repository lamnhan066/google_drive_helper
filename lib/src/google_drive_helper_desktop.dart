import 'package:google_drive_helper/src/utils/account_information_model.dart';
import 'package:google_drive_helper/src/google_sign_in_desktop/google_sign_in.dart';
import 'package:google_drive_helper/src/utils/google_auth_client.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'google_drive_helper.dart';
import 'google_drive_helper_interface.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'google_sign_in_desktop/google_user_model.dart';
import 'utils/google_file_type.dart';

class GoogleDriveHelperDesktop implements GoogleDriveHelperInterface {
  late final GoogleSignInDesktop googleSignIn;
  Stream<bool> get onSignChanged => googleSignIn.onSignChanged;
  bool get isSigned => googleSignIn.isSigned;
  AuthClient get authClient => googleSignIn.authClient;
  GoogleUser get user => googleSignIn.user;
  Map<String, String> get headers => googleSignIn.headers;

  late GoogleDriveHelper helper;

  bool _isInitialized = false;

  @override
  void initial({String? desktopId, String? desktopSecret}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    assert(desktopId != null, 'desktopId must be non-null on Desktop');

    googleSignIn = GoogleSignInDesktop(desktopId!, desktopSecret);
    final isSigned = await signInSilently();
    if (isSigned) {
      print('Đã đăng nhập Google tự động');
    } else {
      print('Không thể đăng nhập Google tự động');
    }
  }

  @override
  Future<bool> signIn() async {
    final isSigned = await googleSignIn.signIn(true);

    if (isSigned) {
      helper = GoogleDriveHelper(GoogleAuthClient(googleSignIn.headers));

      return true;
    } else {
      // TODO: Không thể đăng nhập bằng tài khoản này
      return false;
    }
  }

  @override
  Future<bool> signInSilently() async {
    final isSigned = await googleSignIn.signInSilently();
    if (isSigned) {
      helper = GoogleDriveHelper(GoogleAuthClient(googleSignIn.headers));
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

    googleSignIn.dispose();
    await googleSignIn.signOut();
  }

  @override
  AccountInfo? accountInfo;

  @override
  Future<bool> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future<List> fileList({GoogleFileType fileType = GoogleFileType.all}) =>
      helper.fileList(fileType: fileType);

  @override
  Future<String> update(String fileId, String fileName, String content) =>
      helper.update(fileId, fileName, content);

  @override
  Future<drive.File> upload(
    String fileName,
    String content, {
    String? parentID,
  }) =>
      helper.upload(fileName, content, parentID: parentID);

  @override
  Future delete(String fileId) => helper.delete(fileId);

  @override
  Future download(String fileId) => helper.download(fileId);

  Future<void> deleteAll({GoogleFileType fileType = GoogleFileType.all}) async {
    final list = await fileList(fileType: fileType);
    for (var element in list) {
      if (element.id != null) {
        print('Đang xóa file có tên: ${element.name}, id: ${element.id}');
        await delete(element.id!);
      }
    }
  }
}
