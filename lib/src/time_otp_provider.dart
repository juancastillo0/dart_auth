import 'package:otp/otp.dart';

import '../flow.dart';
import '../oauth.dart';
import '../providers.dart';
import 'backend_translation.dart';

class TimeOneTimePasswordProvider
    implements CredentialsProvider<TOTPCredentials, TOTPUser> {
  ///
  TimeOneTimePasswordProvider({
    required this.issuer,
    required this.persistence,
    this.providerId = ImplementedProviders.totp,
    this.config = const TOTPConfig(),
    this.createFlowUserMessage,
    ParamDescription? totpDescription,
  }) : totpDescription = totpDescription ??
            ParamDescription(
              name: const Translation(key: Translations.totpNameKey),
              description:
                  const Translation(key: Translations.totpDescriptionKey),
              regExp: RegExp('^[0-9]{${config.digits}}\$'),
              keyboardType: ParamKeyboardType.number,
            );

  @override
  final String providerId;
  final String issuer;
  final Persistence persistence;
  final TOTPConfig config;
  final Translation Function({required String base32Secret})?
      createFlowUserMessage;
  // TODO: allow sign in with providerUserId

  final ParamDescription totpDescription;
  Map<String, ParamDescription> get initiatedFlowParamDescriptions =>
      {'totp': totpDescription};

  @override
  Map<String, ParamDescription>? get paramDescriptions => null;

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
      final base32Secret = OTP.randomSecret();
      final providerUserId = generateStateToken(size: 21);
      final saved = await _saveState(
        base32Secret: base32Secret,
        providerUserId: providerUserId,
      );
      final state = saved.state;

      final query = Uri(
        queryParameters: {
          'secret': base32Secret,
          'issuer': issuer,
          ...config.toQueryParameters(),
        },
      ).query;

      // final userId =
      //     base64UrlEncode(sha1.convert(utf8.encode(providerUserId)).bytes);
      final userId = providerUserId;
      final qrUrl =
          'otpauth://totp/${Uri.encodeComponent(issuer)}:${userId}?${query}';

      return Ok(
        CredentialsResponse.continueFlow(
          ResponseContinueFlow(
            state: state,
            qrUrl: qrUrl,
            userMessage:
                createFlowUserMessage?.call(base32Secret: base32Secret) ??
                    Translation(
                      key: Translations.totpCreateFlowKey,
                      args: {'base32Secret': base32Secret},
                    ),
            paramDescriptions: initiatedFlowParamDescriptions,
          ),
        ),
      );
    }
  }

  @override
  Result<TOTPCredentials, Map<String, Translation>> parseCredentials(
    Map<String, Object?> json,
  ) {
    final totp = json['totp'];
    final state = json['state'];
    final providerUserId = json['providerUserId'];
    if ((totp is! String?) ||
        (state is! String?) ||
        (providerUserId is! String?)) {
      return Err(
        Map.fromEntries(
          [
            if (totp is! String?) 'totp',
            if (state is! String?) 'state',
            if (providerUserId is! String?) 'providerUserId',
          ].map(
            (e) => MapEntry(
              e,
              Translation(
                key: Translations.requiredStringArgumentKey,
                args: {'name': e},
              ),
            ),
          ),
        ),
      );
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

  Future<AuthStateModel> _saveState({
    required String base32Secret,
    required String providerUserId,
  }) async {
    final state = generateStateToken();
    final model = AuthStateModel(
      state: state,
      createdAt: DateTime.now(),
      providerId: providerId,
      responseType: null,
      meta: {
        'base32Secret': base32Secret,
        'providerUserId': providerUserId,
      },
    );
    await persistence.setState(state, model);

    return model;
  }

  @override
  Future<ResponseContinueFlow?> mfaCredentialsFlow(
    ProviderUserId mfaItem,
  ) async {
    // final state = await saveState(user);
    return ResponseContinueFlow(
      state: null,
      // TODO: Should we send providerUserId to the client?
      userMessage: Translation(
        key: Translations.totpAuthenticateFlowKey,
        args: {'providerUserId': mfaItem.providerUserId},
      ),
      paramDescriptions: initiatedFlowParamDescriptions,
    );
  }

  @override
  Future<Result<CredentialsResponse<TOTPUser>, AuthError>> updateCredentials(
    TOTPUser user,
    TOTPCredentials credentials,
  ) async {
    return Err(
      AuthError(
        error: 'unsupported',
        message:
            'Can not update credentials for ${TimeOneTimePasswordProvider}',
      ),
    );
  }

  @override
  ResponseContinueFlow? updateCredentialsParams(TOTPUser user) {
    return null;
  }

  @override
  AuthUser<TOTPUser> parseUser(Map<String, Object?> userData) {
    final user = TOTPUser.fromJson(userData);
    return AuthUser(
      emailIsVerified: false,
      phoneIsVerified: false,
      providerId: providerId,
      providerUser: user,
      providerUserId: user.providerUserId,
      rawUserData: userData,
    );
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

  factory TOTPUser.fromJson(Map<String, Object?> json) {
    return TOTPUser(
      base32Secret: json['base32Secret']! as String,
      providerUserId: json['providerUserId']! as String,
    );
  }
}
