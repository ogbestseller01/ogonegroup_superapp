// lib/services/e2ee_service.dart  (NEW, OPTIONAL — OFF by default)
//
// End-to-end encrypted TEXT messages. Private keys never leave the phone (Keychain/Keystore).
// Scheme: per message a random 256-bit key (AES-256-GCM) is wrapped separately for the receiver
// AND for the sender with X25519 + HKDF-SHA256 (ephemeral key per wrap). The server stores only
//   "e2ee1:" + base64(json)  in messages.content   (is_encrypted = 1).
//
// IMPORTANT — this is NOT the Signal protocol: no Double Ratchet, no prekeys, so no forward secrecy
// and no post-compromise security. Attachments are NOT encrypted yet. For real Signal-grade E2EE use
// `libsignal_protocol_dart` (community port) or libsignal via platform channels; the hooks below
// (encrypt before send / decrypt after receive) are exactly where it plugs in.
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class E2eeService {
  static const _prefix = 'e2ee1:';
  static const _store = FlutterSecureStorage();
  static final _x = X25519();
  static final _aes = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _info = utf8.encode('nearbyfundi-e2ee-v1');
  static final _salt = utf8.encode('nf-salt');

  final Map<int, SimplePublicKey> _peerKeys = {};
  SimpleKeyPairData? _me;

  static bool isEncrypted(String? c) => c != null && c.startsWith(_prefix);

  // ── keys ────────────────────────────────────────────────
  Future<SimpleKeyPairData> _identity() async {
    if (_me != null) return _me!;
    final priv = await _store.read(key: 'e2ee_priv');
    final pub = await _store.read(key: 'e2ee_pub');
    if (priv != null && pub != null) {
      return _me = SimpleKeyPairData(base64Decode(priv),
          publicKey: SimplePublicKey(base64Decode(pub), type: KeyPairType.x25519), type: KeyPairType.x25519);
    }
    final kp = await _x.newKeyPair();
    final d = await kp.extract();
    await _store.write(key: 'e2ee_priv', value: base64Encode(await d.extractPrivateKeyBytes()));
    await _store.write(key: 'e2ee_pub', value: base64Encode(d.publicKey.bytes));
    return _me = d;
  }

  Future<String> publicKeyB64() async => base64Encode((await _identity()).publicKey.bytes);

  /// Call once after login.
  Future<void> publishKey(Dio dio) async {
    await dio.post('/v14/chat/e2ee/key', data: {'identity_key': await publicKeyB64()});
  }

  Future<SimplePublicKey?> _peerKey(Dio dio, int userId) async {
    final cached = _peerKeys[userId];
    if (cached != null) return cached;
    try {
      final r = await dio.get('/v14/chat/e2ee/key/$userId');
      final k = r.data['data']['identity_key'] as String;
      return _peerKeys[userId] = SimplePublicKey(base64Decode(k), type: KeyPairType.x25519);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // peer has not enabled secure chat
      rethrow;
    }
  }

  Future<SecretKey> _kek(SimpleKeyPair mine, SimplePublicKey theirs) async {
    final shared = await _x.sharedSecretKey(keyPair: mine, remotePublicKey: theirs);
    return _hkdf.deriveKey(secretKey: shared, nonce: _salt, info: _info);
  }

  // ── encrypt / decrypt ───────────────────────────────────
  /// Returns null if the peer has no key yet (caller sends plaintext or blocks — your policy).
  Future<String?> encrypt(String plain, {required Dio dio, required int myId, required int peerId}) async {
    final peer = await _peerKey(dio, peerId);
    if (peer == null) return null;
    final me = await _identity();

    final msgKey = await _aes.newSecretKey();
    final body = await _aes.encrypt(utf8.encode(plain), secretKey: msgKey);
    final raw = await msgKey.extractBytes();

    Future<Map<String, String>> wrap(SimplePublicKey to) async {
      final eph = await _x.newKeyPair();
      final kek = await _kek(eph, to);
      final w = await _aes.encrypt(raw, secretKey: kek);
      return {
        'epk': base64Encode((await eph.extractPublicKey()).bytes),
        'n': base64Encode(w.nonce),
        'c': base64Encode(w.concatenation(nonce: false)),
      };
    }

    final env = {
      'v': 1,
      'n': base64Encode(body.nonce),
      'c': base64Encode(body.concatenation(nonce: false)),
      'k': {'$peerId': await wrap(peer), '$myId': await wrap(me.publicKey)},
    };
    return _prefix + base64Encode(utf8.encode(jsonEncode(env)));
  }

  /// Returns the plaintext, or null if it cannot be opened (e.g. new phone / lost key).
  Future<String?> decrypt(String payload, {required int myId}) async {
    if (!isEncrypted(payload)) return payload;
    try {
      final env = jsonDecode(utf8.decode(base64Decode(payload.substring(_prefix.length)))) as Map<String, dynamic>;
      final mine = (env['k'] as Map)['$myId'] as Map?;
      if (mine == null) return null;

      final me = await _identity();
      final kek = await _kek(me, SimplePublicKey(base64Decode(mine['epk']), type: KeyPairType.x25519));
      final wrapped = SecretBox.fromConcatenation(base64Decode(mine['c']),
          nonceLength: 0, macLength: 16);
      final rawKey = await _aes.decrypt(
        SecretBox(wrapped.cipherText, nonce: base64Decode(mine['n']), mac: wrapped.mac),
        secretKey: kek,
      );

      final b = SecretBox.fromConcatenation(base64Decode(env['c']), nonceLength: 0, macLength: 16);
      final plain = await _aes.decrypt(
        SecretBox(b.cipherText, nonce: base64Decode(env['n']), mac: b.mac),
        secretKey: SecretKey(rawKey),
      );
      return utf8.decode(plain);
    } catch (_) {
      return null;
    }
  }
}
