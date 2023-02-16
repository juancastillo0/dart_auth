import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

Uint8List generateRandomBytes(
  int bytes, {
  Random? random,
}) {
  random ??= Random.secure();
  return Uint8List.fromList(
    List.generate(bytes, (index) => random!.nextInt(256)),
  );
}

class Decrypted {
  final String data;
  final String associatedData;

  const Decrypted({
    required this.data,
    required this.associatedData,
  });
}

class AES_GCM {
  AES_GCM({
    required Uint8List secretKey,
    Random? random,
  })  : _secretKeyBytes = secretKey,
        _random = random ?? Random.secure();

  final Uint8List _secretKeyBytes;
  final Random _random;

  static const ivByteLength = 12;
  static const macSize = 128;

  String encrypt(
    String data, {
    String? associatedData,
  }) {
    final cipher = GCMBlockCipher(AESEngine());
    final iv = generateRandomBytes(ivByteLength, random: _random);
    final associatedDataBytes =
        Uint8List.fromList(utf8.encode(associatedData ?? ''));

    final params = AEADParameters(
      KeyParameter(_secretKeyBytes),
      macSize,
      iv,
      associatedDataBytes,
    );
    cipher.init(true, params);

    final dataBytes = Uint8List.fromList(utf8.encode(data));
    final dataEncrypted = cipher.process(dataBytes);

    return jsonEncode({
      if (associatedData != null) 'meta': associatedData,
      'iv': base64Encode(iv),
      'enc': base64Encode(dataEncrypted),
    });
  }

  Decrypted decrypt(
    String data, {
    String? expectedAssociatedData,
  }) {
    final cipher = GCMBlockCipher(AESEngine());

    final obj = jsonDecode(data) as Map<String, Object?>;
    final iv = base64Decode(obj['iv'] as String);
    final associatedData =
        expectedAssociatedData ?? obj['meta'] as String? ?? '';
    final associatedDataBytes = Uint8List.fromList(utf8.encode(associatedData));

    final params = AEADParameters(
      KeyParameter(_secretKeyBytes),
      macSize,
      iv,
      associatedDataBytes,
    );
    cipher.init(false, params);

    final cipherText = base64Decode(obj['enc'] as String);
    final plainText = cipher.process(cipherText);

    return Decrypted(
      data: utf8.decode(plainText),
      associatedData: associatedData,
    );
  }
}

void main() {
  final secretKey = generateRandomBytes(32);
  print(base64Encode(secretKey));

  final aesGCM = AES_GCM(secretKey: secretKey);

  void test(String data, String associated) {
    final d = aesGCM.encrypt(data, associatedData: associated);
    print(d);
    final dOut = aesGCM.decrypt(d);
    print(dOut.data);
    print(dOut.associatedData);
  }

  test('data', '');
  test('data', '');
  test('data2', 'associated');
  test('data2', 'associated');
}
