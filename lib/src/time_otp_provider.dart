import 'dart:convert' show base64UrlEncode, utf8;

import 'package:crypto/crypto.dart' show sha1;
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:otp/otp.dart';

class TimeOneTimePasswordProvider
    implements CredentialsProvider<TOTPCredentials, TOTPUser> {
  ///
  TimeOneTimePasswordProvider({
    required this.issuer,
    required this.persistence,
    this.providerId = ImplementedProviders.totp,
    this.config = const TOTPConfig(),
  });

  @override
  final String providerId;
  final String issuer;
  final Persistence persistence;
  final TOTPConfig config;

  @override
  Future<Result<CredentialsResponse<TOTPUser>, AuthError>> getUser(
    TOTPCredentials credentials,
  ) async {
    if (credentials.totp != null) {
      final state = credentials.state;
      if (state == null) {
        return const Err(AuthError.noState);
      }
      final stateModel = await persistence.getState(state);
      final base32Secret = stateModel?.meta?['base32Secret'];
      final providerUserId = stateModel?.meta?['providerUserId'];
      if (base32Secret is! String || providerUserId is! String) {
        return const Err(AuthError.invalidState);
      }

      final user = TOTPUser(
        base32Secret: base32Secret,
        providerUserId: providerUserId,
      );
      final result = await verifyCredentials(user, credentials);
      if (result.isErr()) return Err(result.unwrapErr());

      return Ok(
        CredentialsResponse.authenticated(
          AuthUser(
            emailIsVerified: false,
            phoneIsVerified: false,
            providerId: providerId,
            providerUser: user,
            providerUserId: providerUserId,
            rawUserData: user.toJson(),
          ),
        ),
      );
    } else {
      final state = generateStateToken();
      final base32Secret = OTP.randomSecret();
      final providerUserId = generateStateToken();
      await persistence.setState(
        state,
        AuthStateModel(
          createdAt: DateTime.now(),
          providerId: providerId,
          responseType: null,
          meta: {
            'base32Secret': base32Secret,
            'providerUserId': providerUserId,
          },
        ),
      );

      final query = Uri(
        queryParameters: {
          'secret': base32Secret,
          'issuer': issuer,
          ...config.toQueryParameters(),
        },
      ).query;

      final userId =
          base64UrlEncode(sha1.convert(utf8.encode(providerUserId)).bytes);
      final qrUrl =
          'otpauth://totp/${Uri.encodeComponent(issuer)}:${userId}?${query}';

      return Ok(
        CredentialsResponse.continueFlow(
          state: state,
          qrUrl: qrUrl,
          userMessage: 'Use the an authenticator application that supports'
              ' Time-Base One-Time Passwords (TOTP) such as'
              ' Google Authenticator, Twilio Authy or Microsoft Authenticator.'
              ' Setup key: "$base32Secret".',
          paramDescriptions: {
            'totp': ParamDescription(
              name: 'One Time Password Code',
              description: 'The code presented in your authenticator app.',
              regExp: RegExp('^[0-9]{${config.digits}}\$'),
            ),
          },
        ),
      );
    }
  }

  @override
  Map<String, ParamDescription>? get paramDescriptions => null;

  @override
  Result<TOTPCredentials, Map<String, FormatException>> parseCredentials(
    Map<String, Object?> json,
  ) {
    final totp = json['totp'];
    final state = json['state'];
    final providerUserId = json['providerUserId'];
    if ((totp is! String?) ||
        (state is! String?) ||
        (providerUserId is! String?)) {
      return Err({
        if (totp is! String?)
          'totp': const FormatException('totp should be a String'),
        if (state is! String?)
          'state': const FormatException('state should be a String'),
        if (providerUserId is! String?)
          'providerUserId':
              const FormatException('providerUserId should be a String'),
      });
    }

    return Ok(
      TOTPCredentials(
        totp: totp,
        state: state,
        providerUserId: providerUserId,
      ),
    );
  }

  @override
  Future<Result<Option<CredentialsResponse<TOTPUser>>, AuthError>>
      verifyCredentials(
    TOTPUser user,
    TOTPCredentials credentials,
  ) async {
    final code = OTP.generateTOTPCodeString(
      user.base32Secret,
      DateTime.now().millisecondsSinceEpoch,
      algorithm: config.algorithm,
      interval: config.period,
      isGoogle: config.isGoogle,
      length: config.digits,
    );

    if (credentials.totp != null &&
        OTP.constantTimeVerification(credentials.totp!, code)) {
      return const Ok(None());
    } else {
      return const Err(AuthError.invalidCode);
    }
  }
}

///
typedef TOTPAlgorithm = Algorithm;

class TOTPConfig {
  final int digits;
  final int period;
  final TOTPAlgorithm algorithm;
  final bool isGoogle;

  ///
  const TOTPConfig({
    this.digits = 6,
    this.period = 30,
    this.algorithm = TOTPAlgorithm.SHA1,
    this.isGoogle = true,
  });

  Map<String, String> toQueryParameters() {
    return {
      'digits': digits.toString(),
      'period': period.toString(),
      'algorithm': algorithm.name,
    };
  }
}

/// The input credentials for [TimeOneTimePasswordProvider]
class TOTPCredentials implements CredentialsData {
  /// Time-based one-time password
  final String? totp;

  /// The state key for [AuthStateModel]
  final String? state;

  /// The user id
  @override
  final String? providerUserId;

  /// The input credentials for [TimeOneTimePasswordProvider]
  TOTPCredentials({
    required this.totp,
    required this.state,
    required this.providerUserId,
  });
}

class TOTPUser implements SerializableToJson {
  final String base32Secret;
  final String providerUserId;

  ///
  TOTPUser({
    required this.base32Secret,
    required this.providerUserId,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'base32Secret': base32Secret,
      'providerUserId': providerUserId,
    };
  }
}
