import 'dart:convert' show base64Encode, base64UrlEncode, utf8;
import 'dart:math' show Random;

import 'package:crypto/crypto.dart' show sha256;

/// Create an anti-forgery state token
String generateStateToken({int size = 48, Random? random}) {
  final r = random ?? Random.secure();
  return base64Encode(List.generate(size, (_) => r.nextInt(8)));
}

enum CodeChallengeMethod {
  plain,
  S256,
}

class CodeChallenge {
  ///
  const CodeChallenge({
    required this.codeVerifier,
    required this.codeChallenge,
    required this.codeChallengeMethod,
  });

  factory CodeChallenge.generateS256({int size = 128, Random? random}) {
    final r = random ?? Random.secure();
    final codeVerifier = String.fromCharCodes(
      Iterable.generate(
        size,
        (_) => codeVerifierVocabulary.codeUnitAt(
          r.nextInt(codeVerifierVocabulary.length),
        ),
      ),
    );
    final codeChallenge =
        base64UrlEncode(sha256.convert(utf8.encode(codeVerifier)).bytes)
            .replaceAll('=', '');
    return CodeChallenge(
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      codeChallengeMethod: CodeChallengeMethod.S256,
    );
  }

  /// In order to generate the code_challenge, your app should hash the
  /// code verifier using the SHA256 algorithm.
  /// The code verifier is a random string between 43 and 128 characters in length.
  /// It can contain letters, digits, underscores, periods, hyphens, or tildes.
  static const codeVerifierVocabulary =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-~';

  @override
  final String codeVerifier;
  @override
  final String codeChallenge;
  @override
  final CodeChallengeMethod codeChallengeMethod;
}
