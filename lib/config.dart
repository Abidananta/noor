/// Online gazal sources. Every audio file in the GitHub folder below shows up
/// in the Gazal page automatically (just upload a file to the folder).
///
/// GitHub: 'owner/repo' (reads the "gazal" folder) or 'owner/repo/folder'
///         or a full link such as https://github.com/owner/repo/tree/main/audio
const String kGazalGithub = 'https://github.com/Abidananta/noor/tree/main/gazal';

/// Folder used when only 'owner/repo' is given.
const String kGazalDefaultFolder = 'gazal';

/// Google Drive: folder link or folder ID (folder must be shared as
/// "Anyone with the link - Viewer").
const String kGazalDriveFolder = '';

/// Google API key with the Drive API enabled (needed to list a Drive folder).
const String kGazalDriveKey = '';

/// Kitab (PDF books). Every .pdf file in this GitHub folder shows up in the
/// Kitab page automatically; tapping one opens it inside the app.
/// Just upload PDFs to the `kitab/` folder of the repo - no new build needed.
const String kKitabGithub = 'https://github.com/Abidananta/noor/tree/main/kitab';

// ---------------- App info / updates ----------------

/// Filled in by the build (see .github/workflows/build.yml) from the
/// `version:` line of pubspec.yaml, e.g. "1.0.1+2".
const String kAppVersionFull = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0+1');

String get kAppVersion => kAppVersionFull.split('+').first;
String get kAppBuild => kAppVersionFull.contains('+') ? kAppVersionFull.split('+').last : '1';

/// Developer credit shown on the About page.
const String kDeveloperCredit = 'This App Developed By Ananta Abid';
const String kDeveloperName = 'Ananta Abid';

/// Inbox that receives messages from the in-app "Contact us" form.
/// It is never shown anywhere in the UI.
const String kContactEmail = 'anantaabid24@gmail.com';

/// In-app mail (admin address stays hidden).
///
/// 1. Go to https://web3forms.com, enter [kContactEmail] and you get a free
///    "Access Key" by email.
/// 2. Paste it below. Messages are then delivered straight to that inbox
///    without the user's mail app opening and without the address being shown.
///
/// While this is empty the form falls back to the phone's mail app.
const String kContactAccessKey = '';
const String kContactEndpoint = 'https://api.web3forms.com/submit';

/// GitHub repo ('owner/repo') whose latest Release holds the newest APK.
/// Leave empty and the app asks for it the first time "Update app" is tapped.
const String kUpdateGithub = 'Abidananta/noor';

/// Set by the GitHub build (--dart-define=UPDATE_REPO=owner/repo) so the app
/// knows where to look without asking.
const String kUpdateRepoBuild = String.fromEnvironment('UPDATE_REPO', defaultValue: '');
