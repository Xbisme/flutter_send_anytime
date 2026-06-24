import 'package:flutter/widgets.dart';

/// Direction of a transfer. Shared in `core/` because History (#006) reuses it
/// (avoids a cross-feature import).
enum TransferDirection {
  /// Files sent from this device.
  sent,

  /// Files received by this device.
  received,
}

/// Maps a file extension (upper-case, no dot) to its chip background +
/// foreground color, per the design's file-type palette. Shared in `core/`.
abstract final class FileTypeColors {
  static const _map = <String, (Color bg, Color fg)>{
    'PDF': (Color(0x24FF4D4D), Color(0xFFE5484D)),
    'DOC': (Color(0x242D9CF0), Color(0xFF2D9CF0)),
    'DOCX': (Color(0x242D9CF0), Color(0xFF2D9CF0)),
    'JPG': (Color(0x242D9CF0), Color(0xFF2D9CF0)),
    'XLSX': (Color(0x2400C853), Color(0xFF00A847)),
    'PNG': (Color(0x2400C853), Color(0xFF00A847)),
    'PPTX': (Color(0x29F5A623), Color(0xFFD98E0A)),
    'KEY': (Color(0x29F5A623), Color(0xFFD98E0A)),
    'ZIP': (Color(0x2900C2A8), Color(0xFF009E8A)),
    'MP4': (Color(0x2900C2A8), Color(0xFF009E8A)),
    'HTML': (Color(0x295B6B64), Color(0xFF5B6B64)),
    'TAR': (Color(0x295B6B64), Color(0xFF5B6B64)),
  };

  static const _fallback = (Color(0x295B6B64), Color(0xFF5B6B64));

  /// Background color for [ext]'s file chip.
  static Color background(String ext) =>
      (_map[ext.toUpperCase()] ?? _fallback).$1;

  /// Foreground (text/icon) color for [ext]'s file chip.
  static Color foreground(String ext) =>
      (_map[ext.toUpperCase()] ?? _fallback).$2;
}
