import 'dart:convert';
import 'package:http/http.dart';

import 'utils/google_file_type.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveHelper {
  late drive.DriveApi _driveApi;
  late String _spaces;

  /// Create an instance
  GoogleDriveHelper();

  /// Initialize the plugin
  void initial({
    required BaseClient client,
    String spaces = 'appDataFolder',
  }) {
    _driveApi = drive.DriveApi(client);
    _spaces = spaces;
  }

  /// Get list of all files with param [fileType]
  Future<List<drive.File>> fileList({
    GoogleFileType fileType = GoogleFileType.all,
  }) async {
    final results = <drive.File>[];
    String? nextPageToken;
    final q = fileType.toQ;
    do {
      final fileList = await _driveApi.files.list(
        spaces: _spaces,
        pageToken: nextPageToken,
        $fields: '*',
        q: q,
      );
      results.addAll(fileList.files ?? []);
      nextPageToken = fileList.nextPageToken;
    } while (nextPageToken != null);

    return results;
  }

  Future<String> update({
    required String fileId,
    String? fileName,
    required String content,
  }) async {
    final List<int> codeUnits = const Utf8Encoder().convert(content);

    return updateAsBytes(fileId: fileId, fileName: fileName, bytes: codeUnits);
  }

  Future<String> updateAsBytes({
    required String fileId,
    String? fileName,
    required List<int> bytes,
  }) async {
    final drive.File file = drive.File();
    file.parents = <String>[_spaces];
    file.name = fileName;

    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(bytes).asStream().asBroadcastStream();

    final drive.Media media = drive.Media(mediaStream, bytes.length);

    final drive.File result = await _driveApi.files
        .update(file, fileId, uploadMedia: media, $fields: '*');

    return result.id ?? '';
  }

  Future<drive.File> upload({
    String? fileName,
    required String content,
    String? parentID,
  }) async {
    final List<int> codeUnits = const Utf8Encoder().convert(content);

    return uploadAsBytes(
      fileName: fileName,
      bytes: codeUnits,
      parentID: parentID,
    );
  }

  Future<drive.File> uploadAsBytes({
    String? fileName,
    required List<int> bytes,
    String? parentID,
  }) async {
    final drive.File file = drive.File();
    file.parents = parentID != null ? [parentID] : <String>[_spaces];
    file.name = fileName;
    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(bytes).asStream().asBroadcastStream();
    final drive.Media media = drive.Media(mediaStream, bytes.length);

    final drive.File result =
        await _driveApi.files.create(file, uploadMedia: media, $fields: '*');

    return result;
  }

  Future<drive.File?> createFolder({
    String? folderName,
    String? parentId,
  }) async {
    final drive.File file = drive.File();
    file.parents = parentId != null ? [parentId] : <String>[_spaces];
    file.name = folderName;
    file.mimeType = 'application/vnd.google-apps.folder';

    final drive.File result = await _driveApi.files.create(file);

    return result;
  }

  Future delete(String fileId) async {
    await _driveApi.files.delete(fileId);
  }

  /// Use downloadAsBytes if you want to return as List<int>
  Future<String> download(String fileId) async {
    return const Utf8Decoder().convert(await downloadAsBytes(fileId));
  }

  Future<List<int>> downloadAsBytes(String fileId) async {
    final drive.Media result = await _driveApi.files.get(fileId,
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
