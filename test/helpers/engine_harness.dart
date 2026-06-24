import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/services/signaling/loopback_signaling_channel.dart';
import 'package:safe_send/core/services/transport/loopback_data_transport.dart';
import 'package:safe_send/core/services/transport/transfer_engine.dart';

/// A wired sender+receiver pair over in-process loopback (no server/device).
class EngineHarness {
  EngineHarness({Duration latency = Duration.zero}) {
    final (sc, rc) = LoopbackPeerConnector.pair(deliveryLatency: latency);
    final (ss, rs) = LoopbackSignalingChannel.pair();
    senderConnector = sc;
    receiverConnector = rc;
    senderSignaling = ss;
    receiverSignaling = rs;
    const config = AppConfig(flavor: AppFlavor.dev);
    sender = TransferEngine(sc, config);
    receiver = TransferEngine(rc, config);
  }

  late final LoopbackPeerConnector senderConnector;
  late final LoopbackPeerConnector receiverConnector;
  late final LoopbackSignalingChannel senderSignaling;
  late final LoopbackSignalingChannel receiverSignaling;
  late final TransferEngine sender;
  late final TransferEngine receiver;
}
