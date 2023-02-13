/// https://developers.facebook.com/docs/graph-api/reference/user#default-public-profile-fields
class FacebookUser {
  /// Básico. Numeric. The app user's App-Scoped User ID. This ID is unique to
  /// the app and cannot be used by other apps.
  final String id;

  /// Básico The person's first name
  final String first_name;

  /// Básico The person's middle name
  final String? middle_name;

  /// Básico The person's last name
  final String last_name;

  /// BásicoPredeterminado The person's full name
  final String name;

  /// The person's name formatted to correctly
  /// handle Chinese, Japanese, or Korean ordering
  final String name_format;

  /// Shortened, locale-aware name for the person
  final String short_name;

  /// Básico The person's profile picture
  final FacebookPictureNode picture;

  /// Básico. The User's primary email address listed on their profile.
  /// This field will not be returned if no valid email address is available.
  final String email;

  /// Is the app making the request installed
  final bool? installed;

  /// Install type
  final String? install_type;

  /// if the current user is a guest user. should always return false.
  final bool? is_guest_user;

  /// Numeric. A profile based app scoped ID. It is used to query avatars
  final String? id_for_avatars;

  /// Básico The age segment for this person expressed as a minimum and maximum age.
  /// For example, more than 18, less than 21.
  final FacebookAgeRange? age_range;

  /// Básico The person's birthday. This is a fixed format String, like MM/DD/YYYY.
  /// However, people can control who can see the year they were born separately
  /// from the month and day so this String can be only the year (YYYY) or the month + day (MM/DD)
  final String? birthday;

  /// Básico The gender selected by this person, male or female.
  /// If the gender is set to a custom value, this value will be based off of
  /// the preferred pronoun; it will be omitted if the preferred pronoun is neutral
  final String? gender;

  /// Facebook Pages representing the languages this person knows
  final List<FacebookExperience>? languages;

  /// Básico A link to the person's Timeline. The link will only resolve if the
  /// person clicking the link is logged into Facebook and is a friend of the
  /// person whose profile is being viewed.
  final String? link;

  /// Básico The person's current location as entered by them on their profile.
  /// This field requires the user_location permission.
  final FacebookPage? location;

  /// The time that the shared login needs to be upgraded to Business Manager by
  final DateTime? shared_login_upgrade_required_by;

  /// The person's hometown
  final FacebookPage? hometown;

  /// Athletes the User likes.
  final List<FacebookExperience>? favorite_athletes;

  /// Sports teams the User likes.
  final List<FacebookExperience>? favorite_teams;

  /// The person's inspirational people
  final List<FacebookExperience>? inspirational_people;

  /// Básico What the person is interested in meeting for
  final List<String>? meeting_for;

  /// The person's payment pricepoints
  final FacebookPaymentPricepoints? payment_pricepoints;

  /// The profile picture URL of the Messenger user. The URL will expire.
  final String? profile_pic;

  /// The person's favorite quotes
  final String? quotes;

  /// The person's significant other
  final FacebookUser? significant_other;

  /// Sports played by the person
  final List<FacebookExperience>? sports;

  /// Whether the user can add a Donate Button to their Live Videos
  final bool? supports_donate_button_in_live_video;

  /// A token that is the same across a business's apps.
  /// Access to this token requires that the person be logged into your app or
  /// have a role on your app. This token will change if the business owning the app changes
  final String? token_for_business;

  /// Video upload limits
  final FacebookVideoUploadLimits? video_upload_limits;

  /// Returns no data as of April 4, 2018.
  // final String about;

  // /// Returns no data as of April 4, 2018.
  // final List<EducationExperience> education;

  // /// Obsoleto A String containing an anonymous, unique identifier for the User, for use with third-parties.
  // Deprecated for versions 3.0+. Apps using older versions of the API can get this field until January 8, 2019. Apps installed by the User on or after May 1st, 2018, cannot get this field.
  // final String third_party_id;

  // /// Obsoleto Updated time
  // final DateTime updated_time;

  // /// Obsoleto Indicates whether the account has been verified. This is distinct from the is_verified field.
  // /// Someone is considered verified if they take any of the following actions:
  // /// * Register for mobile
  // /// * Confirm their account via SMS
  // /// * Enter a valid credit card
  // final bool verified;

  // /// Returns no data as of April 4, 2018.
  // final String website;

  // /// BásicoObsoleto The person's current timezone offset from UTC
  // final double /*float (min = -24) (max: 24)*/ timezone;

  // /// Returns no data as of April 4, 2018.
  // final String political;

  // /// Returns no data as of April 4, 2018.
  // final String relationship_status;

  // /// Obsoleto Daily local news notification
  // final bool local_news_subscription_status;

  // /// Obsoleto Display megaphone for local news bookmark
  // final bool local_news_megaphone_dismiss_status;

  // /// BásicoObsoleto The person's locale
  // final String locale;

  const FacebookUser({
    required this.id,
    required this.first_name,
    this.middle_name,
    required this.last_name,
    required this.name,
    required this.name_format,
    required this.short_name,
    required this.picture,
    required this.email,
    this.installed,
    this.install_type,
    this.is_guest_user,
    this.id_for_avatars,
    this.age_range,
    this.birthday,
    this.gender,
    this.languages,
    this.link,
    this.location,
    this.shared_login_upgrade_required_by,
    this.hometown,
    this.favorite_athletes,
    this.favorite_teams,
    this.inspirational_people,
    this.meeting_for,
    this.payment_pricepoints,
    this.profile_pic,
    this.quotes,
    this.significant_other,
    this.sports,
    this.supports_donate_button_in_live_video,
    this.token_for_business,
    this.video_upload_limits,
  });

// generated-dart-fixer-start{"md5Hash":"2Grj2hhyGO1t2fWFlt9kAw=="}

  factory FacebookUser.fromJson(Map json) {
    return FacebookUser(
      id: json['id'] as String,
      first_name: json['first_name'] as String,
      middle_name: json['middle_name'] as String?,
      last_name: json['last_name'] as String,
      name: json['name'] as String,
      name_format: json['name_format'] as String,
      short_name: json['short_name'] as String,
      picture: FacebookPictureNode.fromJson((json['picture'] as Map).cast()),
      email: json['email'] as String,
      installed: json['installed'] as bool?,
      install_type: json['install_type'] as String?,
      is_guest_user: json['is_guest_user'] as bool?,
      id_for_avatars: json['id_for_avatars'] as String?,
      age_range: json['age_range'] == null
          ? null
          : FacebookAgeRange.fromJson((json['age_range'] as Map).cast()),
      birthday: json['birthday'] as String?,
      gender: json['gender'] as String?,
      languages: json['languages'] == null
          ? null
          : (json['languages'] as Iterable)
              .map((v) => FacebookExperience.fromJson((v as Map).cast()))
              .toList(),
      link: json['link'] as String?,
      location:
          (json['location'] as Map).map((k, v) => MapEntry(k as String, v)),
      shared_login_upgrade_required_by:
          json['shared_login_upgrade_required_by'] == null
              ? null
              : DateTime.parse(
                  json['shared_login_upgrade_required_by'] as String,
                ),
      hometown:
          (json['hometown'] as Map).map((k, v) => MapEntry(k as String, v)),
      favorite_athletes: json['favorite_athletes'] == null
          ? null
          : (json['favorite_athletes'] as Iterable)
              .map((v) => FacebookExperience.fromJson((v as Map).cast()))
              .toList(),
      favorite_teams: json['favorite_teams'] == null
          ? null
          : (json['favorite_teams'] as Iterable)
              .map((v) => FacebookExperience.fromJson((v as Map).cast()))
              .toList(),
      inspirational_people: json['inspirational_people'] == null
          ? null
          : (json['inspirational_people'] as Iterable)
              .map((v) => FacebookExperience.fromJson((v as Map).cast()))
              .toList(),
      meeting_for: json['meeting_for'] == null
          ? null
          : (json['meeting_for'] as Iterable).map((v) => v as String).toList(),
      payment_pricepoints: (json['payment_pricepoints'] as Map)
          .map((k, v) => MapEntry(k as String, v)),
      profile_pic: json['profile_pic'] as String?,
      quotes: json['quotes'] as String?,
      significant_other: json['significant_other'] == null
          ? null
          : FacebookUser.fromJson((json['significant_other'] as Map).cast()),
      sports: json['sports'] == null
          ? null
          : (json['sports'] as Iterable)
              .map((v) => FacebookExperience.fromJson((v as Map).cast()))
              .toList(),
      supports_donate_button_in_live_video:
          json['supports_donate_button_in_live_video'] as bool?,
      token_for_business: json['token_for_business'] as String?,
      video_upload_limits: json['video_upload_limits'] == null
          ? null
          : FacebookVideoUploadLimits.fromJson(
              (json['video_upload_limits'] as Map).cast(),
            ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'first_name': first_name,
      'middle_name': middle_name,
      'last_name': last_name,
      'name': name,
      'name_format': name_format,
      'short_name': short_name,
      'picture': picture,
      'email': email,
      'installed': installed,
      'install_type': install_type,
      'is_guest_user': is_guest_user,
      'id_for_avatars': id_for_avatars,
      'age_range': age_range,
      'birthday': birthday,
      'gender': gender,
      'languages': languages?.map((v) => v).toList(),
      'link': link,
      'location': location,
      'shared_login_upgrade_required_by':
          shared_login_upgrade_required_by?.toIso8601String(),
      'hometown': hometown,
      'favorite_athletes': favorite_athletes?.map((v) => v).toList(),
      'favorite_teams': favorite_teams?.map((v) => v).toList(),
      'inspirational_people': inspirational_people?.map((v) => v).toList(),
      'meeting_for': meeting_for,
      'payment_pricepoints': payment_pricepoints,
      'profile_pic': profile_pic,
      'quotes': quotes,
      'significant_other': significant_other,
      'sports': sports?.map((v) => v).toList(),
      'supports_donate_button_in_live_video':
          supports_donate_button_in_live_video,
      'token_for_business': token_for_business,
      'video_upload_limits': video_upload_limits,
    };
  }

  @override
  String toString() {
    return "FacebookUser${{
      "id": id,
      "first_name": first_name,
      "middle_name": middle_name,
      "last_name": last_name,
      "name": name,
      "name_format": name_format,
      "short_name": short_name,
      "picture": picture,
      "email": email,
      "installed": installed,
      "install_type": install_type,
      "is_guest_user": is_guest_user,
      "id_for_avatars": id_for_avatars,
      "age_range": age_range,
      "birthday": birthday,
      "gender": gender,
      "languages": languages,
      "link": link,
      "location": location,
      "shared_login_upgrade_required_by": shared_login_upgrade_required_by,
      "hometown": hometown,
      "favorite_athletes": favorite_athletes,
      "favorite_teams": favorite_teams,
      "inspirational_people": inspirational_people,
      "meeting_for": meeting_for,
      "payment_pricepoints": payment_pricepoints,
      "profile_pic": profile_pic,
      "quotes": quotes,
      "significant_other": significant_other,
      "sports": sports,
      "supports_donate_button_in_live_video":
          supports_donate_button_in_live_video,
      "token_for_business": token_for_business,
      "video_upload_limits": video_upload_limits,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"2Grj2hhyGO1t2fWFlt9kAw=="}

/// https://developers.facebook.com/docs/graph-api/reference/page/
typedef FacebookPage = Map<String, Object?>;

/// https://developers.facebook.com/docs/graph-api/reference/payment-pricepoints/
typedef FacebookPaymentPricepoints = Map<String, Object?>;

/// https://developers.facebook.com/docs/graph-api/reference/experience/
class FacebookExperience {
  /// IDnumeric string
  final String id;

  /// Description
  final String description;

  /// From
  final Object? from;

  /// Name
  final String name;

  /// Tagged users
  final List<FacebookUser> with$;

  const FacebookExperience({
    required this.id,
    required this.description,
    this.from,
    required this.name,
    required this.with$,
  });

// generated-dart-fixer-start{"md5Hash":"o0+1hc/YQe8Qdv+WAra/ww=="}

  factory FacebookExperience.fromJson(Map json) {
    return FacebookExperience(
      id: json['id'] as String,
      description: json['description'] as String,
      from: json['from'],
      name: json['name'] as String,
      with$: (json['with'] as Iterable)
          .map((v) => FacebookUser.fromJson((v as Map).cast()))
          .toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'description': description,
      'from': from,
      'name': name,
      'with': with$.map((v) => v).toList(),
    };
  }

  @override
  String toString() {
    return "FacebookExperience${{
      "id": id,
      "description": description,
      "from": from,
      "name": name,
      "with": with$,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"o0+1hc/YQe8Qdv+WAra/ww=="}

class FacebookVideoUploadLimits {
  /// Length
  final int length;

  /// Size
  final int size;

  const FacebookVideoUploadLimits({
    required this.length,
    required this.size,
  });

// generated-dart-fixer-start{"md5Hash":"xOSRNxNUben4mBj1KZoIyQ=="}

  factory FacebookVideoUploadLimits.fromJson(Map json) {
    return FacebookVideoUploadLimits(
      length: json['length'] as int,
      size: json['size'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'length': length,
      'size': size,
    };
  }

  @override
  String toString() {
    return "FacebookVideoUploadLimits${{
      "length": length,
      "size": size,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"xOSRNxNUben4mBj1KZoIyQ=="}

class FacebookAgeRange {
  /// Predeterminado The upper bounds of the range for this person's age. enum{17, 20, or empty}.
  final int? max;

  /// The lower bounds of the range for this person's age. enum{13, 18, 21}
  final int min;

  const FacebookAgeRange({
    this.max,
    required this.min,
  });
// generated-dart-fixer-start{"md5Hash":"276yPLchwFJp5HJtg1+qPA=="}

  factory FacebookAgeRange.fromJson(Map json) {
    return FacebookAgeRange(
      max: json['max'] as int?,
      min: json['min'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'max': max,
      'min': min,
    };
  }

  @override
  String toString() {
    return "FacebookAgeRange${{
      "max": max,
      "min": min,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"276yPLchwFJp5HJtg1+qPA=="}

class FacebookPictureNode {
  final FacebookPicture data;

  const FacebookPictureNode({required this.data});
// generated-dart-fixer-start{"md5Hash":"25fIUL3/a0V0gsHAauC7vQ=="}

  factory FacebookPictureNode.fromJson(Map json) {
    return FacebookPictureNode(
      data: FacebookPicture.fromJson((json['data'] as Map).cast()),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'data': data,
    };
  }

  @override
  String toString() {
    return "FacebookPictureNode${{
      "data": data,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"25fIUL3/a0V0gsHAauC7vQ=="}

class FacebookPicture {
  /// A key to identify the profile picture for the purpose of
  /// invalidating the image cache
  final String? cache_key;

  /// Predeterminado Picture height in pixels.
  /// Only returned when specified as a modifier
  final int /*unsigned int32*/ height;

  /// Predeterminado True if the profile picture is the default 'silhouette' picture
  final bool is_silhouette;

  /// Predeterminado URL of the profile picture. The URL will expire.
  final String url;

  /// Predeterminado Picture width in pixels.
  /// Only returned when specified as a modifier
  final int /*unsigned int32*/ width;

  const FacebookPicture({
    this.cache_key,
    required this.height,
    required this.is_silhouette,
    required this.url,
    required this.width,
  });
// generated-dart-fixer-start{"md5Hash":"lL72tkT61XPX4+jBx3S17g=="}

  factory FacebookPicture.fromJson(Map json) {
    return FacebookPicture(
      cache_key: json['cache_key'] as String?,
      height: json['height'] as int,
      is_silhouette: json['is_silhouette'] as bool,
      url: json['url'] as String,
      width: json['width'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'cache_key': cache_key,
      'height': height,
      'is_silhouette': is_silhouette,
      'url': url,
      'width': width,
    };
  }

  @override
  String toString() {
    return "FacebookPicture${{
      "cache_key": cache_key,
      "height": height,
      "is_silhouette": is_silhouette,
      "url": url,
      "width": width,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"lL72tkT61XPX4+jBx3S17g=="}
