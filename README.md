# Noor App (Flutter)

1. GitHub e notun repo banao, ei folder er shob file upload/push koro.
2. Actions tab -> "Build APK" -> Run workflow (ba push korlei auto cholbe).
3. Build shesh hole run page er Artifacts theke `noor-app-apk` download koro, zip khule APK install koro.

## গজল (audio)
- অ্যাপের গজল পেজে উপরের `+` বাটন দিয়ে ফোন থেকে mp3/m4a যোগ করা যায়।
- অ্যাপের ভেতরে বান্ডেল করতে: অডিও ফাইল `assets/audio/` এ রাখো এবং `assets/gazal.json` এ লেখো:
  `[{"title": "গজলের নাম", "artist": "শিল্পী", "asset": "audio/file.mp3"}]`
- ইন্টারনেট থেকে চালাতে: `{"title": "...", "artist": "...", "url": "https://.../file.mp3"}`

## AI জিজ্ঞাসা
- পেজের চাবি (key) আইকনে নিজের Anthropic API key দিতে হবে; কী শুধু ফোনে সংরক্ষিত থাকে।
- সবার জন্য প্রকাশ করলে API key অ্যাপে না রেখে নিজের সার্ভারের মাধ্যমে কল করা নিরাপদ।
