import 'package:budget/struct/encryptedBackup.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encryptedBackup', () {
    final List<int> sample =
        List<int>.generate(4096, (i) => (i * 31 + 7) % 256);

    test('round-trips data with correct password', () async {
      final encrypted = await encryptBackupData(sample, "hunter2");
      expect(isEncryptedBackupData(encrypted), isTrue);
      // Ciphertext must not contain the plaintext as-is
      expect(encrypted.length, greaterThan(sample.length));
      final decrypted = await decryptBackupData(encrypted, "hunter2");
      expect(decrypted, equals(sample));
    });

    test('wrong password fails authentication', () async {
      final encrypted = await encryptBackupData(sample, "correct password");
      expect(
        () => decryptBackupData(encrypted, "wrong password"),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('tampered ciphertext fails authentication', () async {
      final encrypted = await encryptBackupData(sample, "pw");
      final tampered = List<int>.from(encrypted);
      tampered[40] = tampered[40] ^ 0xFF;
      expect(
        () => decryptBackupData(tampered, "pw"),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('plain data is not detected as encrypted backup', () {
      expect(isEncryptedBackupData([1, 2, 3, 4, 5, 6, 7, 8, 9]), isFalse);
      expect(isEncryptedBackupData([]), isFalse);
    });

    test('salt differs between exports (unique ciphertexts)', () async {
      final a = await encryptBackupData(sample, "pw");
      final b = await encryptBackupData(sample, "pw");
      expect(a, isNot(equals(b)));
    });

    test('malformed data throws FormatException', () {
      expect(
        () => decryptBackupData([1, 2, 3], "pw"),
        throwsA(isA<FormatException>()),
      );
    });

    test('new backups are written in the v2 (Argon2id) format', () async {
      final encrypted = await encryptBackupData(sample, "pw");
      expect(
        String.fromCharCodes(encrypted.sublist(0, 8)),
        equals("CASHEWE2"),
      );
    });

    group('backward compatibility with v1 (PBKDF2) backups', () {
      // The whole point of versioning the magic bytes: a user restoring a
      // backup taken before the KDF upgrade must still get their data back.

      test('v1 backup is still recognised as an encrypted backup', () async {
        final legacy = await encryptBackupDataV1ForTesting(sample, "pw");
        expect(
          String.fromCharCodes(legacy.sublist(0, 8)),
          equals("CASHEWE1"),
        );
        expect(isEncryptedBackupData(legacy), isTrue);
      });

      test('v1 backup still decrypts with the correct password', () async {
        final legacy = await encryptBackupDataV1ForTesting(sample, "hunter2");
        final decrypted = await decryptBackupData(legacy, "hunter2");
        expect(decrypted, equals(sample));
      });

      test('v1 backup rejects the wrong password', () async {
        final legacy = await encryptBackupDataV1ForTesting(sample, "right");
        expect(
          () => decryptBackupData(legacy, "wrong"),
          throwsA(isA<SecretBoxAuthenticationError>()),
        );
      });

      test('v1 and v2 of the same payload derive different keys', () async {
        // Guards against a future refactor accidentally routing v1 payloads
        // through the v2 KDF, which would silently break every old backup.
        final legacy = await encryptBackupDataV1ForTesting(sample, "pw");
        final current = await encryptBackupData(sample, "pw");
        expect(legacy.sublist(0, 8), isNot(equals(current.sublist(0, 8))));
        expect(await decryptBackupData(legacy, "pw"), equals(sample));
        expect(await decryptBackupData(current, "pw"), equals(sample));
      });
    });
  });
}
