import 'dart:convert';

import 'utils/google_auth_client.dart';
import 'utils/google_file_type.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveHelperStub {
  final drive.DriveApi driveApi;

  GoogleDriveHelperStub(GoogleAuthClient client)
      : driveApi = drive.DriveApi(client);

  Future<List> fileList({GoogleFileType fileType = GoogleFileType.all}) async {
    final results = <drive.File>[];
    String? nextPageToken;
    String? q;
    switch (fileType) {
      case GoogleFileType.folder:
        q = "mimeType='application/vnd.google-apps.folder'";
        break;
      case GoogleFileType.file:
        q = "mimeType!='application/vnd.google-apps.folder'";
        break;
      case GoogleFileType.all:
        q = null;
        break;
    }
    do {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        pageToken: nextPageToken,
        $fields: '*',
        q: q,
      );
      results.addAll(fileList.files ?? []);
      nextPageToken = fileList.nextPageToken;
    } while (nextPageToken != null);

    return results;
  }

  Future<String> update(String fileId, String fileName, String content) async {
    final drive.File file = drive.File();
    file.parents = <String>['appDataFolder'];
    file.name = fileName;

    final List<int> codeUnits = const Utf8Encoder().convert(content);

    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(codeUnits).asStream().asBroadcastStream();

    final drive.Media media = drive.Media(mediaStream, codeUnits.length);

    final drive.File result = await driveApi.files
        .update(file, fileId, uploadMedia: media, $fields: '*');

    return result.id ?? '';
  }

  Future<drive.File> upload(String fileName, String content,
      {String? parentID}) async {
    final drive.File file = drive.File();
    file.parents = parentID != null ? [parentID] : <String>['appDataFolder'];
    file.name = fileName;

    final List<int> codeUnits = const Utf8Encoder().convert(content);
    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(codeUnits).asStream().asBroadcastStream();
    final drive.Media media = drive.Media(mediaStream, codeUnits.length);

    final drive.File result =
        await driveApi.files.create(file, uploadMedia: media, $fields: '*');

    return result;
  }

  Future delete(String fileId) async {
    await driveApi.files.delete(fileId);
  }

  Future download(String fileId) async {
    final drive.Media result = await driveApi.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    // Convert from multiple list from stream to list
    final List<List<int>> contentMultipleList = await result.stream.toList();
    final List<int> contentList = <int>[];
    contentMultipleList.forEach(contentList.addAll);

    return const Utf8Decoder()
        .convert(contentList); // Utf8Decoder().convert(contentList);
  }
}
