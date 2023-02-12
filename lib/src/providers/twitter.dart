import 'package:oauth/oauth.dart';

/// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
/// https://developer.twitter.com/en/docs/authentication/oauth-2-0/authorization-code
/// https://developer.twitter.com/en/docs/authentication/guides/v2-authentication-mapping
class TwitterProvider extends OAuthProvider {
  /// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
  /// https://developer.twitter.com/en/docs/authentication/oauth-2-0/authorization-code
  /// https://developer.twitter.com/en/docs/authentication/guides/v2-authentication-mapping
  const TwitterProvider({
    required super.clientIdentifier,
    required super.clientSecret,
  }) : super(
          // TODO: response_type=code&code_challenge=dwdwa&code_challenge_method=plain
          authorizationEndpoint: 'https://twitter.com/i/oauth2/authorize',
          tokenEndpoint: 'https://api.twitter.com/2/oauth2/token',
          // App only bearer token https://developer.twitter.com/en/docs/authentication/api-reference/invalidate_bearer_token
          // https://api.twitter.com/oauth2/invalidate_token
          revokeTokenEndpoint: 'https://api.twitter.com/2/oauth2/revoke',
        );

  @override
  List<GrantType> get supportedFlows =>

      ///S256 OR plain
      const [
        GrantType.authorization_code,
        GrantType.refresh_token,

        // App only bearer token https://developer.twitter.com/en/docs/authentication/api-reference/invalidate_bearer_token
        // revoke https://api.twitter.com/oauth2/invalidate_token
        // https://developer.twitter.com/en/docs/authentication/api-reference/token
        GrantType.client_credentials,
      ];

  // scope: users.read tweet.read offline.access
  //
  // url: "https://api.twitter.com/2/users/me",
  // user.fields: profile_image_url
  // https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me
}

/// https://api.twitter.com/1.1/account/verify_credentials.json
class TwitterVerifyCredentialsParams {
  /// The entities node will not be included when set to false.
  final bool? include_entities;

  /// When set to either true , t or 1 statuses will not be included
  /// in the returned user object.
  final bool? skip_status;

  /// When set to true email will be returned in the user objects as a string.
  /// If the user does not have an email address on their account,
  /// or if the email address is not verified, null will be returned.
  final bool? include_email;
}

/// Get user email https://stackoverflow.com/questions/22627083/can-we-get-email-id-from-twitter-oauth-api
/// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials

/// https://api.twitter.com/1.1/account/verify_credentials.json
class TwitterVerifyCredentials {}

/// https://developer.twitter.com/en/docs/twitter-api/data-dictionary/object-model/user
class TwitterUser {
  /// Unique identifier of this user. This is returned as a string in order
  /// to avoid complications with languages and tools that cannot handle large integers.
  final String id;

  /// The friendly name of this user, as shown on their profile.
  final String name;

  /// The Twitter handle (screen name) of this user.
  final String username;

  /// Creation time of this account.
  /// To return this field, add user.fields=created_at in the request's query parameter.
  final DateTime? created_at;

  /// Indicates if this user has chosen to protect their Tweets
  /// (in other words, if this user's Tweets are private).
  /// To return this field, add user.fields=protected in the request's query parameter.
  final bool? protected;

  /// Contains withholding details for withheld content.
  /// To return this field, add user.fields=withheld in the request's query parameter.
  final Withheld? withheld;

  /// The location specified in the user's profile, if the user provided one.
  /// As this is a freeform value, it may not indicate a valid location,
  /// but it may be fuzzily evaluated when performing searches with location queries.
  /// To return this field, add user.fields=location in the request's query parameter.
  final String? location;

  /// The URL specified in the user's profile, if present.
  /// To return this field, add user.fields=url in the request's query parameter.
  final String? url;

  /// The text of this user's profile description (also known as bio),
  /// if the user provided one.
  /// To return this field, add user.fields=description in the request's query parameter.
  final String? description;

  /// Indicate if this user is a verified Twitter user.
  /// To return this field, add user.fields=verified in the request's query parameter.
  final bool? verified;

  /// blue, business, government, none)	Indicates the type of verification
  /// for the Twitter account.
  /// To return this field, add user.fields=verified_type in the request's query parameter.
  final TwitterVerifiedType? verified_type;

  /// This object and its children fields contain details about text that
  /// has a special meaning in the user's description.
  /// To return this field, add user.fields=entities in the request's query parameter.
  final Map<String, Object?>? entities;

  /// The URL to the profile image for this user, as shown on the user's profile.
  final String? profile_image_url;

  /// Contains details about activity for this user.
  final TwitterPublicMetrics? public_metrics;

  /// Unique identifier of this user's pinned Tweet.
  /// You can obtain the expanded object in includes.tweets by
  /// adding expansions=pinned_tweet_id in the request's query parameter.
  final String? pinned_tweet_id;

  /// When including the expansions=pinned_tweet_id parameter,
  /// this includes the pinned Tweets attached to the returned users' profiles
  /// in the form of [Tweet objects](https://developer.twitter.com/en/docs/twitter-api/data-dictionary/object-model/tweet)
  /// with their default fields and any additional
  /// fields requested using the tweet.fields parameter, assuming there is a
  /// referenced Tweet present in the returned Tweet(s).
  final TwitterIncludes? includes;

  /// Contains details about errors that affected any of the requested users.
  /// See [Status codes and error messages](https://developer.twitter.com/en/support/twitter-api/error-troubleshooting) for more details.
  final Map<String, Object?>? errors;
}

class TwitterIncludes {
  final List<Map<String, Object?>>? tweets;
}

enum TwitterVerifiedType { blue, business, government, none }

class Withheld {
  /// Provides a list of countries where this user is not available.
  ///
  /// To return this field, add user.fields=withheld.country_codes in the request's query parameter.
  final List<String> country_codes;

  /// Indicates whether the content being withheld is a Tweet or a user (this API will return user).
  ///
  /// To return this field, add user.fields=withheld.scope in the request's query parameter.
  final WithheldScope scope;
}

enum WithheldScope { tweet, user }

class TwitterPublicMetrics {
  /// Number of users who follow this user.
  final int followers_count;

  /// Number of users this user is following.
  final int following_count;

  /// Number of Tweets (including Retweets) posted by this user.
  final int tweet_count;

  /// Number of lists that include this user.
  final int listed_count;
}

// entities.url	array	Contains details about the user's profile website.
// entities.url.urls	array	Contains details about the user's profile website.
// entities.url.urls.start	integer	The start position (zero-based) of the recognized user's profile website. All start indices are inclusive.
// entities.url.urls.end	integer	The end position (zero-based) of the recognized user's profile website. This end index is exclusive.
// entities.url.urls.url	string	The URL in the format entered by the user.
// entities.url.urls.expanded_url	string	The fully resolved URL.
// entities.url.urls.display_url	string	The URL as displayed in the user's profile.
// entities.description	array	Contains details about URLs, Hashtags, Cashtags, or mentions located within a user's description.
// entities.description.urls	array	Contains details about any URLs included in the user's description.
// entities.description.urls.start	integer	The start position (zero-based) of the recognized URL in the user's description. All start indices are inclusive.
// entities.description.urls.end	integer	The end position (zero-based) of the recognized URL in the user's description. This end index is exclusive.
// entities.description.urls.url	string	The URL in the format entered by the user.
// entities.description.urls.expanded_url	string	The fully resolved URL.
// entities.description.urls.display_url	string	The URL as displayed in the user's description.
// entities.description.hashtags	array	Contains details about text recognized as a Hashtag.
// entities.description.hashtags.start	integer	The start position (zero-based) of the recognized Hashtag within the Tweet. All start indices are inclusive.
// entities.description.hashtags.end	integer	The end position (zero-based) of the recognized Hashtag within the Tweet. This end index is exclusive.
// entities.description.hashtags.hashtag	string	The text of the Hashtag.
// entities.description.mentions	array	Contains details about text recognized as a user mention.
// entities.description.mentions.start	integer	The start position (zero-based) of the recognized user mention within the Tweet. All start indices are inclusive.
// entities.description.mentions.end	integer	The end position (zero-based) of the recognized user mention within the Tweet. This end index is exclusive.
// entities.description.mentions.username	string	The part of text recognized as a user mention.
// entities.description.cashtags	array	Contains details about text recognized as a Cashtag.
// entities.description.cashtags.start	integer	The start position (zero-based) of the recognized Cashtag within the Tweet. All start indices are inclusive.
// entities.description.cashtags.end	integer	The end position (zero-based) of the recognized Cashtag within the Tweet. This end index is exclusive.
// entities.description.cashtags.cashtag	string	The text of the Cashtag.
