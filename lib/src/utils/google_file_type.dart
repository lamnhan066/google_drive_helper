enum GoogleFileType {
  /// Only folder: mimeType='application/vnd.google-apps.folder'
  folder("mimeType='application/vnd.google-apps.folder'"),

  /// Only file: mimeType!='application/vnd.google-apps.folder'
  file("mimeType!='application/vnd.google-apps.folder'"),

  /// Both folder and file
  all(null);

  /// Get mineType
  final String? toQ;
  const GoogleFileType(this.toQ);
}
