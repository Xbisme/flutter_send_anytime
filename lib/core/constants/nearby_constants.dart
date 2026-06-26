/// Constants for Nearby Radar mDNS discovery (#009). Centralized so the service
/// type and TXT keys have a single source of truth (Constitution VIII).
library;

/// mDNS/Bonjour service type advertised + browsed by Safe Send. Must match the
/// `NSBonjourServices` entry in iOS `Info.plist`.
const String kNearbyServiceType = '_safesend._tcp';

/// TXT record key carrying the payload version.
const String kNearbyTxtVersionKey = 'v';

/// TXT record key carrying the 6-digit #003 rendezvous code.
const String kNearbyTxtCodeKey = 'c';

/// Current TXT payload version (mirrors `ConnectLink` `v=1`).
const String kNearbyTxtVersion = '1';

/// Nominal port advertised with the service. Unused for the actual transfer
/// (the rendezvous happens over signaling) but required by the mDNS record.
const int kNearbyPort = 4567;
