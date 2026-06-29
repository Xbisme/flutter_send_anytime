/// Fixed format sets + bounds for the in-app file viewers (#013). One source
/// of truth; image/video sets live on `FileCategory` (#012) and are reused by
/// `ViewerResolver`.
library;

/// Audio extensions (lower-case, no dot) routed to the shared media player.
const kAudioExts = <String>{
  'mp3',
  'm4a',
  'aac',
  'wav',
  'flac',
  'ogg',
  'oga',
  'opus',
  'aiff',
  'aif',
  'caf',
};

/// PDF extensions routed to the document viewer.
const kPdfExts = <String>{'pdf'};

/// Plain-text + source-code extensions routed to the text viewer. Anything not
/// here (and not image/video/audio/pdf) is unsupported → OS open/share.
const kTextExts = <String>{
  'txt',
  'text',
  'md',
  'markdown',
  'json',
  'xml',
  'csv',
  'tsv',
  'log',
  'yaml',
  'yml',
  'ini',
  'conf',
  'toml',
  'html',
  'htm',
  'css',
  'js',
  'ts',
  'dart',
  'py',
  'java',
  'kt',
  'swift',
  'c',
  'h',
  'cpp',
  'hpp',
  'cc',
  'cs',
  'go',
  'rb',
  'php',
  'sh',
  'bash',
  'sql',
  'gradle',
  'properties',
};

/// Source-code extensions that render in a monospace style (subset of
/// [kTextExts] minus prose formats).
const kCodeExts = <String>{
  'json',
  'xml',
  'yaml',
  'yml',
  'toml',
  'ini',
  'conf',
  'html',
  'htm',
  'css',
  'js',
  'ts',
  'dart',
  'py',
  'java',
  'kt',
  'swift',
  'c',
  'h',
  'cpp',
  'hpp',
  'cc',
  'cs',
  'go',
  'rb',
  'php',
  'sh',
  'bash',
  'sql',
  'gradle',
  'properties',
  'csv',
  'tsv',
  'log',
};

/// Max bytes the text viewer reads; larger files are shown truncated with a
/// notice (FR-010a). 1 MiB.
const int kTextViewerCapBytes = 1 << 20;

/// Decode width cap for a generated video thumbnail (FR-013).
const int kVideoThumbMaxWidth = 320;

/// On-disk LRU bound for the video-thumbnail cache (FR-013a). 64 MiB.
const int kVideoThumbCacheMaxBytes = 64 << 20;
