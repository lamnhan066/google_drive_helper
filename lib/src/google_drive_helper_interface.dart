import 'package:google_drive_helper/src/utils/account_information_model.dart';
import 'package:googleapis/drive/v3.dart';

abstract class GoogleDriveHelperInterface {
  AccountInfo? get accountInfo;
  void initial({String? desktopId, String? desktopSecret}) =>
      throw UnimplementedError();
  Future<bool> signIn() => throw UnimplementedError();
  Future<bool> signInSilently() => throw UnimplementedError();
  Future<void> disconnect() => throw UnimplementedError();
  Future<void> signOut() => throw UnimplementedError();
  Future<List> fileList() => throw UnimplementedError();
  Future<File> upload(String fileName, String content) =>
      throw UnimplementedError();
  Future<dynamic> update(String fileId, String fileName, String content) =>
      throw UnimplementedError();
  Future<dynamic> download(String fileId) => throw UnimplementedError();
  Future<dynamic> delete(String fileId) => throw UnimplementedError();
}
