import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

// Password-encrypted local backup format (".cashew" files).
//
// Two format versions exist. New backups are always written as v2; both
// versions decrypt, so backups written by older builds keep working forever.
// The version is identified by the 8-byte ASCII magic prefix.
//
//   v1 "CASHEWE1"  (read-only, legacy)
//   v2 "CASHEWE2"  (current)
//
// Layout is identical for both — only the key derivation differs:
//
//   bytes 0..7      ASCII magic
//   bytes 8..23     KDF salt (16 bytes, random)
//   bytes 24..35    AES-GCM nonce (12 bytes, random)
//   bytes 36..n-17  ciphertext (the raw SQLite database)
//   last 16 bytes   AES-GCM MAC
//
// Key derivation:
//   v1  PBKDF2-HMAC-SHA256, 150k iterations, 256-bit key. Below OWASP's
//       current guidance of 600k for PBKDF2-HMAC-SHA256, which is why v2
//       exists. Retained only to decrypt existing backups.
//   v2  Argon2id, 64 MiB memory / 3 passes / parallelism 1, 256-bit key.
//       Memory-hard, so it resists GPU and ASIC attack in a way PBKDF2
//       fundamentally cannot at any iteration count.
//
// A wrong password fails MAC verification and throws
// SecretBoxAuthenticationError for either version.

const List<int> _magicBytesV1 = [
  0x43, 0x41, 0x53, 0x48, 0x45, 0x57, 0x45, 0x31 // "CASHEWE1"
];
const List<int> _magicBytesV2 = [
  0x43, 0x41, 0x53, 0x48, 0x45, 0x57, 0x45, 0x32 // "CASHEWE2"
];
const int _magicLength = 8;
const int _saltLength = 16;
const int _nonceLength = 12;
const int _macLength = 16;

// v1 (legacy read-only)
const int _pbkdf2Iterations = 150000;

// v2 (current). OWASP's Argon2id baseline of 46 MiB/1 pass is exceeded here
// because a database backup is encrypted rarely and interactively, so a few
// hundred milliseconds of derivation is an acceptable cost.
const int _argon2Memory = 65536; // in 1 KiB blocks == 64 MiB
const int _argon2Iterations = 3;
const int _argon2Parallelism = 1;

const int _keyLengthBytes = 32;

final AesGcm _cipher = AesGcm.with256bits();

Future<SecretKey> _deriveKeyV1(String password, List<int> salt) async {
  final Pbkdf2 pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: _keyLengthBytes * 8,
  );
  return await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
}

Future<SecretKey> _deriveKeyV2(String password, List<int> salt) async {
  final Argon2id argon2id = Argon2id(
    parallelism: _argon2Parallelism,
    memory: _argon2Memory,
    iterations: _argon2Iterations,
    hashLength: _keyLengthBytes,
  );
  return await argon2id.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
}

bool _startsWith(List<int> data, List<int> prefix) {
  if (data.length < prefix.length) return false;
  for (int i = 0; i < prefix.length; i++) {
    if (data[i] != prefix[i]) return false;
  }
  return true;
}

/// Whether [data] is any version of an encrypted Cashew backup.
bool isEncryptedBackupData(List<int> data) {
  return _startsWith(data, _magicBytesV2) || _startsWith(data, _magicBytesV1);
}

/// Encrypts [data] with [password], always using the current (v2) format.
Future<Uint8List> encryptBackupData(List<int> data, String password) async {
  final Random random = Random.secure();
  final List<int> salt =
      List<int>.generate(_saltLength, (_) => random.nextInt(256));

  final SecretKey key = await _deriveKeyV2(password, salt);
  final SecretBox box = await _cipher.encrypt(data, secretKey: key);

  final BytesBuilder out = BytesBuilder();
  out.add(_magicBytesV2);
  out.add(salt);
  out.add(box.nonce);
  out.add(box.cipherText);
  out.add(box.mac.bytes);
  return out.toBytes();
}

/// Decrypts a backup written by any format version.
///
/// Throws [SecretBoxAuthenticationError] on wrong password,
/// [FormatException] on malformed data.
Future<Uint8List> decryptBackupData(List<int> data, String password) async {
  final bool isV2 = _startsWith(data, _magicBytesV2);
  if (!isV2 && !_startsWith(data, _magicBytesV1)) {
    throw FormatException("Not an encrypted Cashew backup");
  }

  const int headerLength = _magicLength + _saltLength + _nonceLength;
  if (data.length < headerLength + _macLength) {
    throw FormatException("Encrypted backup is truncated");
  }

  final List<int> salt = data.sublist(_magicLength, _magicLength + _saltLength);
  final List<int> nonce =
      data.sublist(_magicLength + _saltLength, headerLength);
  final List<int> cipherText =
      data.sublist(headerLength, data.length - _macLength);
  final List<int> macBytes = data.sublist(data.length - _macLength);

  final SecretKey key = isV2
      ? await _deriveKeyV2(password, salt)
      : await _deriveKeyV1(password, salt);

  final List<int> clearText = await _cipher.decrypt(
    SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
    secretKey: key,
  );
  return Uint8List.fromList(clearText);
}

/// Encrypts using the legacy v1 format. Exposed for tests only, so that
/// backward compatibility can be verified against a genuinely v1-encoded
/// payload rather than a hand-assembled one.
Future<Uint8List> encryptBackupDataV1ForTesting(
    List<int> data, String password) async {
  final Random random = Random.secure();
  final List<int> salt =
      List<int>.generate(_saltLength, (_) => random.nextInt(256));

  final SecretKey key = await _deriveKeyV1(password, salt);
  final SecretBox box = await _cipher.encrypt(data, secretKey: key);

  final BytesBuilder out = BytesBuilder();
  out.add(_magicBytesV1);
  out.add(salt);
  out.add(box.nonce);
  out.add(box.cipherText);
  out.add(box.mac.bytes);
  return out.toBytes();
}
