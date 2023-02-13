/// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
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

  /// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
  /// https://api.twitter.com/1.1/account/verify_credentials.json
  const TwitterVerifyCredentialsParams({
    this.include_entities,
    this.skip_status,
    this.include_email,
  });
// generated-dart-fixer-start{"md5Hash":"RlVwm1JOlWXgd8KOfZx8Hw=="}

  factory TwitterVerifyCredentialsParams.fromJson(Map json) {
    return TwitterVerifyCredentialsParams(
      include_entities: json['include_entities'] as bool?,
      skip_status: json['skip_status'] as bool?,
      include_email: json['include_email'] as bool?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'include_entities': include_entities,
      'skip_status': skip_status,
      'include_email': include_email,
    };
  }

  @override
  String toString() {
    return "TwitterVerifyCredentialsParams${{
      "include_entities": include_entities,
      "skip_status": skip_status,
      "include_email": include_email,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"RlVwm1JOlWXgd8KOfZx8Hw=="}

/// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
/// https://api.twitter.com/1.1/account/verify_credentials.json
class TwitterVerifyCredentials {
  final bool contributors_enabled;
  final String created_at;
  final bool default_profile;
  final bool default_profile_image;
  final String description;
  final int favourites_count;
  final Object? follow_request_sent;
  final int followers_count;
  final Object? following;
  final int friends_count;
  final bool geo_enabled;
  final int id;
  final String id_str;
  final bool is_translator;
  final String lang;
  final int listed_count;
  final String location;
  final String name;
  final Object? notifications;
  final String profile_background_color;
  final String profile_background_image_url;
  final String profile_background_image_url_https;
  final bool profile_background_tile;
  final String profile_image_url;
  final String profile_image_url_https;
  final String profile_link_color;
  final String profile_sidebar_border_color;
  final String profile_sidebar_fill_color;
  final String profile_text_color;
  final bool profile_use_background_image;
  final bool protected;
  final String screen_name;
  final bool show_all_inline_media;
  final VerifyCredentialsStatus status;
  final int statuses_count;
  final String time_zone;
  final String? url;
  final int utc_offset;
  final bool verified;
  final String? email;

  /// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
  /// https://api.twitter.com/1.1/account/verify_credentials.json
  const TwitterVerifyCredentials({
    required this.contributors_enabled,
    required this.created_at,
    required this.default_profile,
    required this.default_profile_image,
    required this.description,
    required this.favourites_count,
    this.follow_request_sent,
    required this.followers_count,
    this.following,
    required this.friends_count,
    required this.geo_enabled,
    required this.id,
    required this.id_str,
    required this.is_translator,
    required this.lang,
    required this.listed_count,
    required this.location,
    required this.name,
    this.notifications,
    required this.profile_background_color,
    required this.profile_background_image_url,
    required this.profile_background_image_url_https,
    required this.profile_background_tile,
    required this.profile_image_url,
    required this.profile_image_url_https,
    required this.profile_link_color,
    required this.profile_sidebar_border_color,
    required this.profile_sidebar_fill_color,
    required this.profile_text_color,
    required this.profile_use_background_image,
    required this.protected,
    required this.screen_name,
    required this.show_all_inline_media,
    required this.status,
    required this.statuses_count,
    required this.time_zone,
    this.url,
    required this.utc_offset,
    required this.verified,
    this.email,
  });

// generated-dart-fixer-start{"md5Hash":"IL+S/w8mY9ItTNLYaX//4A=="}

  factory TwitterVerifyCredentials.fromJson(Map json) {
    return TwitterVerifyCredentials(
      contributors_enabled: json['contributors_enabled'] as bool,
      created_at: json['created_at'] as String,
      default_profile: json['default_profile'] as bool,
      default_profile_image: json['default_profile_image'] as bool,
      description: json['description'] as String,
      favourites_count: json['favourites_count'] as int,
      follow_request_sent: json['follow_request_sent'],
      followers_count: json['followers_count'] as int,
      following: json['following'],
      friends_count: json['friends_count'] as int,
      geo_enabled: json['geo_enabled'] as bool,
      id: json['id'] as int,
      id_str: json['id_str'] as String,
      is_translator: json['is_translator'] as bool,
      lang: json['lang'] as String,
      listed_count: json['listed_count'] as int,
      location: json['location'] as String,
      name: json['name'] as String,
      notifications: json['notifications'],
      profile_background_color: json['profile_background_color'] as String,
      profile_background_image_url:
          json['profile_background_image_url'] as String,
      profile_background_image_url_https:
          json['profile_background_image_url_https'] as String,
      profile_background_tile: json['profile_background_tile'] as bool,
      profile_image_url: json['profile_image_url'] as String,
      profile_image_url_https: json['profile_image_url_https'] as String,
      profile_link_color: json['profile_link_color'] as String,
      profile_sidebar_border_color:
          json['profile_sidebar_border_color'] as String,
      profile_sidebar_fill_color: json['profile_sidebar_fill_color'] as String,
      profile_text_color: json['profile_text_color'] as String,
      profile_use_background_image:
          json['profile_use_background_image'] as bool,
      protected: json['protected'] as bool,
      screen_name: json['screen_name'] as String,
      show_all_inline_media: json['show_all_inline_media'] as bool,
      status: VerifyCredentialsStatus.fromJson((json['status'] as Map).cast()),
      statuses_count: json['statuses_count'] as int,
      time_zone: json['time_zone'] as String,
      url: json['url'] as String?,
      utc_offset: json['utc_offset'] as int,
      verified: json['verified'] as bool,
      email: json['email'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'contributors_enabled': contributors_enabled,
      'created_at': created_at,
      'default_profile': default_profile,
      'default_profile_image': default_profile_image,
      'description': description,
      'favourites_count': favourites_count,
      'follow_request_sent': follow_request_sent,
      'followers_count': followers_count,
      'following': following,
      'friends_count': friends_count,
      'geo_enabled': geo_enabled,
      'id': id,
      'id_str': id_str,
      'is_translator': is_translator,
      'lang': lang,
      'listed_count': listed_count,
      'location': location,
      'name': name,
      'notifications': notifications,
      'profile_background_color': profile_background_color,
      'profile_background_image_url': profile_background_image_url,
      'profile_background_image_url_https': profile_background_image_url_https,
      'profile_background_tile': profile_background_tile,
      'profile_image_url': profile_image_url,
      'profile_image_url_https': profile_image_url_https,
      'profile_link_color': profile_link_color,
      'profile_sidebar_border_color': profile_sidebar_border_color,
      'profile_sidebar_fill_color': profile_sidebar_fill_color,
      'profile_text_color': profile_text_color,
      'profile_use_background_image': profile_use_background_image,
      'protected': protected,
      'screen_name': screen_name,
      'show_all_inline_media': show_all_inline_media,
      'status': status,
      'statuses_count': statuses_count,
      'time_zone': time_zone,
      'url': url,
      'utc_offset': utc_offset,
      'verified': verified,
      'email': email,
    };
  }

  @override
  String toString() {
    return "TwitterVerifyCredentials${{
      "contributors_enabled": contributors_enabled,
      "created_at": created_at,
      "default_profile": default_profile,
      "default_profile_image": default_profile_image,
      "description": description,
      "favourites_count": favourites_count,
      "follow_request_sent": follow_request_sent,
      "followers_count": followers_count,
      "following": following,
      "friends_count": friends_count,
      "geo_enabled": geo_enabled,
      "id": id,
      "id_str": id_str,
      "is_translator": is_translator,
      "lang": lang,
      "listed_count": listed_count,
      "location": location,
      "name": name,
      "notifications": notifications,
      "profile_background_color": profile_background_color,
      "profile_background_image_url": profile_background_image_url,
      "profile_background_image_url_https": profile_background_image_url_https,
      "profile_background_tile": profile_background_tile,
      "profile_image_url": profile_image_url,
      "profile_image_url_https": profile_image_url_https,
      "profile_link_color": profile_link_color,
      "profile_sidebar_border_color": profile_sidebar_border_color,
      "profile_sidebar_fill_color": profile_sidebar_fill_color,
      "profile_text_color": profile_text_color,
      "profile_use_background_image": profile_use_background_image,
      "protected": protected,
      "screen_name": screen_name,
      "show_all_inline_media": show_all_inline_media,
      "status": status,
      "statuses_count": statuses_count,
      "time_zone": time_zone,
      "url": url,
      "utc_offset": utc_offset,
      "verified": verified,
      "email": email,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"IL+S/w8mY9ItTNLYaX//4A=="}

class VerifyCredentialsStatus {
  final Object? contributors;
  final Coordinates coordinates;
  final String created_at;
  final bool favorited;
  final Coordinates geo;
  final double id;
  final String id_str;
  final String in_reply_to_screen_name;
  final double in_reply_to_status_id;
  final String in_reply_to_status_id_str;
  final int in_reply_to_user_id;
  final String in_reply_to_user_id_str;
  final TwitterPlace place;
  final int retweet_count;
  final bool retweeted;
  final String source;
  final String text;
  final bool truncated;

  const VerifyCredentialsStatus({
    this.contributors,
    required this.coordinates,
    required this.created_at,
    required this.favorited,
    required this.geo,
    required this.id,
    required this.id_str,
    required this.in_reply_to_screen_name,
    required this.in_reply_to_status_id,
    required this.in_reply_to_status_id_str,
    required this.in_reply_to_user_id,
    required this.in_reply_to_user_id_str,
    required this.place,
    required this.retweet_count,
    required this.retweeted,
    required this.source,
    required this.text,
    required this.truncated,
  });

// generated-dart-fixer-start{"md5Hash":"/WSwQOjd0uJ7q63bLHnRfA=="}

  factory VerifyCredentialsStatus.fromJson(Map json) {
    return VerifyCredentialsStatus(
      contributors: json['contributors'],
      coordinates: Coordinates.fromJson((json['coordinates'] as Map).cast()),
      created_at: json['created_at'] as String,
      favorited: json['favorited'] as bool,
      geo: Coordinates.fromJson((json['geo'] as Map).cast()),
      id: json['id'] as double,
      id_str: json['id_str'] as String,
      in_reply_to_screen_name: json['in_reply_to_screen_name'] as String,
      in_reply_to_status_id: json['in_reply_to_status_id'] as double,
      in_reply_to_status_id_str: json['in_reply_to_status_id_str'] as String,
      in_reply_to_user_id: json['in_reply_to_user_id'] as int,
      in_reply_to_user_id_str: json['in_reply_to_user_id_str'] as String,
      place: TwitterPlace.fromJson((json['place'] as Map).cast()),
      retweet_count: json['retweet_count'] as int,
      retweeted: json['retweeted'] as bool,
      source: json['source'] as String,
      text: json['text'] as String,
      truncated: json['truncated'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'contributors': contributors,
      'coordinates': coordinates,
      'created_at': created_at,
      'favorited': favorited,
      'geo': geo,
      'id': id,
      'id_str': id_str,
      'in_reply_to_screen_name': in_reply_to_screen_name,
      'in_reply_to_status_id': in_reply_to_status_id,
      'in_reply_to_status_id_str': in_reply_to_status_id_str,
      'in_reply_to_user_id': in_reply_to_user_id,
      'in_reply_to_user_id_str': in_reply_to_user_id_str,
      'place': place,
      'retweet_count': retweet_count,
      'retweeted': retweeted,
      'source': source,
      'text': text,
      'truncated': truncated,
    };
  }

  @override
  String toString() {
    return "VerifyCredentialsStatus${{
      "contributors": contributors,
      "coordinates": coordinates,
      "created_at": created_at,
      "favorited": favorited,
      "geo": geo,
      "id": id,
      "id_str": id_str,
      "in_reply_to_screen_name": in_reply_to_screen_name,
      "in_reply_to_status_id": in_reply_to_status_id,
      "in_reply_to_status_id_str": in_reply_to_status_id_str,
      "in_reply_to_user_id": in_reply_to_user_id,
      "in_reply_to_user_id_str": in_reply_to_user_id_str,
      "place": place,
      "retweet_count": retweet_count,
      "retweeted": retweeted,
      "source": source,
      "text": text,
      "truncated": truncated,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"/WSwQOjd0uJ7q63bLHnRfA=="}

class Coordinates {
  final List<double> coordinates;
  final String type;

  const Coordinates({
    required this.coordinates,
    required this.type,
  });

// generated-dart-fixer-start{"md5Hash":"1vy9RuSO7oxgmBHivsU9Aw=="}

  factory Coordinates.fromJson(Map json) {
    return Coordinates(
      coordinates:
          (json['coordinates'] as Iterable).map((v) => v as double).toList(),
      type: json['type'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'coordinates': coordinates,
      'type': type,
    };
  }

  @override
  String toString() {
    return "Coordinates${{
      "coordinates": coordinates,
      "type": type,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"1vy9RuSO7oxgmBHivsU9Aw=="}

class TwitterPlace {
  final Attributes attributes;
  final TwitterBoundingBox bounding_box;
  final String country;
  final String country_code;
  final String full_name;
  final String id;
  final String name;
  final String place_type;
  final String url;

  const TwitterPlace({
    required this.attributes,
    required this.bounding_box,
    required this.country,
    required this.country_code,
    required this.full_name,
    required this.id,
    required this.name,
    required this.place_type,
    required this.url,
  });

// generated-dart-fixer-start{"md5Hash":"sVJfSKpZl8zmVqkeyjXRvg=="}

  factory TwitterPlace.fromJson(Map json) {
    return TwitterPlace(
      attributes:
          (json['attributes'] as Map).map((k, v) => MapEntry(k as String, v)),
      bounding_box:
          TwitterBoundingBox.fromJson((json['bounding_box'] as Map).cast()),
      country: json['country'] as String,
      country_code: json['country_code'] as String,
      full_name: json['full_name'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      place_type: json['place_type'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'attributes': attributes,
      'bounding_box': bounding_box,
      'country': country,
      'country_code': country_code,
      'full_name': full_name,
      'id': id,
      'name': name,
      'place_type': place_type,
      'url': url,
    };
  }

  @override
  String toString() {
    return "TwitterPlace${{
      "attributes": attributes,
      "bounding_box": bounding_box,
      "country": country,
      "country_code": country_code,
      "full_name": full_name,
      "id": id,
      "name": name,
      "place_type": place_type,
      "url": url,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"sVJfSKpZl8zmVqkeyjXRvg=="}

class TwitterBoundingBox {
  final List<List<List<double>>> coordinates;
  final String type;

  const TwitterBoundingBox({
    required this.coordinates,
    required this.type,
  });

// generated-dart-fixer-start{"md5Hash":"4aB/b48ZGsxuv7MymL8ElQ=="}

  factory TwitterBoundingBox.fromJson(Map json) {
    return TwitterBoundingBox(
      coordinates: (json['coordinates'] as Iterable)
          .map(
            (v) => (v as Iterable)
                .map((v) => (v as Iterable).map((v) => v as double).toList())
                .toList(),
          )
          .toList(),
      type: json['type'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'coordinates': coordinates,
      'type': type,
    };
  }

  @override
  String toString() {
    return "TwitterBoundingBox${{
      "coordinates": coordinates,
      "type": type,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"4aB/b48ZGsxuv7MymL8ElQ=="}
typedef Attributes = Map<String, Object?>;
