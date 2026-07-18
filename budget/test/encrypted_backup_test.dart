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
  });
}
