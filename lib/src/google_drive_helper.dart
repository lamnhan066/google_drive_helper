import 'dart:convert';
import 'package:http/http.dart';

import 'utils/google_file_type.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveHelper {
  final drive.DriveApi driveApi;
  final String spaces;

  GoogleDriveHelper(
    BaseClient client, {
    this.spaces = 'appDataFolder',
  }) : driveApi = drive.DriveApi(client);

  Future<List<drive.File>> fileList(
      {GoogleFileType fileType = GoogleFileType.all}) async {
    final results = <drive.File>[];
    String? nextPageToken;
    final q = fileType.toQ;
    do {
      final fileList = await driveApi.files.list(
        spaces: spaces,
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
    final List<int> codeUnits = const Utf8Encoder().convert(content);

    return updateAsBytes(fileId, fileName, codeUnits);
  }

  Future<String> updateAsBytes(
      String fileId, String fileName, List<int> bytes) async {
    final drive.File file = drive.File();
    file.parents = <String>[spaces];
    file.name = fileName;

    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(bytes).asStream().asBroadcastStream();

    final drive.Media media = drive.Media(mediaStream, bytes.length);

    final drive.File result = await driveApi.files
        .update(file, fileId, uploadMedia: media, $fields: '*');

    return result.id ?? '';
  }

  Future<drive.File> upload(String fileName, String content,
      {String? parentID}) async {
    final List<int> codeUnits = const Utf8Encoder().convert(content);

    return uploadAsBytes(fileName, codeUnits, parentID: parentID);
  }

  Future<drive.File> uploadAsBytes(String fileName, List<int> bytes,
      {String? parentID}) async {
    final drive.File file = drive.File();
    file.parents = parentID != null ? [parentID] : <String>[spaces];
    file.name = fileName;
    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(bytes).asStream().asBroadcastStream();
    final drive.Media media = drive.Media(mediaStream, bytes.length);

    final drive.File result =
        await driveApi.files.create(file, uploadMedia: media, $fields: '*');

    return result;
  }

  Future<drive.File?> createFolder(
    String folderName, {
    String? parentId,
  }) async {
    final drive.File file = drive.File();
    file.parents = parentId != null ? [parentId] : <String>[spaces];
    file.name = folderName;
    file.mimeType = 'application/vnd.google-apps.folder';

    final drive.File result = await driveApi.files.create(file);

    return result;
  }

  Future delete(String fileId) async {
    await driveApi.files.delete(fileId);
  }

  /// Use downloadAsBytes if you want to return as List<int>
  Future<String> download(String fileId) async {
    return const Utf8Decoder().convert(await downloadAsBytes(fileId));
  }

  Future<List<int>> downloadAsBytes(String fileId) async {
    final drive.Media result = await driveApi.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    // Convert from multiple list from stream to list
    final List<List<int>> contentMultipleList = await result.stream.toList();
    final List<int> contentList = <int>[];
    contentMultipleList.forEach(contentList.addAll);

    return contentList;
  }

  Future<void> deleteAll({GoogleFileType fileType = GoogleFileType.all}) async {
    final list = await fileList(fileType: fileType);
    for (var element in list) {
      if (element.id != null) {
        await delete(element.id!);
      }
    }
  }
}
