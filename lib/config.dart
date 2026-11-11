/// Default online gazal sources (optional).
///
/// Anything you type in the app (Gazal page -> cloud icon) overrides these.
/// Fill them in if you want every user to get your gazal list out of the box.
///
/// GitHub: 'owner/repo' (reads the "gazal" folder) or 'owner/repo/folder'
///         or a full link such as https://github.com/owner/repo/tree/main/audio
const String kGazalGithub = '';

/// Folder used when only 'owner/repo' is given.
const String kGazalDefaultFolder = 'gazal';

/// Google Drive: folder link or folder ID (folder must be shared as
/// "Anyone with the link - Viewer").
const String kGazalDriveFolder = '';

/// Google API key with the Drive API enabled (needed to list a Drive folder).
const String kGazalDriveKey = '';

// ---------------- App info / updates ----------------

/// Filled in by the build (see .github/workflows/build.yml) from the
/// `version:` line of pubspec.yaml, e.g. "1.0.1+2".
const String kAppVersionFull = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0+1');

String get kAppVersion => kAppVersionFull.split('+').first;
String get kAppBuild => kAppVersionFull.contains('+') ? kAppVersionFull.split('+').last : '1';

/// "Contact us" opens an email to this address.
const String kContactEmail = 'anantaabid24@gmail.com';

/// GitHub repo ('owner/repo') whose latest Release holds the newest APK.
/// Leave empty and the app asks for it the first time "Update app" is tapped.
const String kUpdateGithub = '';
