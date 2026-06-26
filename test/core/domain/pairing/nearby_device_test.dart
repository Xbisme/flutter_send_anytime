import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/constants/nearby_constants.dart';
import 'package:safe_send/core/domain/pairing/nearby_device.dart';

void main() {
  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  group('NearbyDevice TXT codec (#009)', () {
    test('toTxt → codeFromTxt round-trips a valid code', () {
      final txt = NearbyDevice.toTxt(code: '042815');
      expect(txt[kNearbyTxtVersionKey], bytes(kNearbyTxtVersion));
      expect(NearbyDevice.codeFromTxt(txt), '042815');
    });

    test('null txt → null', () {
      expect(NearbyDevice.codeFromTxt(null), isNull);
    });

    test('unsupported version → null', () {
      final txt = <String, Uint8List?>{
        kNearbyTxtVersionKey: bytes('2'),
        kNearbyTxtCodeKey: bytes('042815'),
      };
      expect(NearbyDevice.codeFromTxt(txt), isNull);
    });

    test('missing version → null', () {
      final txt = <String, Uint8List?>{kNearbyTxtCodeKey: bytes('042815')};
      expect(NearbyDevice.codeFromTxt(txt), isNull);
    });

    test('invalid (non-6-digit) code → null', () {
      final txt = <String, Uint8List?>{
        kNearbyTxtVersionKey: bytes(kNearbyTxtVersion),
        kNearbyTxtCodeKey: bytes('abc'),
      };
      expect(NearbyDevice.codeFromTxt(txt), isNull);
    });

    test('missing code → null', () {
      final txt = <String, Uint8List?>{
        kNearbyTxtVersionKey: bytes(kNearbyTxtVersion),
      };
      expect(NearbyDevice.codeFromTxt(txt), isNull);
    });
  });
}
