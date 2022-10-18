import 'package:google_drive_helper/src/utils/account_information_model.dart';
import 'package:google_drive_helper/src/google_drive_helper.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'utils/google_auth_client.dart';
import 'google_drive_helper_interface.dart';
import 'utils/google_file_type.dart';

class GoogleDriveHelperMobile implements GoogleDriveHelperInterface {
  GoogleSignInAccount? _googleAccount;
  final GoogleSignIn _googleSignIn =
      GoogleSignIn.standard(scopes: <String>[drive.DriveApi.driveAppdataScope]);

  late GoogleDriveHelper helper;

  @override
  void initial({String? desktopId, String? desktopSecret}) {}

  @override
  Future<bool> signIn() async {
    try {
      _googleAccount = await _googleSignIn.signIn();

      if (_googleAccount != null) {
        accountInfo = AccountInfo(
          email: _googleAccount!.email,
          name: _googleAccount!.displayName,
          photoUrl: _googleAccount!.photoUrl,
        );
        final Map<String, String> authHeaders =
            await _googleAccount!.authHeaders;
        final GoogleAuthClient authenticateClient =
            GoogleAuthClient(authHeaders);

        helper = GoogleDriveHelper(authenticateClient);
      } else {
        print('Cannot sign in google: googleAccount == null');
        return false;
      }

      print('Signed in google: ${_googleAccount?.displayName}');

      return true;
    } catch (error) {
      print('Cannot sign in google: $error');
      return false;
    }
  }

  @override
  Future<bool> signInSilently() async {
    try {
      _googleAccount = await _googleSignIn.signInSilently();

      if (_googleAccount != null) {
        accountInfo = AccountInfo(
          email: _googleAccount!.email,
          name: _googleAccount!.displayName,
          photoUrl: _googleAccount!.photoUrl,
        );
        final Map<String, String> authHeaders =
            await _googleAccount!.authHeaders;
        final GoogleAuthClient authenticateClient =
            GoogleAuthClient(authHeaders);

        helper = GoogleDriveHelper(authenticateClient);

        return true;
      }

      return false;
    } catch (error) {
      print('Cannot sign in silently: $error');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    accountInfo = null;
  }

  @override
  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
  }

  @override
  AccountInfo? accountInfo;

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
}
