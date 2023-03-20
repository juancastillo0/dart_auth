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

- [Dart Authenticator](#dart-authenticator)
  - [Features](#features)
  - [Endpoints](#endpoints)
    - [Log In](#log-in)
    - [Log Out](#log-out)
      - [Log Out multiple sessions](#log-out-multiple-sessions)
    - [JSON Web Tokens (JWT)](#json-web-tokens-jwt)
      - [Multiple Sessions](#multiple-sessions)
      - [Refresh Token](#refresh-token)
    - [OAuth2 Callbacks](#oauth2-callbacks)
      - [OAuth2 Notifications Webhooks](#oauth2-notifications-webhooks)
  - [Access Tokens and Authentication Headers](#access-tokens-and-authentication-headers)
    - [JSON Web Tokens (JWT)](#json-web-tokens-jwt-1)
    - [Sessions](#sessions)
  - [Providers](#providers)
    - [OAuth2 and OpenID Connect](#oauth2-and-openid-connect)
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
    - [Credentials: Username or Email and Password](#credentials-username-or-email-and-password)
    - [Email and Magic Link](#email-and-magic-link)
      - [Isolates](#isolates)
    - [Scopes](#scopes)
    - [Two Factor Authentication (2FA)](#two-factor-authentication-2fa)
      - [Time-based One-Time Password (TOTP)](#time-based-one-time-password-totp)
  - [Models](#models)
    - [Databases](#databases)
  - [Authentication Flows](#authentication-flows)
    - [Authentication Code and Tokens](#authentication-code-and-tokens)
    - [Device Code (Smart TV, CLI app, no redirect uri in browser)](#device-code-smart-tv-cli-app-no-redirect-uri-in-browser)
    - [Implicit Flow (frontend, no client secret, no refresh token)](#implicit-flow-frontend-no-client-secret-no-refresh-token)
  - [Getting started](#getting-started)
  - [Usage](#usage)
  - [Additional information](#additional-information)


TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features


## Endpoints

### Log In

### Log Out

#### Log Out multiple sessions


### JSON Web Tokens (JWT)

#### Multiple Sessions

#### Refresh Token


### OAuth2 Callbacks

#### OAuth2 Notifications Webhooks



## Access Tokens and Authentication Headers

### JSON Web Tokens (JWT)

### Sessions



## Providers

### OAuth2 and OpenID Connect

#### Other Custom Provider
#### apple
#### discord
#### facebook
#### github
#### google
#### linkedin
#### microsoft
#### reddit
#### steam
#### twitter
#### spotify


### Credentials: Username or Email and Password

Argon2

### Email and Magic Link


#### Isolates

### Scopes

You may add additional scopes, for example for the `GoogleProvider`, you may add a scope to access the user's  Google Drive and backup you application data, the `TwitterProvider` to write tweets, the `DiscordProvider` to send messages or the `GithubProvider` to access private repositories.



### Two Factor Authentication (2FA)

#### Time-based One-Time Password (TOTP)



## Models

### Databases



## Authentication Flows

### Authentication Code and Tokens

### Device Code (Smart TV, CLI app, no redirect uri in browser)

### Implicit Flow (frontend, no client secret, no refresh token)



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
