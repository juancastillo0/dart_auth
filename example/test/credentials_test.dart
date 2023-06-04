import 'dart:convert';

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/front_end_client.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/main.dart';
import 'package:oauth_example/persistence.dart';
import 'package:otp/otp.dart';
import 'package:test/test.dart';

import 'endpoint_test.dart';

class InMemoryClientPersistence extends ClientPersistence {
  ///
  InMemoryClientPersistence({
    this.prefix,
    Map<String, String>? map,
  }) : map = map ?? {};
  final String? prefix;

  final Map<String, String> map;

  String makeKey(String suffix) => prefix == null ? suffix : '$prefix:$suffix';

  @override
  String? read(String key) => map[makeKey(key)];
  @override
  void write(String key, String value) => map[makeKey(key)] = value;
  @override
  void delete(String key) => map.remove(makeKey(key));
}

Object? jsonEncDec(Object? obj) {
  return jsonDecode(jsonEncode(obj));
}

void main() {
  final persistence = InMemoryPersistance();
  final jwtMaker = JsonWebTokenMaker(
    // TODO:
    base64Key: generateStateToken(),
    issuer: Uri.parse('oauth_example_test'),
    userFromClaims: (claims) => claims,
  );

  group('auth handler', timeout: const Timeout(Duration(seconds: 60)), () {
    late Config config;
    final client = HttpClient();
    late Uri url;
    late GlobalState globalState;
    late AuthState authState;
    late InMemoryClientPersistence clientPersistence;

    final magicCodes = <String, String>{};

    final credentialsProviders = <String, CredentialsProvider>{
      ImplementedProviders.username: UsernamePasswordProvider(),
      'phone_no_password': IdentifierPasswordProvider.phone(
        providerId: 'phone_no_password',
        magicCodeConfig: MagicCodeConfig(
          onlyMagicCodeNoPassword: true,
          sendMagicCode: ({required identifier, required magicCode}) async {
            print('MAGIC_CODE phone_no_password: $identifier $magicCode');
            magicCodes[identifier] = magicCode;
            return const Ok(unit);
          },
          persistence: persistence,
        ),
      ),
      ImplementedProviders.email: IdentifierPasswordProvider.email(
        magicCodeConfig: MagicCodeConfig(
          onlyMagicCodeNoPassword: false,
          sendMagicCode: ({required identifier, required magicCode}) async {
            print('MAGIC_CODE email: $identifier $magicCode');
            magicCodes[identifier] = magicCode;
            return const Ok(unit);
          },
          persistence: persistence,
        ),
      ),
      ImplementedProviders.totp: TimeOneTimePasswordProvider(
        issuer: 'oauth_example',
        persistence: persistence,
      )
    };

    setUpAll(() async {
      config = Config(
        allOAuthProviders: {},
        allCredentialsProviders: credentialsProviders,
        persistence: persistence,
        baseRedirectUri: 'http://localhost:8080/base',
        jwtMaker: jwtMaker,
      );
      final server = await startServer(config, host: 'localhost', port: 0);
      url = Uri.parse('http://${server.address.host}:${server.port}');
    });

    setUp(() async {
      clientPersistence = InMemoryClientPersistence();
      globalState = await GlobalState.load(
        persistence: clientPersistence,
        baseUrl: url.toString(),
      );
      authState = globalState.authState;
    });

    // TODO: test from seeded persistence

    group('oauth/providers endpoint', () {
      test('GET oauth/providers', () async {
        final response = await client.get(url.replace(path: 'oauth/providers'));
        expect(response.headers, jsonHeaderMatcher);
        expect(response.statusCode, 200);
        expect(
          jsonDecode(response.body),
          jsonEncDec({
            'providers': <dynamic>[],
            'credentialsProviders': credentialsProviders.values
                .map(CredentialsProviderData.fromProvider)
                .toList()
          }),
        );
      });

      test('GET oauth/providers globalState', () async {
        final response = await authState.getProviders();
        expect(
          jsonEncDec(response),
          {
            'providers': <dynamic>[],
            'credentialsProviders': jsonEncDec(
              credentialsProviders.values
                  .map(CredentialsProviderData.fromProvider)
                  .toList(),
            )
          },
        );
      });
    });

    void validateSuccessLogIn(
      AuthResponse? result,
      Map<String, Object?> userInfo,
    ) {
      expect(result?.error, isNull);
      expect(result?.credentials, isNull);
      final data = result!.success!;
      expect(data.refreshToken, isNotNull);
      expect(data.leftMfaItems == null || data.leftMfaItems!.isEmpty, true);

      expect(
        clientPersistence.map,
        {AuthState.persistenceTokenKey: jsonEncode(data)},
      );
      expect(authState.authenticatedClient.value, isNotNull);
      // TODO: rename isInOAuthFlow
      expect(authState.isInFlow, false);
      final info = authState.userInfo.value!;
      expect(jsonEncDec(info), userInfo);
      // TODO: test sessions
    }

    Map<String, Object?> usernameAuthUser(String username) {
      return {
        'authUser': {
          'providerId': 'username',
          'providerUserId': username,
          'emailIsVerified': false,
          'phoneIsVerified': false,
          'username': username,
          // TODO: remove this info
          'passwordHash': isA<String>(),
          // r'$argon2id$v=19$m=65536,t=3,p=2$HU76B5RUlYHcU5tS88QEMg$If7ioKrQY1SLExE3qkvoJ0XVluT0V0biGIyL3jmiiwY'
        },
        'providerName': {
          'key': 'usernameProviderName',
          'msg': 'Username and Password'
        },
        'updateParams': {
          'userMessage': {'key': ''},
          // TODO: maybe dont validate this
          'paramDescriptions': {
            'username': {
              'name': {'key': 'usernameName', 'msg': 'Username'},
              'description': {
                'key': 'usernameDescription',
                'msg': 'Alphanumeric username with at least 3 characters.'
                    ' This will be your identifier to sign in.'
              },
              'regExp': r'^[a-zA-Z0-9_-]{3,}$',
              'required': false,
              'initialValue': username,
              'readOnly': false,
              'obscureText': false,
              'keyboardType': 'text',
              'textCapitalization': 'none'
            },
            'password': {
              'name': {'key': 'passwordName', 'msg': 'Password'},
              'description': {
                'key': 'passwordDescription',
                'msg': 'Should be at least 8 characters.'
              },
              'regExp': r'[\s\S]{8,}',
              'required': false,
              'readOnly': false,
              'obscureText': true,
              'keyboardType': 'text',
              'textCapitalization': 'none'
            }
          }
        }
      };
    }

    group('username and password', () {
      test('sign up username', () async {
        final result = await authState.signUpWithCredentials(
          CredentialsParams(
            ImplementedProviders.username,
            {
              'username': 'uss',
              'password': 'password',
            },
          ),
        );
        final claims = await config.jwtMaker
            .getUserClaimsFromToken(result!.success!.accessToken);
        final userInfo = {
          'user': {
            'userId': claims!.userId,
            // 'name': name,
            // 'picture': picture,
            // 'email': email,
            'emailIsVerified': false,
            // 'phone': phone,
            'phoneIsVerified': false,
            'multiFactorAuth': MFAConfig.empty.toJson(),
            // TODO:
            'createdAt': isA<String>(),
          },
          'authUsers': [usernameAuthUser('uss')],
        };

        validateSuccessLogIn(result, userInfo);

        await authState.signOut();
        expect(authState.userInfo.value, isNull);
        expect(authState.authenticatedClient.value, isNull);

        final signIn = await authState.signInWithCredentials(
          CredentialsParams(
            ImplementedProviders.username,
            {
              'username': 'uss',
              'password': 'password2',
            },
          ),
        );
        expect(signIn!.error!.error.key, Translations.invalidPasswordKey);
        expect(signIn.error!.error.msg, 'Invalid credentials');
        expect(signIn.error!.otherErrors, isNull);
        // TODO: should we send this?
        expect(signIn.error!.message, 'Invalid credentials');

        final signIn2 = await authState.signInWithCredentials(
          CredentialsParams(
            ImplementedProviders.username,
            {
              'username': 'uss',
              'password': 'password',
            },
          ),
        );
        validateSuccessLogIn(signIn2, userInfo);

        final deleteResult = await authState.deleteAuthProvider(
          const ProviderUserId(
            providerId: ImplementedProviders.username,
            providerUserId: 'uss',
          ),
        );
        expect(
          deleteResult!.response!.error!.error.key,
          Translations.canNotDeleteOnlyProviderKey,
        );
      });
    });

    group('email, phone and identifier', () {
      test('email, phone MFA', () async {
        const userEmail = 'email@example.com';
        const userPhone = '1111111111';
        const emailParameters = {
          'userMessage': {'key': ''},
          // TODO: maybe dont validate this
          'paramDescriptions': {
            'email': {
              'name': {'key': 'emailName', 'msg': 'Email'},
              'description': {
                'key': 'emailDescription',
                'msg':
                    'The email address. This will be your identifier to sign in.'
              },
              'regExp': '@',
              'required': false,
              'initialValue': userEmail,
              'readOnly': false,
              'obscureText': false,
              'keyboardType': 'emailAddress',
              'textCapitalization': 'none'
            },
            'password': {
              'name': {'key': 'passwordName', 'msg': 'Password'},
              'description': {
                'key': 'passwordDescription',
                'msg': 'Should be at least 8 characters.'
              },
              'regExp': r'[\s\S]{8,}',
              'required': false,
              'readOnly': false,
              'obscureText': true,
              'keyboardType': 'text',
              'textCapitalization': 'none'
            }
          }
        };
        const phoneParamDescription = {
          'phone': {
            'name': {'key': 'phoneName', 'msg': 'Phone'},
            'description': {
              'key': 'phoneDescription',
              'msg':
                  'The phone number. This will be your identifier to sign in.'
            },
            'regExp': r'^[0-9]{7,}$',
            'required': false,
            'initialValue': userPhone,
            'readOnly': false,
            'obscureText': false,
            'keyboardType': 'phone',
            'textCapitalization': 'none'
          },
        };
        const phoneParameters = {
          'userMessage': {'key': ''},
          // TODO: maybe dont validate this
          'paramDescriptions': phoneParamDescription
        };
        final result = await authState.signUpWithCredentials(
          CredentialsParams(
            ImplementedProviders.email,
            {'email': userEmail, 'password': 'password'},
          ),
        );

        // Verify email
        expect(result!.success, isNull);
        expect(result.error, isNull);

        // TODO: maybe use toJson?
        expect(
          result.credentials!.paramDescriptions!.keys,
          ['magicCode'],
        );
        expect(
          result.credentials!.userMessage.key,
          Translations.magicCodeSentKey,
        );
        final result2 = await authState.signUpWithCredentials(
          CredentialsParams(
            ImplementedProviders.email,
            {
              'state': result.credentials!.state,
              'magicCode': 'invalid',
              'email': userEmail,
            },
          ),
        );
        expect(result2!.error!.error.key, Translations.invalidCodeKey);

        final result3 = await authState.signUpWithCredentials(
          CredentialsParams(
            ImplementedProviders.email,
            {
              'state': result.credentials!.state,
              'magicCode': magicCodes[userEmail],
              'email': userEmail,
            },
          ),
        );

        final claims = await config.jwtMaker
            .getUserClaimsFromToken(result3!.success!.accessToken);
        final userInfo = {
          'user': {
            'userId': claims!.userId,
            // 'name': name,
            // 'picture': picture,
            'email': userEmail,
            'emailIsVerified': true,
            // 'phone': phone,
            'phoneIsVerified': false,
            'multiFactorAuth': MFAConfig.empty.toJson(),
            // TODO:
            'createdAt': isA<String>(),
          },
          'authUsers': [
            {
              'authUser': {
                'providerId': 'email',
                'providerUserId': userEmail,
                'emailIsVerified': true,
                'phoneIsVerified': false,
                'email': userEmail,
                // TODO: remove this info
                'passwordHash': isA<String>(),
                // r'$argon2id$v=19$m=65536,t=3,p=2$HU76B5RUlYHcU5tS88QEMg$If7ioKrQY1SLExE3qkvoJ0XVluT0V0biGIyL3jmiiwY'
              },
              'providerName': {'key': 'emailProviderName', 'msg': 'Email'},
              'updateParams': emailParameters,
            },
          ],
        };
        validateSuccessLogIn(result3, userInfo);

        final dateBefore = DateTime.now();
        await authState.signOut();
        // TODO: validate session and previous refresh token
        final sessions = await persistence.getUserSessions(
          claims.userId,
          onlyValid: false,
        );
        expect(sessions, hasLength(1));
        expect(sessions.first.isValid, false);
        expect(
          sessions.first.endedAt,
          predicate((p0) => dateBefore.isBefore(p0! as DateTime)),
        );
        expect(clientPersistence.map, isEmpty);
        expect(authState.userInfo.value, isNull);
        expect(authState.authenticatedClient.value, isNull);

        final signIn = await authState.signInWithCredentials(
          CredentialsParams(
            ImplementedProviders.email,
            {
              'email': userEmail,
              'password': 'password2',
            },
          ),
        );
        // TODO: test fieldError
        expect(signIn!.error!.error.key, Translations.invalidPasswordKey);
        expect(signIn.error!.error.msg, 'Invalid credentials');
        expect(signIn.error!.otherErrors, isNull);
        // TODO: should this be null? maybe delete message?
        expect(signIn.error!.message, 'Invalid credentials');

        final signIn2 = await authState.signInWithCredentials(
          CredentialsParams(
            ImplementedProviders.email,
            {
              'email': userEmail,
              'password': 'password',
            },
          ),
        );
        validateSuccessLogIn(signIn2, userInfo);

        final deleteResult = await authState.deleteAuthProvider(
          const ProviderUserId(
            providerId: ImplementedProviders.username,
            providerUserId: 'uss',
          ),
        );
        expect(
          deleteResult!.response!.error!.error.key,
          Translations.authProviderNotFoundToDeleteKey,
        );

        authState.addMFAProvider();
        expect(authState.isAddingMFAProvider.value, true);

        const phoneProviderId = 'phone_no_password';

        // TODO: separate add MFA provider
        final phoneFlow = await authState.signUpWithCredentials(
          CredentialsParams(
            phoneProviderId,
            {'phone': userPhone},
          ),
        );

        final resultNoCode = await authState.signUpWithCredentials(
          CredentialsParams(
            phoneProviderId,
            {
              'state': phoneFlow!.credentials!.state,
              'phone': userPhone,
            },
          ),
        );
        expect(resultNoCode!.error!.error.key, Translations.invalidCodeKey);
        final resultNoState = await authState.signUpWithCredentials(
          CredentialsParams(
            phoneProviderId,
            {
              'magicCode': magicCodes[userPhone],
              'phone': userPhone,
            },
          ),
        );
        expect(resultNoState!.error!.error.key, Translations.noStateKey);

        final resultOk = await authState.signUpWithCredentials(
          CredentialsParams(
            phoneProviderId,
            {
              'state': phoneFlow.credentials!.state,
              'magicCode': magicCodes[userPhone],
              'phone': userPhone,
            },
          ),
        );
        expect(authState.isAddingMFAProvider.value, false);
        final userInfoWithPhone = {
          'user': {
            'userId': claims.userId,
            // 'name': name,
            // 'picture': picture,
            'email': userEmail,
            'emailIsVerified': true,
            'phone': userPhone,
            'phoneIsVerified': true,
            'multiFactorAuth': {
              'requiredItems': [
                {
                  'providerId': 'email',
                  'providerUserId': userEmail,
                },
                {
                  'providerId': phoneProviderId,
                  'providerUserId': userPhone,
                },
              ],
              'optionalCount': 0,
              'optionalItems': <dynamic>[],
            },
            // TODO:
            'createdAt': isA<String>(),
          },
          'authUsers': [
            {
              'authUser': {
                'providerId': 'email',
                'providerUserId': userEmail,
                'emailIsVerified': true,
                'phoneIsVerified': false,
                'email': userEmail,
                // TODO: remove this info
                'passwordHash': isA<String>(),
                // r'$argon2id$v=19$m=65536,t=3,p=2$HU76B5RUlYHcU5tS88QEMg$If7ioKrQY1SLExE3qkvoJ0XVluT0V0biGIyL3jmiiwY'
              },
              'providerName': {'key': 'emailProviderName', 'msg': 'Email'},
              'updateParams': emailParameters,
            },
            {
              'authUser': {
                'providerId': phoneProviderId,
                'providerUserId': userPhone,
                'emailIsVerified': false,
                'phoneIsVerified': true,
                'phone': userPhone,
              },
              'providerName': {'key': 'phoneProviderName', 'msg': 'Phone'},
              'updateParams': {
                // TODO: should it be?
                // 'userMessage': {
                //   'key': Translations.magicCodeHelperTextKey,
                //   'msg': 'A magic code will be sent to the device'
                // },
                'userMessage': {'key': ''},
                'paramDescriptions': phoneParamDescription
              },
            },
          ],
        };
        validateSuccessLogIn(resultOk, userInfoWithPhone);

        await authState.signOut();
        expect(authState.userInfo.value, isNull);

        final mfa1 = await authState.signInWithCredentials(
          CredentialsParams(
            ImplementedProviders.email,
            {'email': userEmail, 'password': 'password'},
          ),
        );
        final mfaSuccess = mfa1!.success!;
        expect(
          jsonEncDec(mfaSuccess.leftMfaItems),
          [
            jsonEncDec({
              'mfa': {
                'providerId': phoneProviderId,
                'providerUserId': userPhone,
              },
              'credentialsInfo': {
                'userMessage': {
                  'key': Translations.magicCodeHelperTextKey,
                  'msg': 'A magic code will be sent to the device'
                },
                'paramDescriptions': {
                  'phone': {
                    'name': {'key': 'phoneName', 'msg': 'Phone'},
                    'description': {
                      'key': 'phoneDescription',
                      'msg':
                          'The phone number. This will be your identifier to sign in.'
                    },
                    'regExp': r'^[0-9]{7,}$',
                    'required': false,
                    'readOnly': false,
                    'obscureText': false,
                    'keyboardType': 'phone',
                    'textCapitalization': 'none'
                  }
                }
              }
              // phoneFlow,
            }),
          ],
        );

        final mfaNoProvider = await authState.signInWithCredentials(
          CredentialsParams(phoneProviderId, {'phone': userPhone}),
        );
        expect(
          mfaNoProvider!.error!.error.key,
          Translations.wrongParametersForMFAKey,
        );

        final mfa2 = await authState.signInWithCredentials(
          CredentialsParams(phoneProviderId, {
            'phone': userPhone,
            'providerUserId': userPhone,
          }),
        );
        expect(mfa2!.credentials!.paramDescriptions!.keys, ['magicCode']);

        final mfa3 = await authState.signInWithCredentials(
          CredentialsParams(phoneProviderId, {
            'providerUserId': userPhone,
            'magicCode': magicCodes[userPhone],
            'state': mfa2.credentials!.state,
          }),
        );
        validateSuccessLogIn(mfa3, userInfoWithPhone);

        final mfaData = MFAPostData(
          MFAConfig(
            requiredItems: {},
            optionalCount: 1,
            optionalItems: {
              const ProviderUserId(
                providerId: 'email',
                providerUserId: userEmail,
              ),
              const ProviderUserId(
                providerId: phoneProviderId,
                providerUserId: userPhone,
              ),
            },
          ),
        );
        // TODO: maybe improve type
        // TODO: test errors
        final user = await authState.setUserMFA(mfaData);

        expect(user!.user, authState.userInfo.value);

        await authState.signOut();

        final responseAfterMFAChange = await authState.signInWithCredentials(
          CredentialsParams(
            ImplementedProviders.email,
            {'email': userEmail, 'password': 'password'},
          ),
        );
        validateSuccessLogIn(responseAfterMFAChange, {
          ...userInfoWithPhone,
          'user': {
            ...userInfoWithPhone['user']! as Map,
            'multiFactorAuth': jsonEncDec(mfaData.mfa),
          },
        });
        // TODO: delete provider
        // TODO: update provider
      });
    });

    // TODO: log in with phone, add TOTP and delete phone. Only TOTP left. Configure so it is only login

    group('TOTP', () {
      test('sign up username and TOTP', () async {
        final result = await authState.signUpWithCredentials(
          CredentialsParams(
            ImplementedProviders.username,
            {
              'username': 'uss',
              'password': 'password',
            },
          ),
        );
        final claims = await config.jwtMaker
            .getUserClaimsFromToken(result!.success!.accessToken);

        authState.addMFAProvider();
        final String providerUserIdString;
        {
          final totpResult = await authState.signUpWithCredentials(
            CredentialsParams(ImplementedProviders.totp, {}),
          );

          final base32Secret = totpResult!
              .credentials!.userMessage.args!['base32Secret']! as String;

          final qrUrl = Uri.parse(totpResult.credentials!.qrUrl!);
          providerUserIdString = qrUrl.pathSegments.last.split(':').last;
          // TODO: verify base32 secret
          const issuer = 'oauth_example';

          expect(jsonEncDec(totpResult), {
            'state': isA<String>(),
            'userMessage': {
              'key': Translations.totpCreateFlowKey,
              'msg': 'Use the an authenticator application that supports Time-Base'
                  ' One-Time Passwords (TOTP) such as Google Authenticator,'
                  ' Twilio Authy or Microsoft Authenticator. Setup key: "$base32Secret".',
              'args': {'base32Secret': base32Secret}
            },
            'qrUrl':
                'otpauth://totp/$issuer:$providerUserIdString?secret=$base32Secret&issuer=$issuer&digits=6&period=30&algorithm=SHA1',
            'paramDescriptions': {
              'totp': {
                'name': {
                  'key': Translations.totpNameKey,
                  'msg': 'One Time Password Code'
                },
                'description': {
                  'key': Translations.totpDescriptionKey,
                  'msg': 'The code presented in your authenticator app.'
                },
                'regExp': r'^[0-9]{6}$',
                'required': false,
                'readOnly': false,
                'obscureText': false,
                'keyboardType': 'number',
                'textCapitalization': 'none'
              }
            }
          });

          final totpResult2 = await authState.signUpWithCredentials(
            CredentialsParams(ImplementedProviders.totp, {
              'state': totpResult.credentials!.state,
            }),
          );
          expect(totpResult2!.error!.error.key, Translations.invalidCodeKey);
          final totpResult3 = await authState.signUpWithCredentials(
            CredentialsParams(ImplementedProviders.totp, {
              'state': totpResult.credentials!.state,
              'totp': '999999',
            }),
          );
          // TODO: maybe a more specify error message for totp?
          expect(totpResult3!.error!.error.key, Translations.invalidCodeKey);

          final code = OTP.generateTOTPCodeString(
            base32Secret,
            DateTime.now().millisecondsSinceEpoch,
            algorithm: Algorithm.SHA1,
            isGoogle: true,
          );

          final totpResultSuccess = await authState.signUpWithCredentials(
            CredentialsParams(ImplementedProviders.totp, {
              'state': totpResult.credentials!.state,
              'totp': code,
            }),
          );
          validateSuccessLogIn(
            totpResultSuccess,
            {
              'user': {
                'userId': claims!.userId,
                'emailIsVerified': false,
                'phoneIsVerified': false,
                'multiFactorAuth': {
                  'requiredItems': [
                    {'providerId': 'username', 'providerUserId': 'uss'},
                    {
                      'providerId': ImplementedProviders.totp,
                      'providerUserId': providerUserIdString,
                    }
                  ],
                  'optionalCount': 0,
                  'optionalItems': <dynamic>[]
                },
                'createdAt': isA<String>(),
              },
              'authUsers': [
                {
                  'authUser': {
                    'providerId': 'username',
                    'providerUserId': 'uss',
                    'emailIsVerified': false,
                    'phoneIsVerified': false,
                    'username': 'uss',
                    'passwordHash': isA<String>(),
                  },
                  'providerName': {
                    'key': Translations.usernameProviderNameKey,
                    'msg': 'Username and Password'
                  },
                  'updateParams': {
                    'userMessage': {'key': ''},
                    'paramDescriptions': {
                      'username': {
                        'name': {
                          'key': Translations.usernameNameKey,
                          'msg': 'Username'
                        },
                        'description': {
                          'key': Translations.usernameDescriptionKey,
                          'msg':
                              'Alphanumeric username with at least 3 characters. This will be your identifier to sign in.'
                        },
                        'regExp': r'^[a-zA-Z0-9_-]{3,}$',
                        'required': false,
                        'initialValue': 'uss',
                        'readOnly': false,
                        'obscureText': false,
                        'keyboardType': 'text',
                        'textCapitalization': 'none'
                      },
                      'password': {
                        'name': {
                          'key': Translations.passwordNameKey,
                          'msg': 'Password'
                        },
                        'description': {
                          'key': Translations.passwordDescriptionKey,
                          'msg': 'Should be at least 8 characters.'
                        },
                        'regExp': r'[\s\S]{8,}',
                        'required': false,
                        'readOnly': false,
                        'obscureText': true,
                        'keyboardType': 'text',
                        'textCapitalization': 'none'
                      }
                    }
                  }
                },
                {
                  'authUser': {
                    'providerId': ImplementedProviders.totp,
                    'providerUserId': providerUserIdString,
                    'emailIsVerified': false,
                    'phoneIsVerified': false,
                    'base32Secret': base32Secret
                  },
                  'providerName': {
                    'key': Translations.totpProviderNameKey,
                    'msg': 'Time One-Time Password (TOTP)'
                  }
                }
              ]
            },
          );
        }
        {
          final totpProviderUserId = ProviderUserId(
            providerId: ImplementedProviders.totp,
            providerUserId: authState.userInfo.value!.authUsers
                .firstWhere(
                  (a) => a.authUser.providerId == ImplementedProviders.totp,
                )
                .authUser
                .providerUserId,
          );
          expect(providerUserIdString, totpProviderUserId.providerUserId);

          final deleteResult =
              await authState.deleteAuthProvider(totpProviderUserId);
          expect(
            deleteResult!.response!.error!.error.key,
            Translations.canNotDeleteMFAProviderKey,
          );

          final mfa = await authState.setUserMFA(
            MFAPostData(
              MFAConfig(
                requiredItems: {
                  const ProviderUserId(
                    providerId: ImplementedProviders.username,
                    providerUserId: 'uss',
                  ),
                },
                optionalCount: 0,
                optionalItems: {},
              ),
            ),
          );
          // TODO: test errors
          expect(mfa!.response, isNull);
          expect(mfa.user, isNotNull);

          final deleteResult2 =
              await authState.deleteAuthProvider(totpProviderUserId);
          expect(deleteResult2!.response, isNull);
          expect(
            deleteResult2.user!.user.multiFactorAuth.requiredItems.first,
            const ProviderUserId(
              providerId: ImplementedProviders.username,
              providerUserId: 'uss',
            ),
          );
          expect(deleteResult2.user, authState.userInfo.value);
        }
      });
    });
  });
}
