# Google Drive Helper

Make it easier for you to use google drive on all platforms.

## Usage

**Create an instance:**

``` dart
final googleDriveHelper = GoogleDriveHelper();
```

**Initialize the instance:**

``` dart
googleDriveHelper.initial(
    // Get this value from [google_sign_in_helper] plugin or using [AuthClient] from [google_sign_in] plugin
    client: googleSignInHelper.client,
    spaces: 'appDataFolder',
);
```

**All methods:**

``` dart
googleDriveHelper.fileList();
googleDriveHelper.update(
    fileId: <id of file>,
    content: <content as String>,
);
googleDriveHelper.updateAsBytes(
    fileId: <id of file>,
    bytes: <content as List<int>>,
);
googleDriveHelper.upload(
    content: <content as String>,
);
googleDriveHelper.uploadAsBytes(
    bytes: <content as List<int>>,
);
googleDriveHelper.createFolder();
googleDriveHelper.delete(<id of file>);
googleDriveHelper.download(<id of file>);
googleDriveHelper.downloadAsBytes(<id of file>);
```
