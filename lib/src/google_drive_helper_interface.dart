import 'package:google_drive_helper/src/utils/account_information_model.dart';

import 'google_drive_helper_stub.dart';

abstract class GoogleDriveHelperInterface {
  AccountInfo? get accountInfo;
  GoogleDriveHelperStub? get getDrive;
  void initial({String? desktopId, String? desktopSecret}) =>
      throw UnimplementedError();
  Future<bool> signIn() => throw UnimplementedError();
  Future<bool> signInSilently() => throw UnimplementedError();
  Future<void> disconnect() => throw UnimplementedError();
  Future<void> signOut() => throw UnimplementedError();
}
