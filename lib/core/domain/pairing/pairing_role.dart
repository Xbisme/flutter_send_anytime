/// Which side of a pairing this device is. The sender generates the 6-digit
/// code; the receiver enters it (#003).
enum PairingRole {
  /// Generates the code and waits for a peer (the WebRTC offerer).
  sender,

  /// Enters the code to join the sender's room (the WebRTC answerer).
  receiver,
}
