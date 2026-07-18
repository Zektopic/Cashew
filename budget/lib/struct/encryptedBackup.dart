import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

// Password-encrypted local backup format (".cashew" files):
//
//   bytes 0..7    ASCII magic "CASHEWE1"
//   bytes 8..23   PBKDF2 salt (16 bytes, random)
//   bytes 24..35  AES-GCM nonce (12 bytes, random)
//   bytes 36..n-17  ciphertext (the raw SQLite database)
//   last 16 bytes  AES-GCM MAC
//
// Key derivation: PBKDF2-HMAC-SHA256, 150k iterations, 256-bit key.
// A wrong password fails MAC verification and throws SecretBoxAuthenticationError.

const List<int> _magicBytes = [0x43, 0x41, 0x53, 0x48, 0x45, 0x57, 0x45, 0x31];
const int _saltLength = 16;
const int _nonceLength = 12;
const int _macLength = 16;
const int _pbkdf2Iterations = 150000;

final AesGcm _cipher = AesGcm.with256bits();

Future<SecretKey> _deriveKey(String password, List<int> salt) async {
  final Pbkdf2 pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: 256,
  );
  return await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
}

bool isEncryptedBackupData(List<int> data) {
  if (data.length < _magicBytes.length) return false;
  for (int i = 0; i < _magicBytes.length; i++) {
    if (data[i] != _magicBytes[i]) return false;
  }
  return true;
}

Future<Uint8List> encryptBackupData(List<int> data, String password) async {
  final Random random = Random.secure();
  final List<int> salt =
      List<int>.generate(_saltLength, (_) => random.nextInt(256));

  final SecretKey key = await _deriveKey(password, salt);
  final SecretBox box = await _cipher.encrypt(data, secretKey: key);

  final BytesBuilder out = BytesBuilder();
  out.add(_magicBytes);
  out.add(salt);
  out.add(box.nonce);
  out.add(box.cipherText);
  out.add(box.mac.bytes);
  return out.toBytes();
}

/// Throws [SecretBoxAuthenticationError] on wrong password,
/// [FormatException] on malformed data.
Future<Uint8List> decryptBackupData(List<int> data, String password) async {
  if (!isEncryptedBackupData(data)) {
    throw FormatException("Not an encrypted Cashew backup");
  }
  final int headerLength = _magicBytes.length + _saltLength + _nonceLength;
  if (data.length < headerLength + _macLength) {
    throw FormatException("Encrypted backup is truncated");
  }
  final List<int> salt =
      data.sublist(_magicBytes.length, _magicBytes.length + _saltLength);
  final List<int> nonce = data.sublist(
      _magicBytes.length + _saltLength, headerLength);
  final List<int> cipherText =
      data.sublist(headerLength, data.length - _macLength);
  final List<int> macBytes = data.sublist(data.length - _macLength);

  final SecretKey key = await _deriveKey(password, salt);
  final List<int> clearText = await _cipher.decrypt(
    SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
    secretKey: key,
  );
  return Uint8List.fromList(clearText);
}
