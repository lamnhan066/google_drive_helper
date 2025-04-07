import 'dart:async';
import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart';

import 'utils/google_file_type.dart';

class GoogleDriveHelper {
  late drive.DriveApi _driveApi;
  late String spaces;

  /// Create an instance.
  ///
  /// [client] is the authenticated client and can be got from `google_sign_in_helper` plugin
  /// or `google_sign_in`. Default [spaces] is `appDataFolder`.
  GoogleDriveHelper({
    required BaseClient client,
    this.spaces = 'appDataFolder',
  }) {
    _driveApi = drive.DriveApi(client);
  }

  /// Generate [count] of unique file ids.
  Future<List<String>> generateIds(int count) async {
    final generatedIds = await _driveApi.files.generateIds(
      count: count,
      space: spaces,
    );

    return generatedIds.ids ?? [];
  }

  /// Get list of all files with param [fileType].
  Future<List<drive.File>> fileList({
    GoogleFileType fileType = GoogleFileType.all,
  }) async {
    final results = <drive.File>[];
    String? nextPageToken;
    final q = fileType.toQ;
    do {
      final fileList = await _driveApi.files.list(
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

  /// Update file with [fileId].
  Future<String> update({
    required String fileId,
    String? fileName,
    String? description,
    required String content,
  }) async {
    final List<int> codeUnits = const Utf8Encoder().convert(content);

    return updateAsBytes(
      fileId: fileId,
      fileName: fileName,
      description: description,
      bytes: codeUnits,
    );
  }

  /// Update file with [fileId] as bytes content.
  Future<String> updateAsBytes({
    required String fileId,
    String? fileName,
    String? description,
    required List<int> bytes,
  }) async {
    final drive.File file = drive.File();
    file.name = fileName;
    file.description = description;

    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(bytes).asStream().asBroadcastStream();

    final drive.Media media = drive.Media(mediaStream, bytes.length);

    final drive.File result = await _driveApi.files
        .update(file, fileId, uploadMedia: media, $fields: 'id');

    return result.id ?? '';
  }

  /// Upload file as String.
  Future<drive.File> upload({
    String? fileName,
    String? description,
    required String content,
    String? parentID,
  }) async {
    final List<int> codeUnits = const Utf8Encoder().convert(content);

    return uploadAsBytes(
      fileName: fileName,
      description: description,
      bytes: codeUnits,
      parentID: parentID,
    );
  }

  /// Upload file as bytes.
  Future<drive.File> uploadAsBytes({
    String? fileName,
    String? description,
    required List<int> bytes,
    String? parentID,
  }) async {
    final drive.File file = drive.File();
    file.parents = parentID != null ? [parentID] : <String>[spaces];
    file.name = fileName;
    file.description = description;
    final Stream<List<int>> mediaStream =
        Future<List<int>>.value(bytes).asStream().asBroadcastStream();
    final drive.Media media = drive.Media(mediaStream, bytes.length);

    final drive.File result =
        await _driveApi.files.create(file, uploadMedia: media, $fields: '*');

    return result;
  }

  /// Create folder.
  Future<drive.File?> createFolder({
    String? folderName,
    String? parentId,
  }) async {
    final drive.File file = drive.File();
    file.parents = parentId != null ? [parentId] : <String>[spaces];
    file.name = folderName;
    file.mimeType = 'application/vnd.google-apps.folder';

    final drive.File result = await _driveApi.files.create(file);

    return result;
  }

  /// Delete file with [fileId].
  Future delete(String fileId) async {
    await _driveApi.files.delete(fileId);
  }

  /// Download file and return as String.
  Future<String> download(String fileId) async {
    return const Utf8Decoder().convert(await downloadAsBytes(fileId));
  }

  /// Download file and return as bytes.
  Future<List<int>> downloadAsBytes(String fileId) async {
    final drive.Media result = await _driveApi.files.get(fileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    // Convert from multiple list from stream to list.
    final List<List<int>> contentMultipleList = await result.stream.toList();
    final List<int> contentList = <int>[];
    contentMultipleList.forEach(contentList.addAll);

    return contentList;
  }

  /// Delete all [fileType]s.
  Future<void> deleteAll({GoogleFileType fileType = GoogleFileType.all}) async {
    final list = await fileList(fileType: fileType);
    for (var element in list) {
      if (element.id != null) {
        await delete(element.id!);
      }
    }
  }
}
