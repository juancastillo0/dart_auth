// generated-dart-fixer-json{"from":"./reddit.schema.json","kind":"schema","md5Hash":"1ieTS9ZT6cdby7FlKUAzaw=="}

class RedditUser {
  /// The subreddit where the user was last seen
  final String? subreddit;

  /// The number of unread messages in the user's inbox
  final int? inboxCount;

  /// Whether the user is a Reddit employee
  final bool? isEmployee;

  /// Whether the user has visited the new profile page
  final bool? hasVisitedNewProfile;

  /// Whether to show the user's Snoovatar
  final bool? prefShowSnoovatar;

  /// The user's username
  final String name;

  /// Whether the user has a Reddit Gold subscription
  final bool? isGold;

  /// The user's unique ID
  final String id;

  /// Whether the user has subscribed to any subreddits
  final bool? hasSubscribed;

  /// Whether to filter out profanity in comments
  final bool? prefNoProfanity;

  /// Whether the user is suspended from Reddit
  final bool? isSuspended;

  /// Whether to show geopopular subreddits on the home feed
  final bool? prefGeopopular;

  /// Whether the user has verified their email address
  final bool? hasVerifiedEmail;

  /// Whether the user is a moderator of any subreddits
  final bool? isModerator;

  /// Whether to automatically play videos on Reddit
  final bool? prefVideoAutoplay;

  /// The user's total awarder karma
  final int? awarderKarma;

  /// The user's total comment karma
  final int? commentKarma;

  /// Whether the user has been verified by Reddit
  final bool? hasVerified;

  /// Whether to show trending posts on the home feed
  final bool? prefShowTrending;

  /// Whether the user is part of the Reddit beta program
  final bool? isBeta;

  /// Whether the user has an ad blocker enabled
  final bool? isAdBlocked;

  /// The URL of the user's icon image
  final String? iconImg;

  /// The user's total karma
  final int? totalKarma;

  /// A boolean value indicating whether the user has night mode preference
  /// enabled.
  final bool? prefNightmode;

  /// A double representing the UTC timestamp of when the user's account was
  /// created.
  final int? created;

  /// A boolean value indicating whether the user has unread mail.
  final bool? hasMail;

  /// A boolean value indicating whether the user is a sponsor.
  final bool? isSponsor;

  /// An integer representing the link karma of the user.
  final int? linkKarma;

  /// A boolean value indicating whether the user has autoplay preference
  /// enabled.
  final bool? prefAutoplay;

  /// A boolean value indicating whether the user is over 18 years old.
  final bool? over_18;

  const RedditUser({
    this.subreddit,
    this.inboxCount,
    this.isEmployee,
    this.hasVisitedNewProfile,
    this.prefShowSnoovatar,
    required this.name,
    this.isGold,
    required this.id,
    this.hasSubscribed,
    this.prefNoProfanity,
    this.isSuspended,
    this.prefGeopopular,
    this.hasVerifiedEmail,
    this.isModerator,
    this.prefVideoAutoplay,
    this.awarderKarma,
    this.commentKarma,
    this.hasVerified,
    this.prefShowTrending,
    this.isBeta,
    this.isAdBlocked,
    this.iconImg,
    this.totalKarma,
    this.prefNightmode,
    this.created,
    this.hasMail,
    this.isSponsor,
    this.linkKarma,
    this.prefAutoplay,
    this.over_18,
  });

// generated-dart-fixer-start{"jsonKeyCase":"snake_case","md5Hash":"Sgrtq4pTsVjKhWERGUAxsg=="}

  factory RedditUser.fromJson(Map json) {
    return RedditUser(
      subreddit: json['subreddit'] as String?,
      inboxCount: json['inbox_count'] as int?,
      isEmployee: json['is_employee'] as bool?,
      hasVisitedNewProfile: json['has_visited_new_profile'] as bool?,
      prefShowSnoovatar: json['pref_show_snoovatar'] as bool?,
      name: json['name'] as String,
      isGold: json['is_gold'] as bool?,
      id: json['id'] as String,
      hasSubscribed: json['has_subscribed'] as bool?,
      prefNoProfanity: json['pref_no_profanity'] as bool?,
      isSuspended: json['is_suspended'] as bool?,
      prefGeopopular: json['pref_geopopular'] as bool?,
      hasVerifiedEmail: json['has_verified_email'] as bool?,
      isModerator: json['is_moderator'] as bool?,
      prefVideoAutoplay: json['pref_video_autoplay'] as bool?,
      awarderKarma: json['awarder_karma'] as int?,
      commentKarma: json['comment_karma'] as int?,
      hasVerified: json['has_verified'] as bool?,
      prefShowTrending: json['pref_show_trending'] as bool?,
      isBeta: json['is_beta'] as bool?,
      isAdBlocked: json['is_ad_blocked'] as bool?,
      iconImg: json['icon_img'] as String?,
      totalKarma: json['total_karma'] as int?,
      prefNightmode: json['pref_nightmode'] as bool?,
      created: json['created'] as int?,
      hasMail: json['has_mail'] as bool?,
      isSponsor: json['is_sponsor'] as bool?,
      linkKarma: json['link_karma'] as int?,
      prefAutoplay: json['pref_autoplay'] as bool?,
      over_18: json['over_18'] as bool?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'subreddit': subreddit,
      'inbox_count': inboxCount,
      'is_employee': isEmployee,
      'has_visited_new_profile': hasVisitedNewProfile,
      'pref_show_snoovatar': prefShowSnoovatar,
      'name': name,
      'is_gold': isGold,
      'id': id,
      'has_subscribed': hasSubscribed,
      'pref_no_profanity': prefNoProfanity,
      'is_suspended': isSuspended,
      'pref_geopopular': prefGeopopular,
      'has_verified_email': hasVerifiedEmail,
      'is_moderator': isModerator,
      'pref_video_autoplay': prefVideoAutoplay,
      'awarder_karma': awarderKarma,
      'comment_karma': commentKarma,
      'has_verified': hasVerified,
      'pref_show_trending': prefShowTrending,
      'is_beta': isBeta,
      'is_ad_blocked': isAdBlocked,
      'icon_img': iconImg,
      'total_karma': totalKarma,
      'pref_nightmode': prefNightmode,
      'created': created,
      'has_mail': hasMail,
      'is_sponsor': isSponsor,
      'link_karma': linkKarma,
      'pref_autoplay': prefAutoplay,
      'over_18': over_18,
    };
  }

  @override
  String toString() {
    return "RedditUser${{
      "subreddit": subreddit,
      "inboxCount": inboxCount,
      "isEmployee": isEmployee,
      "hasVisitedNewProfile": hasVisitedNewProfile,
      "prefShowSnoovatar": prefShowSnoovatar,
      "name": name,
      "isGold": isGold,
      "id": id,
      "hasSubscribed": hasSubscribed,
      "prefNoProfanity": prefNoProfanity,
      "isSuspended": isSuspended,
      "prefGeopopular": prefGeopopular,
      "hasVerifiedEmail": hasVerifiedEmail,
      "isModerator": isModerator,
      "prefVideoAutoplay": prefVideoAutoplay,
      "awarderKarma": awarderKarma,
      "commentKarma": commentKarma,
      "hasVerified": hasVerified,
      "prefShowTrending": prefShowTrending,
      "isBeta": isBeta,
      "isAdBlocked": isAdBlocked,
      "iconImg": iconImg,
      "totalKarma": totalKarma,
      "prefNightmode": prefNightmode,
      "created": created,
      "hasMail": hasMail,
      "isSponsor": isSponsor,
      "linkKarma": linkKarma,
      "prefAutoplay": prefAutoplay,
      "over_18": over_18,
    }}";
  }
}


// generated-dart-fixer-end{"jsonKeyCase":"snake_case","md5Hash":"Sgrtq4pTsVjKhWERGUAxsg=="}

