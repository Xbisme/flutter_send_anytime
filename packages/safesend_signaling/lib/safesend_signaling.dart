/// Safe Send signaling wire protocol — versioned JSON frames shared by the app
/// client and the relay (#003). Pure Dart; the single source of truth for the
/// protocol so the two programs can never drift (Constitution VIII).
library;

export 'src/signaling_constants.dart';
export 'src/signaling_frame.dart';
