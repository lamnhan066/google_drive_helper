enum GoogleFileType {
  folder("mimeType='application/vnd.google-apps.folder'"),
  file("mimeType!='application/vnd.google-apps.folder'"),
  all(null);

  final String? toQ;
  const GoogleFileType(this.toQ);
}
