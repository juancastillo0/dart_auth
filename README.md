<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

# Dart Authenticator

Provides integrations and configuration for implementing authentication within your Dart applications and servers. Supports multiple [OAuth2/OpenIdConnect providers](#providers) and custom [credentials](#credentials-username-or-email-and-password) such as email, phone, username or time-based one-time password (TOTP).

[Flutter](https://github.com/flutter/flutter) package for an integrated authentication flow and a [`package:shelf`](https://pub.dev/packages/shelf) web server for implementing the backend authentication endpoints.

This repository is a monorepo with the following packages:

| Package           | Description                                                                                       | pub.dev |
| ----------------- | ------------------------------------------------------------------------------------------------- | ------- |
| dart_auth         | Core package with all models and the logic for implementing the<br> server or client applications |         |
| dart_auth_shelf   | Shelf bindings for implementing authentication for a backend<br> web server using shelf           |         |
| dart_auth_flutter | Widgets and API integration for authentication in Flutter applications                            |         |



# Table Of Contents

- [Dart Authenticator](#dart-authenticator)
- [Table Of Contents](#table-of-contents)
- [Features](#features)
- [Endpoints](#endpoints)
  - [Authentication Providers](#authentication-providers)
  - [Sign In](#sign-in)
  - [Sign Up](#sign-up)
  - [Sign Out (Session JWT Revoke)](#sign-out-session-jwt-revoke)
    - [Sign Out multiple sessions](#sign-out-multiple-sessions)
  - [JSON Web Tokens (JWT)](#json-web-tokens-jwt)
    - [Multiple Sessions](#multiple-sessions)
    - [Multiple Devices](#multiple-devices)
    - [Refresh Token](#refresh-token)
  - [OAuth2 Callbacks](#oauth2-callbacks)
    - [OAuth2 Notifications Webhooks](#oauth2-notifications-webhooks)
- [Access Tokens and Authentication Headers](#access-tokens-and-authentication-headers)
  - [JSON Web Tokens (JWT)](#json-web-tokens-jwt-1)
  - [Sessions](#sessions)
- [Providers](#providers)
  - [OAuth2 and OpenID Connect](#oauth2-and-openid-connect)
  - [Scopes](#scopes)
    - [Other Custom Provider](#other-custom-provider)
    - [apple](#apple)
    - [discord](#discord)
    - [facebook](#facebook)
    - [github](#github)
    - [google](#google)
    - [linkedin](#linkedin)
    - [microsoft](#microsoft)
    - [reddit](#reddit)
    - [steam](#steam)
    - [twitter](#twitter)
    - [spotify](#spotify)
  - [OAuth2 and OpenIdConnect server](#oauth2-and-openidconnect-server)
  - [Credentials: Username or Email and Password](#credentials-username-or-email-and-password)
    - [Isolates](#isolates)
  - [Email, Phone and Magic Link](#email-phone-and-magic-link)
  - [Multi-Factor Authentication (MFA or 2FA)](#multi-factor-authentication-mfa-or-2fa)
    - [Example:](#example)
  - [Time-based One-Time Password (TOTP)](#time-based-one-time-password-totp)
- [Persistence and Models](#persistence-and-models)
  - [SQL Databases Table Schemas](#sql-databases-table-schemas)
    - [User Model](#user-model)
    - [Account Model](#account-model)
    - [Session Model](#session-model)
    - [AuthState Model](#authstate-model)
    - [UserChangeEvent Model](#userchangeevent-model)
- [OAuth2 Authentication Flows](#oauth2-authentication-flows)
  - [Authentication Code and Tokens](#authentication-code-and-tokens)
  - [Device Code (Smart TV, CLI app, no redirect uri in browser)](#device-code-smart-tv-cli-app-no-redirect-uri-in-browser)
  - [Implicit Flow (frontend, no client secret, no refresh token)](#implicit-flow-frontend-no-client-secret-no-refresh-token)
- [Admin Dashboard](#admin-dashboard)
- [Backend Config](#backend-config)
  - [Config](#config)
  - [AppCredentialsConfig](#appcredentialsconfig)
  - [Rate Limiting](#rate-limiting)
    - [PersistenceRateLimiter](#persistenceratelimiter)
      - [RateLimit Headers](#ratelimit-headers)
  - [Session Dates Verification](#session-dates-verification)
- [Frontend Client](#frontend-client)
  - [Frontend Client GlobalState](#frontend-client-globalstate)
    - [Global State](#global-state)
    - [AuthClient State](#authclient-state)
    - [Admin State](#admin-state)
  - [Endpoint](#endpoint)
  - [Flutter](#flutter)
    - [Multiple sessions per device](#multiple-sessions-per-device)
- [Translations, Localization and Internationalization (l10n and i18n)](#translations-localization-and-internationalization-l10n-and-i18n)
  - [Backend Translations](#backend-translations)
    - [Translation class](#translation-class)
  - [Frontend Translations](#frontend-translations)
  - [Getting started](#getting-started)
  - [Usage](#usage)
  - [Additional information](#additional-information)


TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

# Features


# Endpoints


| HTTP Method | Path                           | Path Params           | Input Payload | Output Body | Description |
| ----------- | ------------------------------ | --------------------- | ------------- | ----------- | ----------- |
| GET         | oauth/providers                |                       |               |             |             |
| GET         | oauth/url/$providerId          | - $providerId: String |               |             |             |
| GET         | oauth/device/$providerId       | - $providerId: String |               |             |             |
| GET/POST    | oauth/callback/$providerId     | - $providerId: String |               |             |             |
| GET         | oauth/state                    |                       |               |             |             |
| WS          | oauth/subscribe                |                       |               |             |             |
| POST        | jwt/refresh                    |                       |               |             |             |
| POST        | jwt/revoke                     |                       |               |             |             |
| GET         | user/me                        |                       |               |             |             |
| POST        | user/mfa                       |                       |               |             |             |
| DELETE      | providers/delete/$providerId   | - $providerId: String |               |             |             |
| PUT         | credentials/update/$providerId | - $providerId: String |               |             |             |
| POST        | credentials/signin/$providerId | - $providerId: String |               |             |             |
| POST        | credentials/signup/$providerId | - $providerId: String |               |             |             |
| GET         | admin/users                    |                       |               |             |             |

## Authentication Providers

GET "/providers"

Returns a list of the supported authentication providers. Separated between OAuth and Credentials providers. Useful for presenting the sign up and sign in forms.

## Sign In

POST "/credentials/signin"

Logs in an user using a credentials providers

// TODO: ask for user if they would like to create an account

## Sign Up

POST "/credentials/signup"

Registers an user using a credentials providers

## Sign Out (Session JWT Revoke)

POST "/jwt/revoke"

Logs out an user. The access tokens are not revoked, only the refresh token is revoked. The session is updated so the `endedAt` date is set to the current timestamp and a session ended event is saved.

### Sign Out multiple sessions

// TODO: Not implemented. Manage multiple sessions

## JSON Web Tokens (JWT)

// TODO: Encryption

### Multiple Sessions

### Multiple Devices

### Refresh Token

POST "/jwt/refresh"

Retrieves a new access token from a refresh token. Return Unauthorized if the refresh token has been [revoked](#sign-out-session-jwt-revoke).

## OAuth2 Callbacks

### OAuth2 Notifications Webhooks

GET or POST "oauth/callback/<providerId>"

The OAuth2 authentication providers will send a request to this endpoint with the result of the authentication flow.

# Access Tokens and Authentication Headers

We use JSON Web Tokens (JWT) for managing user authentication and a session for revoking access. The token should be sent through the `Authorization` HTTP header.

## JSON Web Tokens (JWT)

We use the [`package:jose`](https://pub.dev/packages/jose)
## Sessions

A session contains the information about the authentication state and other metadata such as the device, platform, last login date the authentication providers used.

# Providers

## OAuth2 and OpenID Connect

We implement multiple predefined authentication providers for social sign in though OAuth2 and OpenID Connect.

## Scopes

You may add additional scopes, for example for the `GoogleProvider`, you may add a scope to access the user's  Google Drive and backup you application data, the `TwitterProvider` to write tweets, the `DiscordProvider` to send messages or the `GithubProvider` to access private repositories.



| provider  | logo                                                                | scope                                  | documentation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | implicit flow | device flow | email | phone | picture | OpenId                                                                                   |
| --------- | ------------------------------------------------------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ----------- | ----- | ----- | ------- | ---------------------------------------------------------------------------------------- |
| Apple     | ![Apple](./lib/assets/oauth_providers_icons/apple.svg)              | "openid name email"                    | [OpenIdConnect](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api), [Revoke](https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens), [Apps](https://developer.apple.com/documentation/sign_in_with_apple/configuring_your_environment_for_sign_in_with_apple)                                                                                                                                                                                                                                                  | ❌             | ❌           | ✅*    | ❌     | ❌       | [config](https://appleid.apple.com/.well-known/openid-configuration)                     |
| Discord   | ![Discord](./lib/assets/oauth_providers_icons/discord.svg)          | "identify email"                       | [OAuth2](https://discord.com/developers/docs/topics/oauth2), [Apps](https://discord.com/developers/applications), [User](https://discord.com/api/oauth2/@me), [Scopes](https://discord.com/developers/docs/topics/oauth2#shared-resources-oauth2-scopes)                                                                                                                                                                                                                                                                                                                   | ✅             | ❌           | ✅     | ❌     | ✅*      | ❌                                                                                        |
| Facebook  | ![Facebook](./lib/assets/oauth_providers_icons/facebook.svg)        | "public_profile,email"                 | [OAuth2](https://developers.facebook.com/docs/facebook-login/guides/advanced/manual-flow#confirm), [Device](https://developers.facebook.com/docs/facebook-login/for-devices), [Revoke](https://developers.facebook.com/docs/facebook-login/guides/permissions/request-revoke#revokelogin), [User](https://graph.facebook.com/v16.0/me), [Scopes](https://developers.facebook.com/docs/permissions/reference)                                                                                                                                                               | ❌             | ✅           | ✅     | ❌     | ✅       | ✅*                                                                                       |
| Github    | ![Github](./lib/assets/oauth_providers_icons/github.svg)            | "read:user user:email"                 | [OAuth2](https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps), [Device](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow), [Revoke](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation), [User](https://api.github.com/applications/$clientId/token), [Scopes](https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps)                                                                        | ❌             | ✅           | ✅     | ❌     | ✅       | ❌                                                                                        |
| Google    | ![Google](./lib/assets/oauth_providers_icons/google.svg)            | "openid email profile"                 | [OAuth2](https://developers.google.com/identity/protocols/oauth2/web-server), [OpenIDConnect](https://developers.google.com/identity/openid-connect/openid-connect), [Scopes Device](https://developers.google.com/identity/protocols/oauth2/limited-input-device#allowedscopes)                                                                                                                                                                                                                                                                                           | ❌             | ✅           | ✅     | ❌     | ✅       | [config](https://accounts.google.com/.well-known/openid-configuration)                   |
| Microsoft | ![Microsoft Azure AD](./lib/assets/oauth_providers_icons/azure.svg) | "openid email profile offline_access"  | [OpenIDConnect](https://learn.microsoft.com/en-us/azure/active-directory/develop/scopes-oidc), [Apps](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app), [User](https://learn.microsoft.com/en-us/azure/active-directory/develop/userinfo)                                                                                                                                                                                                                                                                                         | ✅             | ✅           | ✅     | ❌     | ✅       | [config](https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration) |
| Reddit    | ![Reddit](./lib/assets/oauth_providers_icons/reddit.svg)            | "identity"                             | [OAuth2](https://github.com/reddit-archive/reddit/wiki/OAuth2), [ClientCredentials](https://github.com/reddit-archive/reddit/wiki/OAuth2#application-only-oauth), [Apps](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app), [User](https://www.reddit.com/dev/api/#GET_api_v1_me)                                                                                                                                                                                                                                                  | ✅             | ❌           | ❌*    | ❌     | ❌*      | ❌                                                                                        |
| Spotify   | ![Spotify](./lib/assets/oauth_providers_icons/spotify.svg)          | "user-read-private user-read-email"    | [OAuth2](https://developer.spotify.com/documentation/general/guides/authorization/), [Revoke](https://developer.spotify.com/community/news/2016/07/25/app-ready-token-revoke/), [User](https://developer.spotify.com/documentation/web-api/reference/#/operations/get-current-users-profile)                                                                                                                                                                                                                                                                               | ✅             | ❌           | ✅     | ❌     | ✅       | ❌                                                                                        |
| Twitch    | ![Twitch](./lib/assets/oauth_providers_icons/twitch.svg)            | "user:read:email openid"               | [Scopes](https://dev.twitch.tv/docs/authentication/scopes/)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | ✅             | ❌           | ✅     | ❌     | ✅       | [config](https://id.twitch.tv/oauth2/.well-known/openid-configuration)                   |
| Twitter   | ![Twitter](./lib/assets/oauth_providers_icons/twitter.svg)          | "users.read tweet.read offline.access" | [OAuth2](https://developer.twitter.com/en/docs/authentication/oauth-2-0/authorization-code), [Revoke](https://api.twitter.com/oauth2/invalidate_token), [User](https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials), [UserModel](https://developer.twitter.com/en/docs/twitter-api/data-dictionary/object-model/user), [TokenModel](https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials) | ❌             | ❌           | ✅*    | ❌     | ✅       | ❌                                                                                        |



### Other Custom Provider
### apple
### discord
### facebook
### github
### google
### linkedin
### microsoft
### reddit
### steam
### twitter
### spotify

GitLab
TikTok
Dropbox
Atlassian
Slack

## OAuth2 and OpenIdConnect server

// TODO: 

## Credentials: Username or Email and Password

We use [Argon2](https://en.wikipedia.org/wiki/Argon2) though the [`package:argon2`](https://pub.dev/packages/argon2) for hashing the passwords. The `passwordHash` is stored in the [account Model](#account-model) with the Argon2 configuration used to create it.

### Isolates

You may use isolates for hashing. This allows to share the compute load between isolates.

## Email, Phone and Magic Link

Passwordless login is also implemented for email and phone providers through magic links or authentication codes sent to the email or phone. The provider gives you the authentication code, you may choose to only presente it as a link or show the code to the user. You can configure the way the code is generated. 

You have to use an external provider for sending the verification email or sms. For email you may use a services such as Mailjet and send the email using [`package:mailer`](https://pub.dev/packages/mailer), or perhaps by using an API given by the email or sms provider (some expose REST APIs, for example).


## Multi-Factor Authentication (MFA or 2FA)

Multi-Factor authentication allows you to increase the security of your users' accounts by adding other authentication steps before an user can be signed in. For that, we provide the following configuration:

- Required providers: The set of required providers to sign in.
- Optional providers: The set of optional providers to sign in.
- Optional amount: The number of optional providers to satisfy in order to sign in into the account.

You may combine any OAuth2 or Credential provider in your configuration.

### Example:

If you have the following configuration:

- Required providers: [`provider1`]
- Optional providers: [`provider2`, `provider3`] 
- Optional amount: 1

You will need to sign in with `provider1` since it is required as well as at least one (the optional amount) of `provider2` or `provider3`.

## Time-based One-Time Password (TOTP)

We use the [`package:otp`](https://pub.dev/packages/otp) for computing the TOTP from the shared secret.

This allows the user to sign in with an authenticator application that supports Time-Base One-Time Passwords (TOTP) such as Google Authenticator, Twilio Authy or Microsoft Authenticator.

# Persistence and Models

When using the backend server, the information should be stored to maintain the user's authentication providers, the user's account, sessions and other authentication information.

You may use any database or service for storing the information by implementing the [`Persistence Interface`](./lib/src/data.dart). We provide a `InMemoryPersistence` for testing and an `SQLPersistence` for SQL databases.

## SQL Databases Table Schemas

The tables used by the authentication server are the following:

### User Model

The main user table saves the user's `id`, `name`, `picture`, the creation date and the multi factor authentication configuration as a JSON String (`multiFactorAuth`). The userId is the primary key and it is immutable along with the `createdAt`.

```sql
CREATE TABLE IF NOT EXISTS ${tables.user} (
  userId TEXT NOT NULL,
  name TEXT NULL,
  picture TEXT NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  multiFactorAuth $jsonType NOT NULL,
  PRIMARY KEY (userId)
);
```

### Account Model

Each user can have multiple authentication provider accounts. They save the information required to access the user's data `rawUserData` and expose typical user information such as the `email`, `phone`, `name` and `picture` retrieved from the authentication provider.

```sql
CREATE TABLE IF NOT EXISTS ${tables.account} (
  userId TEXT NOT NULL,
  providerId TEXT NOT NULL,
  providerUserId TEXT NOT NULL,
  name TEXT NULL,
  picture TEXT NULL,
  email TEXT NULL,
  emailIsVerified BOOL NOT NULL,
  phone TEXT NULL,
  phoneIsVerified BOOL NOT NULL,
  rawUserData $jsonType NOT NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (providerId, providerUserId),
  FOREIGN KEY (userId) REFERENCES ${tables.user} (userId)
);
```

### Session Model

An user can have multiple sessions. This is used to revoke sessions, when the `endedAt` Date is not null, then the session has ended and the `refreshToken` can not be used to retrieve a new access token. `mfa` contains the authentication providers used to authenticate the session. `meta` is other custom user or session information and `deviceId` maybe set to identify sessions within a given device.

```sql
CREATE TABLE IF NOT EXISTS ${tables.session} (
  sessionId TEXT NOT NULL,
  deviceId TEXT NULL,
  refreshToken TEXT NULL,
  userId TEXT NOT NULL,
  meta $jsonType NULL,
  mfa $jsonType NOT NULL,
  endedAt DATE NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sessionId),
  FOREIGN KEY (userId) REFERENCES ${tables.user} (userId)
);
```

### AuthState Model

The authentication state is a simple key-value table with information of authentication flows. They save the status and other metadata of authentication requests that require user interaction and may unfinished. For example, OAuth2 flows or Email/Phone magic links/codes that require the user to authorize the app or input an authorization code. This is also used for [Multi-Factor Authentication](#multi-factor-authentication-mfa-or-2fa) flows.

```sql
CREATE TABLE IF NOT EXISTS ${tables.authState} (
  key TEXT NOT NULL,
  value $jsonType NOT NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (key)
);
```

### UserChangeEvent Model

A table with the events that occur to an user's account. Useful for tracing the account's behavior and identifying unwanted access.


```sql
CREATE TABLE IF NOT EXISTS ${tables.userEvent} (
  key TEXT NOT NULL,
  type TEXT NOT NULL,
  value $jsonType NOT NULL,
  sessionId TEXT NOT NULL,
  userId TEXT NOT NULL,
  createdAt DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (userId) REFERENCES ${tables.user} (userId)
  FOREIGN KEY (sessionId, userId) REFERENCES ${tables.session} (sessionId, userId)
  PRIMARY KEY (createdAt, key),
  UNIQUE (key)
);
```

At the moment, the following event types are recorder:

- MFA Updated
- Authentication Provider Created
- Authentication Provider Updated
- Authentication Provider Deleted
- Authentication Provider Revoked
- Session Created
- Session Updated
- Session Revoked

# OAuth2 Authentication Flows

This provides external APIs access to validate an user's account or accessing and editing their information. In this way you can implement social sign in.

## Authentication Code and Tokens

The main way to access external APIs to validate the account of an user or accessing or editing their information (though scopes).

## Device Code (Smart TV, CLI app, no redirect uri in browser)

Should only be used if you are certain the device cannot open a browser or have limited input capabilities. You should probably use [Authentication Code flow](#authentication-code-and-tokens) for CLI apps since you may print the url for the user to open the browser on their device. This may be a problem for Smart TVs however. 

Some providers requiere additional configuration ([Facebook's CLIENT_TOKEN](https://developers.facebook.com/docs/facebook-login/for-devices)) or limit the scopes that can be requested ([Google device flow allowed scopes](https://developers.google.com/identity/protocols/oauth2/limited-input-device#allowedscopes)).

Not all providers support this flow.

## Implicit Flow (frontend, no client secret, no refresh token)

In general, you should not use this unless the app is frontend only or the access is one-time only (or you don't care that the user gives permissions every time).

Not all providers support this flow.


# Admin Dashboard

Dashboard for managing user accounts.

# Backend Config

## Config

late final Map<String, AuthenticationProvider> allProviders;
final List<Translations> translations;
final Persistence persistence;
final String baseRedirectUri;
final JsonWebTokenMaker jwtMaker;

## AppCredentialsConfig

// TODO: maybe get it from the database?

## Rate Limiting

You may provide multiple `RateLimit`s for a given endpoint, which allows you to configure a different amount of requests allowed for different time window sizes. For example, a rate of 100 requests in 1 minute and a 500 requests in an hour allows for bursts of 100 petitions in a single minute, but the can't surpass 500 requests in an hour.


### PersistenceRateLimiter

We provide a RateLimiter implementation `PersistenceRateLimiter` that provides an eventually-consistent sliding window algorithm. It tracks the sliding counters in memory and relies on transactions in the persistence store to periodically sync the local count data with the shared persistence.

#### RateLimit Headers

When the count reaches the configured rate limit, 

| Name                | Type    | Description                                                                                                                                                                                             | Example                           |
| ------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| RateLimit-Policy    | String  | The configuration of the policy                                                                                                                                                                         | 10;w=60;comment="sliding window"' |
| RateLimit-Limit     | amount  | The amount of requests available in the time window                                                                                                                                                     | 10                                |
| RateLimit-Remaining | amount  | The amount of additional requests that can<br>be performed given the current count                                                                                                                      | 1                                 |
| RateLimit-Reset     | seconds | The number of seconds from now where the count will reset.<br>Since this is a sliding window algorithm, will be the resolution,<br>otherwise it will be the amount of seconds the client needs to wait. | 15                                |
| Retry-After         | seconds | Same as RateLimit-Reset                                                                                                                                                                                 | 15                                |

## Session Dates Verification

You may configure the maximum amount of time that a request can be performed since the session was created.

# Frontend Client

We provide a client facing API for the front end. 

## Frontend Client GlobalState

### Global State

Contains translations and global state and settings for the client such as the selected theme brightness and locale.

### AuthClient State

Main authentication logic of the client.

### Admin State

State for the [Admin Dashboard](#admin-dashboard) section of the application.

## Endpoint

## Flutter

You may also use the Flutter library with pre-made widgets that allow the user to:

- Sign up/in/out
- View their information such as account events and sessions
- Change the [multi-factor authentication](#multi-factor-authentication-mfa-or-2fa)
- View, add, update and delete their authentication providers
- Manage multiple accounts per device

### Multiple sessions per device



# Translations, Localization and Internationalization (l10n and i18n)

At the moment we provide the following translations:

- English
- Spanish

However, other translations may be added in the server or client configuration.

## Backend Translations

Contains the messages sent to the client 

### Translation class

This class provides a way to represent a message that can be translated using a Backend [`Translations`](./lib/src/backend_translation.dart) class.

## Frontend Translations

For the frontend we also provide a way to change the texts shown to the user. You may implement the [`FrontEndTranslations`](./lib/src/frontend/frontend_translations.dart) interface.


## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
