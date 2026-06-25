import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';

part 'incoming_offer.freezed.dart';

/// The manifest summary shown at the incoming-transfer prompt (#005). A pure
/// presentation projection of a [TransferManifest] — held only for the session.
/// The peer is a generic localized label until device profiles arrive (#010).
@freezed
abstract class IncomingOffer with _$IncomingOffer {
  const factory IncomingOffer({
    required String senderLabel,
    required int fileCount,
    required int totalBytes,
    required List<String> typeSummary,
  }) = _IncomingOffer;

  /// Build the offer summary from [manifest]; [senderLabel] is the generic
  /// localized "Người gửi" supplied by the UI layer (no peer name is exchanged).
  factory IncomingOffer.fromManifest(
    TransferManifest manifest, {
    required String senderLabel,
  }) {
    final exts = <String>{};
    for (final f in manifest.files) {
      final dot = f.name.lastIndexOf('.');
      if (dot > 0 && dot < f.name.length - 1) {
        exts.add(f.name.substring(dot + 1).toUpperCase());
      }
    }
    return IncomingOffer(
      senderLabel: senderLabel,
      fileCount: manifest.fileCount,
      totalBytes: manifest.totalBytes,
      typeSummary: exts.toList(),
    );
  }
}
