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
  final TwitterWithheld? withheld;

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

  const TwitterUser({
    required this.id,
    required this.name,
    required this.username,
    this.created_at,
    this.protected,
    this.withheld,
    this.location,
    this.url,
    this.description,
    this.verified,
    this.verified_type,
    this.entities,
    this.profile_image_url,
    this.public_metrics,
    this.pinned_tweet_id,
    this.includes,
    this.errors,
  });
// generated-dart-fixer-start{"md5Hash":"FBkP/miL7El930eK6W4I6g=="}

  factory TwitterUser.fromJson(Map json) {
    return TwitterUser(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      protected: json['protected'] as bool?,
      withheld: json['withheld'] == null
          ? null
          : TwitterWithheld.fromJson((json['withheld'] as Map).cast()),
      location: json['location'] as String?,
      url: json['url'] as String?,
      description: json['description'] as String?,
      verified: json['verified'] as bool?,
      verified_type: json['verified_type'] == null
          ? null
          : TwitterVerifiedType.values.byName(json['verified_type'] as String),
      entities: json['entities'] == null
          ? null
          : (json['entities'] as Map).map((k, v) => MapEntry(k as String, v)),
      profile_image_url: json['profile_image_url'] as String?,
      public_metrics: json['public_metrics'] == null
          ? null
          : TwitterPublicMetrics.fromJson(
              (json['public_metrics'] as Map).cast(),),
      pinned_tweet_id: json['pinned_tweet_id'] as String?,
      includes: json['includes'] == null
          ? null
          : TwitterIncludes.fromJson((json['includes'] as Map).cast()),
      errors: json['errors'] == null
          ? null
          : (json['errors'] as Map).map((k, v) => MapEntry(k as String, v)),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'created_at': created_at?.toIso8601String(),
      'protected': protected,
      'withheld': withheld,
      'location': location,
      'url': url,
      'description': description,
      'verified': verified,
      'verified_type': verified_type,
      'entities': entities,
      'profile_image_url': profile_image_url,
      'public_metrics': public_metrics,
      'pinned_tweet_id': pinned_tweet_id,
      'includes': includes,
      'errors': errors,
    };
  }

  @override
  String toString() {
    return "TwitterUser${{
      "id": id,
      "name": name,
      "username": username,
      "created_at": created_at,
      "protected": protected,
      "withheld": withheld,
      "location": location,
      "url": url,
      "description": description,
      "verified": verified,
      "verified_type": verified_type,
      "entities": entities,
      "profile_image_url": profile_image_url,
      "public_metrics": public_metrics,
      "pinned_tweet_id": pinned_tweet_id,
      "includes": includes,
      "errors": errors,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"FBkP/miL7El930eK6W4I6g=="}

class TwitterIncludes {
  final List<Map<String, Object?>>? tweets;

  const TwitterIncludes({this.tweets});
// generated-dart-fixer-start{"md5Hash":"fvli/5emIYo4ON4fXv7STw=="}

  factory TwitterIncludes.fromJson(Map json) {
    return TwitterIncludes(
      tweets: json['tweets'] == null
          ? null
          : (json['tweets'] as Iterable)
              .map((v) => (v as Map).map((k, v) => MapEntry(k as String, v)))
              .toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'tweets': tweets,
    };
  }

  @override
  String toString() {
    return "TwitterIncludes${{
      "tweets": tweets,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"fvli/5emIYo4ON4fXv7STw=="}

enum TwitterVerifiedType { blue, business, government, none }

class TwitterWithheld {
  /// Provides a list of countries where this user is not available.
  ///
  /// To return this field, add user.fields=withheld.country_codes in the request's query parameter.
  final List<String> country_codes;

  /// Indicates whether the content being withheld is a Tweet or a user (this API will return user).
  ///
  /// To return this field, add user.fields=withheld.scope in the request's query parameter.
  final TwitterWithheldScope scope;

  const TwitterWithheld({
    required this.country_codes,
    required this.scope,
  });
// generated-dart-fixer-start{"md5Hash":"5C5WPb2z4OeIYO0OwpQ/vw=="}

  factory TwitterWithheld.fromJson(Map json) {
    return TwitterWithheld(
      country_codes:
          (json['country_codes'] as Iterable).map((v) => v as String).toList(),
      scope: TwitterWithheldScope.values.byName(json['scope'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'country_codes': country_codes,
      'scope': scope,
    };
  }

  @override
  String toString() {
    return "TwitterWithheld${{
      "country_codes": country_codes,
      "scope": scope,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"5C5WPb2z4OeIYO0OwpQ/vw=="}

enum TwitterWithheldScope { tweet, user }

class TwitterPublicMetrics {
  /// Number of users who follow this user.
  final int followers_count;

  /// Number of users this user is following.
  final int following_count;

  /// Number of Tweets (including Retweets) posted by this user.
  final int tweet_count;

  /// Number of lists that include this user.
  final int listed_count;

  const TwitterPublicMetrics({
    required this.followers_count,
    required this.following_count,
    required this.tweet_count,
    required this.listed_count,
  });

// generated-dart-fixer-start{"md5Hash":"c77E/8mWvZJ/NnOG4thZ6w=="}

  factory TwitterPublicMetrics.fromJson(Map json) {
    return TwitterPublicMetrics(
      followers_count: json['followers_count'] as int,
      following_count: json['following_count'] as int,
      tweet_count: json['tweet_count'] as int,
      listed_count: json['listed_count'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'followers_count': followers_count,
      'following_count': following_count,
      'tweet_count': tweet_count,
      'listed_count': listed_count,
    };
  }

  @override
  String toString() {
    return "TwitterPublicMetrics${{
      "followers_count": followers_count,
      "following_count": following_count,
      "tweet_count": tweet_count,
      "listed_count": listed_count,
    }}";
  }
}


// generated-dart-fixer-end{"md5Hash":"c77E/8mWvZJ/NnOG4thZ6w=="}
