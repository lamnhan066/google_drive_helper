export 'package:googleapis/drive/v3.dart' show File;

import 'dart:io' as io;

import 'package:google_drive_helper/src/utils/account_information_model.dart';
import 'package:google_drive_helper/src/google_drive_helper_desktop.dart';
import 'package:google_drive_helper/src/google_drive_helper_interface.dart';
import 'package:google_drive_helper/src/google_drive_helper_mobile.dart';

import 'src/google_drive_helper_stub.dart';

class GoogleDriveHelper implements GoogleDriveHelperInterface {
  final GoogleDriveHelperInterface _delegate =
      io.Platform.isAndroid || io.Platform.isIOS
          ? GoogleDriveHelperMobile()
          : GoogleDriveHelperDesktop();

  @override
  void initial({String? desktopId, String? desktopSecret}) =>
      _delegate.initial(desktopId: desktopId, desktopSecret: desktopSecret);

  @override
  Future<bool> signIn() => _delegate.signIn();

  @override
  Future<bool> signInSilently() => _delegate.signInSilently();

  @override
  Future<void> signOut() => _delegate.signOut();

  @override
  AccountInfo? get accountInfo => _delegate.accountInfo;

  @override
  Future<void> disconnect() => _delegate.disconnect();

  @override
  GoogleDriveHelperStub? get getDrive => _delegate.getDrive;
}
