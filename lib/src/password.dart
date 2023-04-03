import 'dart:convert' show base64;
import 'dart:isolate';
import 'dart:math' show Random;
import 'dart:typed_data' show Uint8List;

import 'package:argon2/argon2.dart';

Uint8List getRandomBytes([int length = 16]) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (i) => random.nextInt(256)),
  );
}

Future<String> hashPasswordFromIsolate(String password) async {
  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(_isolatePasswordTask, {
    'sendPort': receivePort.sendPort,
    'password': password,
  });
  final value = await receivePort.first as String;
  // assert((() => verifyPasswordFromHash(password, value))());
  isolate.kill();
  return value;
}

Future<bool> verifyPasswordFromIsolate(String password, String realHash) async {
  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(_isolatePasswordTask, {
    'sendPort': receivePort.sendPort,
    'password': password,
    'realHash': realHash,
  });
  final value = await receivePort.first as bool;
  // assert((() => verifyPasswordFromHash(password, realHash) == value)());
  isolate.kill();
  return value;
}

// coverage:ignore-start
void _isolatePasswordTask(Map<String, Object?> message) {
  final sendPort = message['sendPort']! as SendPort;
  final password = message['password']! as String;
  final realHash = message['realHash'] as String?;

  if (realHash != null) {
    final value = verifyPasswordFromHash(password, realHash);
    sendPort.send(value);
  } else {
    final value = hashFromPassword(password);
    sendPort.send(value);
  }
}
// coverage:ignore-end

String hashFromPassword(String password, {Argon2Parameters? params}) {
  final params0 = params ??
      Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        getRandomBytes(),
        memoryPowerOf2: 16,
        lanes: 2,
      );
  final argon2 = Argon2BytesGenerator();
  argon2.init(params0);

  final result = Uint8List(32);
  argon2.generateBytesFromString(password, result, 0, result.length);

  final encoded =
      '\$argon2${['d', 'i', 'id'][params0.type]}\$v=${params0.version}'
      '\$m=${params0.memory},t=${params0.iterations},p=${params0.lanes}'
      '\$${base64.encode(params0.salt).replaceAll('=', '')}'
      '\$${base64.encode(result).replaceAll('=', '')}';
  return encoded;
}

bool verifyPasswordFromHash(String password, String realHash) {
  try {
    final split = realHash.split(r'$');
    final version = int.parse(split[2].substring(2));
    final computeParams =
        split[3].split(',').map((v) => int.parse(v.substring(2))).toList();
    final saltStrUnPadded = split[4];
    final salt =
        base64.decode('$saltStrUnPadded${'=' * (saltStrUnPadded.length % 4)}');

    final parameters = Argon2Parameters(
      const {'d': 0, 'i': 1, 'id': 2}[split[1].substring(6)]!,
      salt,
      version: version,
      memory: computeParams[0],
      iterations: computeParams[1],
      lanes: computeParams[2],
    );
    final hash = hashFromPassword(password, params: parameters);

    return hash == realHash;
  } catch (_) {
    return false;
  }
}
