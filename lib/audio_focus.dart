import 'package:flutter/foundation.dart';

/// Which feature currently owns the speaker: 'quran', 'gazal' or ''.
/// Each audio engine pauses itself when the other one takes over, so the
/// Quran recitation and a gazal never play at the same time.
final ValueNotifier<String> audioOwner = ValueNotifier<String>('');
