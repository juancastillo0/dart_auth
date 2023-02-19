// generated-dart-fixer-json{"from":"./github-token.schema.json","kind":"schema","md5Hash":"vxGH0pDg31BSBnJXhdE31A=="}

// ignore_for_file: always_put_required_named_parameters_first, non_constant_identifier_names

class GithubTokenApp {
  final String client_id;
  final String name;
  final String url;

  const GithubTokenApp({
    required this.client_id,
    required this.name,
    required this.url,
  });
// generated-dart-fixer-start{"md5Hash":"gjlEnRZ/Igeu8FgAXT7rnQ=="}

  factory GithubTokenApp.fromJson(Map json) {
    return GithubTokenApp(
      client_id: json['client_id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'client_id': client_id,
      'name': name,
      'url': url,
    };
  }

  GithubTokenApp copyWith({
    String? client_id,
    String? name,
    String? url,
  }) {
    return GithubTokenApp(
      client_id: client_id ?? this.client_id,
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is GithubTokenApp &&
            other.runtimeType == runtimeType &&
            other.client_id == client_id &&
            other.name == name &&
            other.url == url;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      client_id,
      name,
      url,
    ]);
  }

  @override
  String toString() {
    return "GithubTokenApp${{
      "client_id": client_id,
      "name": name,
      "url": url,
    }}";
  }

  List<Object?> get props => [
        client_id,
        name,
        url,
      ];
}

// generated-dart-fixer-end{"md5Hash":"gjlEnRZ/Igeu8FgAXT7rnQ=="}

/// A GitHub user.
class GithubTokenUser {
  final String? name;
  final String? email;

  /// #### Example
  /// ```json
  /// "octocat"
  /// ```
  final String login;

  /// #### Example
  /// ```json
  /// 1
  /// ```
  final int id;

  /// #### Example
  /// ```json
  /// "MDQ6VXNlcjE="
  /// ```
  final String node_id;

  /// #### Example
  /// ```json
  /// "https://github.com/images/error/octocat_happy.gif"
  /// ```
  final String avatar_url;

  /// #### Example
  /// ```json
  /// "41d064eb2195891e12d0413f63227ea7"
  /// ```
  final String? gravatar_id;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat"
  /// ```
  final String url;

  /// #### Example
  /// ```json
  /// "https://github.com/octocat"
  /// ```
  final String html_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/followers"
  /// ```
  final String followers_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/following{/other_user}"
  /// ```
  final String following_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/gists{/gist_id}"
  /// ```
  final String gists_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/starred{/owner}{/repo}"
  /// ```
  final String starred_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/subscriptions"
  /// ```
  final String subscriptions_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/orgs"
  /// ```
  final String organizations_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/repos"
  /// ```
  final String repos_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/events{/privacy}"
  /// ```
  final String events_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/received_events"
  /// ```
  final String received_events_url;

  /// #### Example
  /// ```json
  /// "User"
  /// ```
  final String type;
  final bool site_admin;

  /// #### Example
  /// ```json
  /// "\"2020-07-09T00:17:55Z\""
  /// ```
  final String? starred_at;

  /// A GitHub user.
  const GithubTokenUser({
    this.name,
    this.email,
    required this.login,
    required this.id,
    required this.node_id,
    required this.avatar_url,
    this.gravatar_id,
    required this.url,
    required this.html_url,
    required this.followers_url,
    required this.following_url,
    required this.gists_url,
    required this.starred_url,
    required this.subscriptions_url,
    required this.organizations_url,
    required this.repos_url,
    required this.events_url,
    required this.received_events_url,
    required this.type,
    required this.site_admin,
    this.starred_at,
  });
// generated-dart-fixer-start{"md5Hash":"xP1Mn2qhonw7A0BKbMJ8bQ=="}

  factory GithubTokenUser.fromJson(Map json) {
    return GithubTokenUser(
      name: json['name'] as String?,
      email: json['email'] as String?,
      login: json['login'] as String,
      id: json['id'] as int,
      node_id: json['node_id'] as String,
      avatar_url: json['avatar_url'] as String,
      gravatar_id: json['gravatar_id'] as String?,
      url: json['url'] as String,
      html_url: json['html_url'] as String,
      followers_url: json['followers_url'] as String,
      following_url: json['following_url'] as String,
      gists_url: json['gists_url'] as String,
      starred_url: json['starred_url'] as String,
      subscriptions_url: json['subscriptions_url'] as String,
      organizations_url: json['organizations_url'] as String,
      repos_url: json['repos_url'] as String,
      events_url: json['events_url'] as String,
      received_events_url: json['received_events_url'] as String,
      type: json['type'] as String,
      site_admin: json['site_admin'] as bool,
      starred_at: json['starred_at'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'email': email,
      'login': login,
      'id': id,
      'node_id': node_id,
      'avatar_url': avatar_url,
      'gravatar_id': gravatar_id,
      'url': url,
      'html_url': html_url,
      'followers_url': followers_url,
      'following_url': following_url,
      'gists_url': gists_url,
      'starred_url': starred_url,
      'subscriptions_url': subscriptions_url,
      'organizations_url': organizations_url,
      'repos_url': repos_url,
      'events_url': events_url,
      'received_events_url': received_events_url,
      'type': type,
      'site_admin': site_admin,
      'starred_at': starred_at,
    };
  }

  GithubTokenUser copyWith({
    String? name,
    bool nameToNull = false,
    String? email,
    bool emailToNull = false,
    String? login,
    int? id,
    String? node_id,
    String? avatar_url,
    String? gravatar_id,
    bool gravatar_idToNull = false,
    String? url,
    String? html_url,
    String? followers_url,
    String? following_url,
    String? gists_url,
    String? starred_url,
    String? subscriptions_url,
    String? organizations_url,
    String? repos_url,
    String? events_url,
    String? received_events_url,
    String? type,
    bool? site_admin,
    String? starred_at,
    bool starred_atToNull = false,
  }) {
    return GithubTokenUser(
      name: name ?? (nameToNull ? null : this.name),
      email: email ?? (emailToNull ? null : this.email),
      login: login ?? this.login,
      id: id ?? this.id,
      node_id: node_id ?? this.node_id,
      avatar_url: avatar_url ?? this.avatar_url,
      gravatar_id: gravatar_id ?? (gravatar_idToNull ? null : this.gravatar_id),
      url: url ?? this.url,
      html_url: html_url ?? this.html_url,
      followers_url: followers_url ?? this.followers_url,
      following_url: following_url ?? this.following_url,
      gists_url: gists_url ?? this.gists_url,
      starred_url: starred_url ?? this.starred_url,
      subscriptions_url: subscriptions_url ?? this.subscriptions_url,
      organizations_url: organizations_url ?? this.organizations_url,
      repos_url: repos_url ?? this.repos_url,
      events_url: events_url ?? this.events_url,
      received_events_url: received_events_url ?? this.received_events_url,
      type: type ?? this.type,
      site_admin: site_admin ?? this.site_admin,
      starred_at: starred_at ?? (starred_atToNull ? null : this.starred_at),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is GithubTokenUser &&
            other.runtimeType == runtimeType &&
            other.name == name &&
            other.email == email &&
            other.login == login &&
            other.id == id &&
            other.node_id == node_id &&
            other.avatar_url == avatar_url &&
            other.gravatar_id == gravatar_id &&
            other.url == url &&
            other.html_url == html_url &&
            other.followers_url == followers_url &&
            other.following_url == following_url &&
            other.gists_url == gists_url &&
            other.starred_url == starred_url &&
            other.subscriptions_url == subscriptions_url &&
            other.organizations_url == organizations_url &&
            other.repos_url == repos_url &&
            other.events_url == events_url &&
            other.received_events_url == received_events_url &&
            other.type == type &&
            other.site_admin == site_admin &&
            other.starred_at == starred_at;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      name,
      email,
      login,
      id,
      node_id,
      avatar_url,
      gravatar_id,
      url,
      html_url,
      followers_url,
      following_url,
      gists_url,
      starred_url,
      subscriptions_url,
      organizations_url,
      repos_url,
      events_url,
      received_events_url,
      type,
      site_admin,
      starred_at,
    ]);
  }

  @override
  String toString() {
    return "GithubTokenUser${{
      "name": name,
      "email": email,
      "login": login,
      "id": id,
      "node_id": node_id,
      "avatar_url": avatar_url,
      "gravatar_id": gravatar_id,
      "url": url,
      "html_url": html_url,
      "followers_url": followers_url,
      "following_url": following_url,
      "gists_url": gists_url,
      "starred_url": starred_url,
      "subscriptions_url": subscriptions_url,
      "organizations_url": organizations_url,
      "repos_url": repos_url,
      "events_url": events_url,
      "received_events_url": received_events_url,
      "type": type,
      "site_admin": site_admin,
      "starred_at": starred_at,
    }}";
  }

  List<Object?> get props => [
        name,
        email,
        login,
        id,
        node_id,
        avatar_url,
        gravatar_id,
        url,
        html_url,
        followers_url,
        following_url,
        gists_url,
        starred_url,
        subscriptions_url,
        organizations_url,
        repos_url,
        events_url,
        received_events_url,
        type,
        site_admin,
        starred_at,
      ];
}

// generated-dart-fixer-end{"md5Hash":"xP1Mn2qhonw7A0BKbMJ8bQ=="}

/// The permissions granted to the user-to-server access token.
class GithubTokenInstallationPermissions {
  /// The level of permission to grant the access token for GitHub Actions workflows, workflow runs, and artifacts.
  final GithubTokenInstallationPermissionsActions? actions;

  /// The level of permission to grant the access token for repository creation, deletion, settings, teams, and collaborators creation.
  final GithubTokenInstallationPermissionsAdministration? administration;

  /// The level of permission to grant the access token for checks on code.
  final GithubTokenInstallationPermissionsChecks? checks;

  /// The level of permission to grant the access token for repository contents, commits, branches, downloads, releases, and merges.
  final GithubTokenInstallationPermissionsContents? contents;

  /// The level of permission to grant the access token for deployments and deployment statuses.
  final GithubTokenInstallationPermissionsDeployments? deployments;

  /// The level of permission to grant the access token for managing repository environments.
  final GithubTokenInstallationPermissionsEnvironments? environments;

  /// The level of permission to grant the access token for issues and related comments, assignees, labels, and milestones.
  final GithubTokenInstallationPermissionsIssues? issues;

  /// The level of permission to grant the access token to search repositories, list collaborators, and access repository metadata.
  final GithubTokenInstallationPermissionsMetadata? metadata;

  /// The level of permission to grant the access token for packages published to GitHub Packages.
  final GithubTokenInstallationPermissionsPackages? packages;

  /// The level of permission to grant the access token to retrieve Pages statuses, configuration, and builds, as well as create new builds.
  final GithubTokenInstallationPermissionsPages? pages;

  /// The level of permission to grant the access token for pull requests and related comments, assignees, labels, milestones, and merges.
  final GithubTokenInstallationPermissionsPullRequests? pull_requests;

  /// The level of permission to grant the access token to view and manage announcement banners for a repository.
  final GithubTokenInstallationPermissionsRepositoryAnnouncementBanners?
      repository_announcement_banners;

  /// The level of permission to grant the access token to manage the post-receive hooks for a repository.
  final GithubTokenInstallationPermissionsRepositoryHooks? repository_hooks;

  /// The level of permission to grant the access token to manage repository projects, columns, and cards.
  final GithubTokenInstallationPermissionsRepositoryProjects?
      repository_projects;

  /// The level of permission to grant the access token to view and manage secret scanning alerts.
  final GithubTokenInstallationPermissionsSecretScanningAlerts?
      secret_scanning_alerts;

  /// The level of permission to grant the access token to manage repository secrets.
  final GithubTokenInstallationPermissionsSecrets? secrets;

  /// The level of permission to grant the access token to view and manage security events like code scanning alerts.
  final GithubTokenInstallationPermissionsSecurityEvents? security_events;

  /// The level of permission to grant the access token to manage just a single file.
  final GithubTokenInstallationPermissionsSingleFile? single_file;

  /// The level of permission to grant the access token for commit statuses.
  final GithubTokenInstallationPermissionsStatuses? statuses;

  /// The level of permission to grant the access token to manage Dependabot alerts.
  final GithubTokenInstallationPermissionsVulnerabilityAlerts?
      vulnerability_alerts;

  /// The level of permission to grant the access token to update GitHub Actions workflow files.
  final GithubTokenInstallationPermissionsWorkflows? workflows;

  /// The level of permission to grant the access token for organization teams and members.
  final GithubTokenInstallationPermissionsMembers? members;

  /// The level of permission to grant the access token to manage access to an organization.
  final GithubTokenInstallationPermissionsOrganizationAdministration?
      organization_administration;

  /// The level of permission to grant the access token for custom repository roles management. This property is in beta and is subject to change.
  final GithubTokenInstallationPermissionsOrganizationCustomRoles?
      organization_custom_roles;

  /// The level of permission to grant the access token to view and manage announcement banners for an organization.
  final GithubTokenInstallationPermissionsOrganizationAnnouncementBanners?
      organization_announcement_banners;

  /// The level of permission to grant the access token to manage the post-receive hooks for an organization.
  final GithubTokenInstallationPermissionsOrganizationHooks? organization_hooks;

  /// The level of permission to grant the access token for viewing an organization's plan.
  final GithubTokenInstallationPermissionsOrganizationPlan? organization_plan;

  /// The level of permission to grant the access token to manage organization projects and projects beta (where available).
  final GithubTokenInstallationPermissionsOrganizationProjects?
      organization_projects;

  /// The level of permission to grant the access token for organization packages published to GitHub Packages.
  final GithubTokenInstallationPermissionsOrganizationPackages?
      organization_packages;

  /// The level of permission to grant the access token to manage organization secrets.
  final GithubTokenInstallationPermissionsOrganizationSecrets?
      organization_secrets;

  /// The level of permission to grant the access token to view and manage GitHub Actions self-hosted runners available to an organization.
  final GithubTokenInstallationPermissionsOrganizationSelfHostedRunners?
      organization_self_hosted_runners;

  /// The level of permission to grant the access token to view and manage users blocked by the organization.
  final GithubTokenInstallationPermissionsOrganizationUserBlocking?
      organization_user_blocking;

  /// The level of permission to grant the access token to manage team discussions and related comments.
  final GithubTokenInstallationPermissionsTeamDiscussions? team_discussions;

  /// The permissions granted to the user-to-server access token.
  const GithubTokenInstallationPermissions({
    this.actions,
    this.administration,
    this.checks,
    this.contents,
    this.deployments,
    this.environments,
    this.issues,
    this.metadata,
    this.packages,
    this.pages,
    this.pull_requests,
    this.repository_announcement_banners,
    this.repository_hooks,
    this.repository_projects,
    this.secret_scanning_alerts,
    this.secrets,
    this.security_events,
    this.single_file,
    this.statuses,
    this.vulnerability_alerts,
    this.workflows,
    this.members,
    this.organization_administration,
    this.organization_custom_roles,
    this.organization_announcement_banners,
    this.organization_hooks,
    this.organization_plan,
    this.organization_projects,
    this.organization_packages,
    this.organization_secrets,
    this.organization_self_hosted_runners,
    this.organization_user_blocking,
    this.team_discussions,
  });
// generated-dart-fixer-start{"md5Hash":"LdKrAc+sO1aXwzUki1U20g=="}

  factory GithubTokenInstallationPermissions.fromJson(Map json) {
    return GithubTokenInstallationPermissions(
      actions: json['actions'] == null
          ? null
          : GithubTokenInstallationPermissionsActions.fromJson(
              json['actions'] as Object?,
            ),
      administration: json['administration'] == null
          ? null
          : GithubTokenInstallationPermissionsAdministration.fromJson(
              json['administration'] as Object?,
            ),
      checks: json['checks'] == null
          ? null
          : GithubTokenInstallationPermissionsChecks.fromJson(
              json['checks'] as Object?,
            ),
      contents: json['contents'] == null
          ? null
          : GithubTokenInstallationPermissionsContents.fromJson(
              json['contents'] as Object?,
            ),
      deployments: json['deployments'] == null
          ? null
          : GithubTokenInstallationPermissionsDeployments.fromJson(
              json['deployments'] as Object?,
            ),
      environments: json['environments'] == null
          ? null
          : GithubTokenInstallationPermissionsEnvironments.fromJson(
              json['environments'] as Object?,
            ),
      issues: json['issues'] == null
          ? null
          : GithubTokenInstallationPermissionsIssues.fromJson(
              json['issues'] as Object?,
            ),
      metadata: json['metadata'] == null
          ? null
          : GithubTokenInstallationPermissionsMetadata.fromJson(
              json['metadata'] as Object?,
            ),
      packages: json['packages'] == null
          ? null
          : GithubTokenInstallationPermissionsPackages.fromJson(
              json['packages'] as Object?,
            ),
      pages: json['pages'] == null
          ? null
          : GithubTokenInstallationPermissionsPages.fromJson(
              json['pages'] as Object?,
            ),
      pull_requests: json['pull_requests'] == null
          ? null
          : GithubTokenInstallationPermissionsPullRequests.fromJson(
              json['pull_requests'] as Object?,
            ),
      repository_announcement_banners:
          json['repository_announcement_banners'] == null
              ? null
              : GithubTokenInstallationPermissionsRepositoryAnnouncementBanners
                  .fromJson(json['repository_announcement_banners'] as Object?),
      repository_hooks: json['repository_hooks'] == null
          ? null
          : GithubTokenInstallationPermissionsRepositoryHooks.fromJson(
              json['repository_hooks'] as Object?,
            ),
      repository_projects: json['repository_projects'] == null
          ? null
          : GithubTokenInstallationPermissionsRepositoryProjects.fromJson(
              json['repository_projects'] as Object?,
            ),
      secret_scanning_alerts: json['secret_scanning_alerts'] == null
          ? null
          : GithubTokenInstallationPermissionsSecretScanningAlerts.fromJson(
              json['secret_scanning_alerts'] as Object?,
            ),
      secrets: json['secrets'] == null
          ? null
          : GithubTokenInstallationPermissionsSecrets.fromJson(
              json['secrets'] as Object?,
            ),
      security_events: json['security_events'] == null
          ? null
          : GithubTokenInstallationPermissionsSecurityEvents.fromJson(
              json['security_events'] as Object?,
            ),
      single_file: json['single_file'] == null
          ? null
          : GithubTokenInstallationPermissionsSingleFile.fromJson(
              json['single_file'] as Object?,
            ),
      statuses: json['statuses'] == null
          ? null
          : GithubTokenInstallationPermissionsStatuses.fromJson(
              json['statuses'] as Object?,
            ),
      vulnerability_alerts: json['vulnerability_alerts'] == null
          ? null
          : GithubTokenInstallationPermissionsVulnerabilityAlerts.fromJson(
              json['vulnerability_alerts'] as Object?,
            ),
      workflows: json['workflows'] == null
          ? null
          : GithubTokenInstallationPermissionsWorkflows.fromJson(
              json['workflows'] as Object?,
            ),
      members: json['members'] == null
          ? null
          : GithubTokenInstallationPermissionsMembers.fromJson(
              json['members'] as Object?,
            ),
      organization_administration: json['organization_administration'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationAdministration
              .fromJson(json['organization_administration'] as Object?),
      organization_custom_roles: json['organization_custom_roles'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationCustomRoles.fromJson(
              json['organization_custom_roles'] as Object?,
            ),
      organization_announcement_banners: json[
                  'organization_announcement_banners'] ==
              null
          ? null
          : GithubTokenInstallationPermissionsOrganizationAnnouncementBanners
              .fromJson(json['organization_announcement_banners'] as Object?),
      organization_hooks: json['organization_hooks'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationHooks.fromJson(
              json['organization_hooks'] as Object?,
            ),
      organization_plan: json['organization_plan'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationPlan.fromJson(
              json['organization_plan'] as Object?,
            ),
      organization_projects: json['organization_projects'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationProjects.fromJson(
              json['organization_projects'] as Object?,
            ),
      organization_packages: json['organization_packages'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationPackages.fromJson(
              json['organization_packages'] as Object?,
            ),
      organization_secrets: json['organization_secrets'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationSecrets.fromJson(
              json['organization_secrets'] as Object?,
            ),
      organization_self_hosted_runners:
          json['organization_self_hosted_runners'] == null
              ? null
              : GithubTokenInstallationPermissionsOrganizationSelfHostedRunners
                  .fromJson(
                  json['organization_self_hosted_runners'] as Object?,
                ),
      organization_user_blocking: json['organization_user_blocking'] == null
          ? null
          : GithubTokenInstallationPermissionsOrganizationUserBlocking.fromJson(
              json['organization_user_blocking'] as Object?,
            ),
      team_discussions: json['team_discussions'] == null
          ? null
          : GithubTokenInstallationPermissionsTeamDiscussions.fromJson(
              json['team_discussions'] as Object?,
            ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'actions': actions,
      'administration': administration,
      'checks': checks,
      'contents': contents,
      'deployments': deployments,
      'environments': environments,
      'issues': issues,
      'metadata': metadata,
      'packages': packages,
      'pages': pages,
      'pull_requests': pull_requests,
      'repository_announcement_banners': repository_announcement_banners,
      'repository_hooks': repository_hooks,
      'repository_projects': repository_projects,
      'secret_scanning_alerts': secret_scanning_alerts,
      'secrets': secrets,
      'security_events': security_events,
      'single_file': single_file,
      'statuses': statuses,
      'vulnerability_alerts': vulnerability_alerts,
      'workflows': workflows,
      'members': members,
      'organization_administration': organization_administration,
      'organization_custom_roles': organization_custom_roles,
      'organization_announcement_banners': organization_announcement_banners,
      'organization_hooks': organization_hooks,
      'organization_plan': organization_plan,
      'organization_projects': organization_projects,
      'organization_packages': organization_packages,
      'organization_secrets': organization_secrets,
      'organization_self_hosted_runners': organization_self_hosted_runners,
      'organization_user_blocking': organization_user_blocking,
      'team_discussions': team_discussions,
    };
  }

  GithubTokenInstallationPermissions copyWith({
    GithubTokenInstallationPermissionsActions? actions,
    bool actionsToNull = false,
    GithubTokenInstallationPermissionsAdministration? administration,
    bool administrationToNull = false,
    GithubTokenInstallationPermissionsChecks? checks,
    bool checksToNull = false,
    GithubTokenInstallationPermissionsContents? contents,
    bool contentsToNull = false,
    GithubTokenInstallationPermissionsDeployments? deployments,
    bool deploymentsToNull = false,
    GithubTokenInstallationPermissionsEnvironments? environments,
    bool environmentsToNull = false,
    GithubTokenInstallationPermissionsIssues? issues,
    bool issuesToNull = false,
    GithubTokenInstallationPermissionsMetadata? metadata,
    bool metadataToNull = false,
    GithubTokenInstallationPermissionsPackages? packages,
    bool packagesToNull = false,
    GithubTokenInstallationPermissionsPages? pages,
    bool pagesToNull = false,
    GithubTokenInstallationPermissionsPullRequests? pull_requests,
    bool pull_requestsToNull = false,
    GithubTokenInstallationPermissionsRepositoryAnnouncementBanners?
        repository_announcement_banners,
    bool repository_announcement_bannersToNull = false,
    GithubTokenInstallationPermissionsRepositoryHooks? repository_hooks,
    bool repository_hooksToNull = false,
    GithubTokenInstallationPermissionsRepositoryProjects? repository_projects,
    bool repository_projectsToNull = false,
    GithubTokenInstallationPermissionsSecretScanningAlerts?
        secret_scanning_alerts,
    bool secret_scanning_alertsToNull = false,
    GithubTokenInstallationPermissionsSecrets? secrets,
    bool secretsToNull = false,
    GithubTokenInstallationPermissionsSecurityEvents? security_events,
    bool security_eventsToNull = false,
    GithubTokenInstallationPermissionsSingleFile? single_file,
    bool single_fileToNull = false,
    GithubTokenInstallationPermissionsStatuses? statuses,
    bool statusesToNull = false,
    GithubTokenInstallationPermissionsVulnerabilityAlerts? vulnerability_alerts,
    bool vulnerability_alertsToNull = false,
    GithubTokenInstallationPermissionsWorkflows? workflows,
    bool workflowsToNull = false,
    GithubTokenInstallationPermissionsMembers? members,
    bool membersToNull = false,
    GithubTokenInstallationPermissionsOrganizationAdministration?
        organization_administration,
    bool organization_administrationToNull = false,
    GithubTokenInstallationPermissionsOrganizationCustomRoles?
        organization_custom_roles,
    bool organization_custom_rolesToNull = false,
    GithubTokenInstallationPermissionsOrganizationAnnouncementBanners?
        organization_announcement_banners,
    bool organization_announcement_bannersToNull = false,
    GithubTokenInstallationPermissionsOrganizationHooks? organization_hooks,
    bool organization_hooksToNull = false,
    GithubTokenInstallationPermissionsOrganizationPlan? organization_plan,
    bool organization_planToNull = false,
    GithubTokenInstallationPermissionsOrganizationProjects?
        organization_projects,
    bool organization_projectsToNull = false,
    GithubTokenInstallationPermissionsOrganizationPackages?
        organization_packages,
    bool organization_packagesToNull = false,
    GithubTokenInstallationPermissionsOrganizationSecrets? organization_secrets,
    bool organization_secretsToNull = false,
    GithubTokenInstallationPermissionsOrganizationSelfHostedRunners?
        organization_self_hosted_runners,
    bool organization_self_hosted_runnersToNull = false,
    GithubTokenInstallationPermissionsOrganizationUserBlocking?
        organization_user_blocking,
    bool organization_user_blockingToNull = false,
    GithubTokenInstallationPermissionsTeamDiscussions? team_discussions,
    bool team_discussionsToNull = false,
  }) {
    return GithubTokenInstallationPermissions(
      actions: actions ?? (actionsToNull ? null : this.actions),
      administration:
          administration ?? (administrationToNull ? null : this.administration),
      checks: checks ?? (checksToNull ? null : this.checks),
      contents: contents ?? (contentsToNull ? null : this.contents),
      deployments: deployments ?? (deploymentsToNull ? null : this.deployments),
      environments:
          environments ?? (environmentsToNull ? null : this.environments),
      issues: issues ?? (issuesToNull ? null : this.issues),
      metadata: metadata ?? (metadataToNull ? null : this.metadata),
      packages: packages ?? (packagesToNull ? null : this.packages),
      pages: pages ?? (pagesToNull ? null : this.pages),
      pull_requests:
          pull_requests ?? (pull_requestsToNull ? null : this.pull_requests),
      repository_announcement_banners: repository_announcement_banners ??
          (repository_announcement_bannersToNull
              ? null
              : this.repository_announcement_banners),
      repository_hooks: repository_hooks ??
          (repository_hooksToNull ? null : this.repository_hooks),
      repository_projects: repository_projects ??
          (repository_projectsToNull ? null : this.repository_projects),
      secret_scanning_alerts: secret_scanning_alerts ??
          (secret_scanning_alertsToNull ? null : this.secret_scanning_alerts),
      secrets: secrets ?? (secretsToNull ? null : this.secrets),
      security_events: security_events ??
          (security_eventsToNull ? null : this.security_events),
      single_file: single_file ?? (single_fileToNull ? null : this.single_file),
      statuses: statuses ?? (statusesToNull ? null : this.statuses),
      vulnerability_alerts: vulnerability_alerts ??
          (vulnerability_alertsToNull ? null : this.vulnerability_alerts),
      workflows: workflows ?? (workflowsToNull ? null : this.workflows),
      members: members ?? (membersToNull ? null : this.members),
      organization_administration: organization_administration ??
          (organization_administrationToNull
              ? null
              : this.organization_administration),
      organization_custom_roles: organization_custom_roles ??
          (organization_custom_rolesToNull
              ? null
              : this.organization_custom_roles),
      organization_announcement_banners: organization_announcement_banners ??
          (organization_announcement_bannersToNull
              ? null
              : this.organization_announcement_banners),
      organization_hooks: organization_hooks ??
          (organization_hooksToNull ? null : this.organization_hooks),
      organization_plan: organization_plan ??
          (organization_planToNull ? null : this.organization_plan),
      organization_projects: organization_projects ??
          (organization_projectsToNull ? null : this.organization_projects),
      organization_packages: organization_packages ??
          (organization_packagesToNull ? null : this.organization_packages),
      organization_secrets: organization_secrets ??
          (organization_secretsToNull ? null : this.organization_secrets),
      organization_self_hosted_runners: organization_self_hosted_runners ??
          (organization_self_hosted_runnersToNull
              ? null
              : this.organization_self_hosted_runners),
      organization_user_blocking: organization_user_blocking ??
          (organization_user_blockingToNull
              ? null
              : this.organization_user_blocking),
      team_discussions: team_discussions ??
          (team_discussionsToNull ? null : this.team_discussions),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is GithubTokenInstallationPermissions &&
            other.runtimeType == runtimeType &&
            other.actions == actions &&
            other.administration == administration &&
            other.checks == checks &&
            other.contents == contents &&
            other.deployments == deployments &&
            other.environments == environments &&
            other.issues == issues &&
            other.metadata == metadata &&
            other.packages == packages &&
            other.pages == pages &&
            other.pull_requests == pull_requests &&
            other.repository_announcement_banners ==
                repository_announcement_banners &&
            other.repository_hooks == repository_hooks &&
            other.repository_projects == repository_projects &&
            other.secret_scanning_alerts == secret_scanning_alerts &&
            other.secrets == secrets &&
            other.security_events == security_events &&
            other.single_file == single_file &&
            other.statuses == statuses &&
            other.vulnerability_alerts == vulnerability_alerts &&
            other.workflows == workflows &&
            other.members == members &&
            other.organization_administration == organization_administration &&
            other.organization_custom_roles == organization_custom_roles &&
            other.organization_announcement_banners ==
                organization_announcement_banners &&
            other.organization_hooks == organization_hooks &&
            other.organization_plan == organization_plan &&
            other.organization_projects == organization_projects &&
            other.organization_packages == organization_packages &&
            other.organization_secrets == organization_secrets &&
            other.organization_self_hosted_runners ==
                organization_self_hosted_runners &&
            other.organization_user_blocking == organization_user_blocking &&
            other.team_discussions == team_discussions;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      actions,
      administration,
      checks,
      contents,
      deployments,
      environments,
      issues,
      metadata,
      packages,
      pages,
      pull_requests,
      repository_announcement_banners,
      repository_hooks,
      repository_projects,
      secret_scanning_alerts,
      secrets,
      security_events,
      single_file,
      statuses,
      vulnerability_alerts,
      workflows,
      members,
      organization_administration,
      organization_custom_roles,
      organization_announcement_banners,
      organization_hooks,
      organization_plan,
      organization_projects,
      organization_packages,
      organization_secrets,
      organization_self_hosted_runners,
      organization_user_blocking,
      team_discussions,
    ]);
  }

  @override
  String toString() {
    return "GithubTokenInstallationPermissions${{
      "actions": actions,
      "administration": administration,
      "checks": checks,
      "contents": contents,
      "deployments": deployments,
      "environments": environments,
      "issues": issues,
      "metadata": metadata,
      "packages": packages,
      "pages": pages,
      "pull_requests": pull_requests,
      "repository_announcement_banners": repository_announcement_banners,
      "repository_hooks": repository_hooks,
      "repository_projects": repository_projects,
      "secret_scanning_alerts": secret_scanning_alerts,
      "secrets": secrets,
      "security_events": security_events,
      "single_file": single_file,
      "statuses": statuses,
      "vulnerability_alerts": vulnerability_alerts,
      "workflows": workflows,
      "members": members,
      "organization_administration": organization_administration,
      "organization_custom_roles": organization_custom_roles,
      "organization_announcement_banners": organization_announcement_banners,
      "organization_hooks": organization_hooks,
      "organization_plan": organization_plan,
      "organization_projects": organization_projects,
      "organization_packages": organization_packages,
      "organization_secrets": organization_secrets,
      "organization_self_hosted_runners": organization_self_hosted_runners,
      "organization_user_blocking": organization_user_blocking,
      "team_discussions": team_discussions,
    }}";
  }

  List<Object?> get props => [
        actions,
        administration,
        checks,
        contents,
        deployments,
        environments,
        issues,
        metadata,
        packages,
        pages,
        pull_requests,
        repository_announcement_banners,
        repository_hooks,
        repository_projects,
        secret_scanning_alerts,
        secrets,
        security_events,
        single_file,
        statuses,
        vulnerability_alerts,
        workflows,
        members,
        organization_administration,
        organization_custom_roles,
        organization_announcement_banners,
        organization_hooks,
        organization_plan,
        organization_projects,
        organization_packages,
        organization_secrets,
        organization_self_hosted_runners,
        organization_user_blocking,
        team_discussions,
      ];
}

// generated-dart-fixer-end{"md5Hash":"LdKrAc+sO1aXwzUki1U20g=="}

/// A GitHub user.
class GithubTokenInstallationAccount {
  final String? name;
  final String? email;

  /// #### Example
  /// ```json
  /// "octocat"
  /// ```
  final String login;

  /// #### Example
  /// ```json
  /// 1
  /// ```
  final int id;

  /// #### Example
  /// ```json
  /// "MDQ6VXNlcjE="
  /// ```
  final String node_id;

  /// #### Example
  /// ```json
  /// "https://github.com/images/error/octocat_happy.gif"
  /// ```
  final String avatar_url;

  /// #### Example
  /// ```json
  /// "41d064eb2195891e12d0413f63227ea7"
  /// ```
  final String? gravatar_id;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat"
  /// ```
  final String url;

  /// #### Example
  /// ```json
  /// "https://github.com/octocat"
  /// ```
  final String html_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/followers"
  /// ```
  final String followers_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/following{/other_user}"
  /// ```
  final String following_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/gists{/gist_id}"
  /// ```
  final String gists_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/starred{/owner}{/repo}"
  /// ```
  final String starred_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/subscriptions"
  /// ```
  final String subscriptions_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/orgs"
  /// ```
  final String organizations_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/repos"
  /// ```
  final String repos_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/events{/privacy}"
  /// ```
  final String events_url;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/received_events"
  /// ```
  final String received_events_url;

  /// #### Example
  /// ```json
  /// "User"
  /// ```
  final String type;
  final bool site_admin;

  /// #### Example
  /// ```json
  /// "\"2020-07-09T00:17:55Z\""
  /// ```
  final String? starred_at;

  /// A GitHub user.
  const GithubTokenInstallationAccount({
    this.name,
    this.email,
    required this.login,
    required this.id,
    required this.node_id,
    required this.avatar_url,
    this.gravatar_id,
    required this.url,
    required this.html_url,
    required this.followers_url,
    required this.following_url,
    required this.gists_url,
    required this.starred_url,
    required this.subscriptions_url,
    required this.organizations_url,
    required this.repos_url,
    required this.events_url,
    required this.received_events_url,
    required this.type,
    required this.site_admin,
    this.starred_at,
  });
// generated-dart-fixer-start{"md5Hash":"nXmv8e0HU7k8NGYYjTLMnQ=="}

  factory GithubTokenInstallationAccount.fromJson(Map json) {
    return GithubTokenInstallationAccount(
      name: json['name'] as String?,
      email: json['email'] as String?,
      login: json['login'] as String,
      id: json['id'] as int,
      node_id: json['node_id'] as String,
      avatar_url: json['avatar_url'] as String,
      gravatar_id: json['gravatar_id'] as String?,
      url: json['url'] as String,
      html_url: json['html_url'] as String,
      followers_url: json['followers_url'] as String,
      following_url: json['following_url'] as String,
      gists_url: json['gists_url'] as String,
      starred_url: json['starred_url'] as String,
      subscriptions_url: json['subscriptions_url'] as String,
      organizations_url: json['organizations_url'] as String,
      repos_url: json['repos_url'] as String,
      events_url: json['events_url'] as String,
      received_events_url: json['received_events_url'] as String,
      type: json['type'] as String,
      site_admin: json['site_admin'] as bool,
      starred_at: json['starred_at'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'email': email,
      'login': login,
      'id': id,
      'node_id': node_id,
      'avatar_url': avatar_url,
      'gravatar_id': gravatar_id,
      'url': url,
      'html_url': html_url,
      'followers_url': followers_url,
      'following_url': following_url,
      'gists_url': gists_url,
      'starred_url': starred_url,
      'subscriptions_url': subscriptions_url,
      'organizations_url': organizations_url,
      'repos_url': repos_url,
      'events_url': events_url,
      'received_events_url': received_events_url,
      'type': type,
      'site_admin': site_admin,
      'starred_at': starred_at,
    };
  }

  GithubTokenInstallationAccount copyWith({
    String? name,
    bool nameToNull = false,
    String? email,
    bool emailToNull = false,
    String? login,
    int? id,
    String? node_id,
    String? avatar_url,
    String? gravatar_id,
    bool gravatar_idToNull = false,
    String? url,
    String? html_url,
    String? followers_url,
    String? following_url,
    String? gists_url,
    String? starred_url,
    String? subscriptions_url,
    String? organizations_url,
    String? repos_url,
    String? events_url,
    String? received_events_url,
    String? type,
    bool? site_admin,
    String? starred_at,
    bool starred_atToNull = false,
  }) {
    return GithubTokenInstallationAccount(
      name: name ?? (nameToNull ? null : this.name),
      email: email ?? (emailToNull ? null : this.email),
      login: login ?? this.login,
      id: id ?? this.id,
      node_id: node_id ?? this.node_id,
      avatar_url: avatar_url ?? this.avatar_url,
      gravatar_id: gravatar_id ?? (gravatar_idToNull ? null : this.gravatar_id),
      url: url ?? this.url,
      html_url: html_url ?? this.html_url,
      followers_url: followers_url ?? this.followers_url,
      following_url: following_url ?? this.following_url,
      gists_url: gists_url ?? this.gists_url,
      starred_url: starred_url ?? this.starred_url,
      subscriptions_url: subscriptions_url ?? this.subscriptions_url,
      organizations_url: organizations_url ?? this.organizations_url,
      repos_url: repos_url ?? this.repos_url,
      events_url: events_url ?? this.events_url,
      received_events_url: received_events_url ?? this.received_events_url,
      type: type ?? this.type,
      site_admin: site_admin ?? this.site_admin,
      starred_at: starred_at ?? (starred_atToNull ? null : this.starred_at),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is GithubTokenInstallationAccount &&
            other.runtimeType == runtimeType &&
            other.name == name &&
            other.email == email &&
            other.login == login &&
            other.id == id &&
            other.node_id == node_id &&
            other.avatar_url == avatar_url &&
            other.gravatar_id == gravatar_id &&
            other.url == url &&
            other.html_url == html_url &&
            other.followers_url == followers_url &&
            other.following_url == following_url &&
            other.gists_url == gists_url &&
            other.starred_url == starred_url &&
            other.subscriptions_url == subscriptions_url &&
            other.organizations_url == organizations_url &&
            other.repos_url == repos_url &&
            other.events_url == events_url &&
            other.received_events_url == received_events_url &&
            other.type == type &&
            other.site_admin == site_admin &&
            other.starred_at == starred_at;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      name,
      email,
      login,
      id,
      node_id,
      avatar_url,
      gravatar_id,
      url,
      html_url,
      followers_url,
      following_url,
      gists_url,
      starred_url,
      subscriptions_url,
      organizations_url,
      repos_url,
      events_url,
      received_events_url,
      type,
      site_admin,
      starred_at,
    ]);
  }

  @override
  String toString() {
    return "GithubTokenInstallationAccount${{
      "name": name,
      "email": email,
      "login": login,
      "id": id,
      "node_id": node_id,
      "avatar_url": avatar_url,
      "gravatar_id": gravatar_id,
      "url": url,
      "html_url": html_url,
      "followers_url": followers_url,
      "following_url": following_url,
      "gists_url": gists_url,
      "starred_url": starred_url,
      "subscriptions_url": subscriptions_url,
      "organizations_url": organizations_url,
      "repos_url": repos_url,
      "events_url": events_url,
      "received_events_url": received_events_url,
      "type": type,
      "site_admin": site_admin,
      "starred_at": starred_at,
    }}";
  }

  List<Object?> get props => [
        name,
        email,
        login,
        id,
        node_id,
        avatar_url,
        gravatar_id,
        url,
        html_url,
        followers_url,
        following_url,
        gists_url,
        starred_url,
        subscriptions_url,
        organizations_url,
        repos_url,
        events_url,
        received_events_url,
        type,
        site_admin,
        starred_at,
      ];
}

// generated-dart-fixer-end{"md5Hash":"nXmv8e0HU7k8NGYYjTLMnQ=="}

class GithubTokenInstallation {
  /// The permissions granted to the user-to-server access token.
  final GithubTokenInstallationPermissions permissions;

  /// Describe whether all repositories have been selected or there's a selection involved
  final GithubTokenInstallationRepositorySelection repository_selection;

  /// #### Example
  /// ```json
  /// "config.yaml"
  /// ```
  final String? single_file_name;

  /// #### Example
  /// ```json
  /// true
  /// ```
  final bool? has_multiple_single_files;

  /// #### Example 1
  /// ```json
  /// "config.yml"
  /// ```
  ///
  /// #### Example 2
  /// ```json
  /// ".github/issue_TEMPLATE.md"
  /// ```
  final List<String>? single_file_paths;

  /// #### Example
  /// ```json
  /// "https://api.github.com/users/octocat/repos"
  /// ```
  final String repositories_url;

  /// A GitHub user.
  final GithubTokenInstallationAccount account;

  const GithubTokenInstallation({
    required this.permissions,
    required this.repository_selection,
    this.single_file_name,
    this.has_multiple_single_files,
    this.single_file_paths,
    required this.repositories_url,
    required this.account,
  });
// generated-dart-fixer-start{"md5Hash":"lZBNUuD0i1r5Fx/vFlGNcw=="}

  factory GithubTokenInstallation.fromJson(Map json) {
    return GithubTokenInstallation(
      permissions: GithubTokenInstallationPermissions.fromJson(
        (json['permissions'] as Map).cast(),
      ),
      repository_selection: GithubTokenInstallationRepositorySelection.fromJson(
        json['repository_selection'] as Object?,
      ),
      single_file_name: json['single_file_name'] as String?,
      has_multiple_single_files: json['has_multiple_single_files'] as bool?,
      single_file_paths: json['single_file_paths'] == null
          ? null
          : (json['single_file_paths'] as Iterable)
              .map((v) => v as String)
              .toList(),
      repositories_url: json['repositories_url'] as String,
      account: GithubTokenInstallationAccount.fromJson(
        (json['account'] as Map).cast(),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'permissions': permissions,
      'repository_selection': repository_selection,
      'single_file_name': single_file_name,
      'has_multiple_single_files': has_multiple_single_files,
      'single_file_paths': single_file_paths,
      'repositories_url': repositories_url,
      'account': account,
    };
  }

  GithubTokenInstallation copyWith({
    GithubTokenInstallationPermissions? permissions,
    GithubTokenInstallationRepositorySelection? repository_selection,
    String? single_file_name,
    bool single_file_nameToNull = false,
    bool? has_multiple_single_files,
    bool has_multiple_single_filesToNull = false,
    List<String>? single_file_paths,
    bool single_file_pathsToNull = false,
    String? repositories_url,
    GithubTokenInstallationAccount? account,
  }) {
    return GithubTokenInstallation(
      permissions: permissions ?? this.permissions,
      repository_selection: repository_selection ?? this.repository_selection,
      single_file_name: single_file_name ??
          (single_file_nameToNull ? null : this.single_file_name),
      has_multiple_single_files: has_multiple_single_files ??
          (has_multiple_single_filesToNull
              ? null
              : this.has_multiple_single_files),
      single_file_paths: single_file_paths ??
          (single_file_pathsToNull ? null : this.single_file_paths),
      repositories_url: repositories_url ?? this.repositories_url,
      account: account ?? this.account,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is GithubTokenInstallation &&
            other.runtimeType == runtimeType &&
            other.permissions == permissions &&
            other.repository_selection == repository_selection &&
            other.single_file_name == single_file_name &&
            other.has_multiple_single_files == has_multiple_single_files &&
            other.single_file_paths == single_file_paths &&
            other.repositories_url == repositories_url &&
            other.account == account;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      permissions,
      repository_selection,
      single_file_name,
      has_multiple_single_files,
      single_file_paths,
      repositories_url,
      account,
    ]);
  }

  @override
  String toString() {
    return "GithubTokenInstallation${{
      "permissions": permissions,
      "repository_selection": repository_selection,
      "single_file_name": single_file_name,
      "has_multiple_single_files": has_multiple_single_files,
      "single_file_paths": single_file_paths,
      "repositories_url": repositories_url,
      "account": account,
    }}";
  }

  List<Object?> get props => [
        permissions,
        repository_selection,
        single_file_name,
        has_multiple_single_files,
        single_file_paths,
        repositories_url,
        account,
      ];
}

// generated-dart-fixer-end{"md5Hash":"lZBNUuD0i1r5Fx/vFlGNcw=="}

/// The authorization for an OAuth app, GitHub App, or a Personal Access Token.
class GithubToken {
  final int id;
  final String url;

  /// A list of scopes that this authorization is in.
  final List<String>? scopes;
  final String token;
  final String? token_last_eight;
  final String? hashed_token;
  final GithubTokenApp app;
  final String? note;
  final String? note_url;
  final DateTime updated_at;
  final DateTime created_at;
  final String? fingerprint;
  final GithubTokenUser? user;
  final GithubTokenInstallation? installation;
  final DateTime? expires_at;

  /// The authorization for an OAuth app, GitHub App, or a Personal Access Token.
  const GithubToken({
    required this.id,
    required this.url,
    this.scopes,
    required this.token,
    this.token_last_eight,
    this.hashed_token,
    required this.app,
    this.note,
    this.note_url,
    required this.updated_at,
    required this.created_at,
    this.fingerprint,
    this.user,
    this.installation,
    this.expires_at,
  });
// generated-dart-fixer-start{"md5Hash":"CZglqA4+tVO78ujNdOamWA=="}

  factory GithubToken.fromJson(Map json) {
    return GithubToken(
      id: json['id'] as int,
      url: json['url'] as String,
      scopes: json['scopes'] == null
          ? null
          : (json['scopes'] as Iterable).map((v) => v as String).toList(),
      token: json['token'] as String,
      token_last_eight: json['token_last_eight'] as String?,
      hashed_token: json['hashed_token'] as String?,
      app: GithubTokenApp.fromJson((json['app'] as Map).cast()),
      note: json['note'] as String?,
      note_url: json['note_url'] as String?,
      updated_at: DateTime.parse(json['updated_at'] as String),
      created_at: DateTime.parse(json['created_at'] as String),
      fingerprint: json['fingerprint'] as String?,
      user: json['user'] == null
          ? null
          : GithubTokenUser.fromJson(json['user'] as Map),
      installation: json['installation'] == null
          ? null
          : GithubTokenInstallation.fromJson(json['installation'] as Map),
      expires_at: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'url': url,
      'scopes': scopes,
      'token': token,
      'token_last_eight': token_last_eight,
      'hashed_token': hashed_token,
      'app': app,
      'note': note,
      'note_url': note_url,
      'updated_at': updated_at.toIso8601String(),
      'created_at': created_at.toIso8601String(),
      'fingerprint': fingerprint,
      'user': user,
      'installation': installation,
      'expires_at': expires_at?.toIso8601String(),
    };
  }

  GithubToken copyWith({
    int? id,
    String? url,
    List<String>? scopes,
    bool scopesToNull = false,
    String? token,
    String? token_last_eight,
    bool token_last_eightToNull = false,
    String? hashed_token,
    bool hashed_tokenToNull = false,
    GithubTokenApp? app,
    String? note,
    bool noteToNull = false,
    String? note_url,
    bool note_urlToNull = false,
    DateTime? updated_at,
    DateTime? created_at,
    String? fingerprint,
    bool fingerprintToNull = false,
    GithubTokenUser? user,
    bool userToNull = false,
    GithubTokenInstallation? installation,
    bool installationToNull = false,
    DateTime? expires_at,
    bool expires_atToNull = false,
  }) {
    return GithubToken(
      id: id ?? this.id,
      url: url ?? this.url,
      scopes: scopes ?? (scopesToNull ? null : this.scopes),
      token: token ?? this.token,
      token_last_eight: token_last_eight ??
          (token_last_eightToNull ? null : this.token_last_eight),
      hashed_token:
          hashed_token ?? (hashed_tokenToNull ? null : this.hashed_token),
      app: app ?? this.app,
      note: note ?? (noteToNull ? null : this.note),
      note_url: note_url ?? (note_urlToNull ? null : this.note_url),
      updated_at: updated_at ?? this.updated_at,
      created_at: created_at ?? this.created_at,
      fingerprint: fingerprint ?? (fingerprintToNull ? null : this.fingerprint),
      user: user ?? (userToNull ? null : this.user),
      installation:
          installation ?? (installationToNull ? null : this.installation),
      expires_at: expires_at ?? (expires_atToNull ? null : this.expires_at),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is GithubToken &&
            other.runtimeType == runtimeType &&
            other.id == id &&
            other.url == url &&
            other.scopes == scopes &&
            other.token == token &&
            other.token_last_eight == token_last_eight &&
            other.hashed_token == hashed_token &&
            other.app == app &&
            other.note == note &&
            other.note_url == note_url &&
            other.updated_at == updated_at &&
            other.created_at == created_at &&
            other.fingerprint == fingerprint &&
            other.user == user &&
            other.installation == installation &&
            other.expires_at == expires_at;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      id,
      url,
      scopes,
      token,
      token_last_eight,
      hashed_token,
      app,
      note,
      note_url,
      updated_at,
      created_at,
      fingerprint,
      user,
      installation,
      expires_at,
    ]);
  }

  @override
  String toString() {
    return "GithubToken${{
      "id": id,
      "url": url,
      "scopes": scopes,
      "token": token,
      "token_last_eight": token_last_eight,
      "hashed_token": hashed_token,
      "app": app,
      "note": note,
      "note_url": note_url,
      "updated_at": updated_at,
      "created_at": created_at,
      "fingerprint": fingerprint,
      "user": user,
      "installation": installation,
      "expires_at": expires_at,
    }}";
  }

  List<Object?> get props => [
        id,
        url,
        scopes,
        token,
        token_last_eight,
        hashed_token,
        app,
        note,
        note_url,
        updated_at,
        created_at,
        fingerprint,
        user,
        installation,
        expires_at,
      ];
}

// generated-dart-fixer-end{"md5Hash":"CZglqA4+tVO78ujNdOamWA=="}
enum GithubTokenInstallationPermissionsActions {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsActions(this.value);
  factory GithubTokenInstallationPermissionsActions.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsAdministration {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsAdministration(this.value);
  factory GithubTokenInstallationPermissionsAdministration.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsChecks {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsChecks(this.value);
  factory GithubTokenInstallationPermissionsChecks.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsContents {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsContents(this.value);
  factory GithubTokenInstallationPermissionsContents.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsDeployments {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsDeployments(this.value);
  factory GithubTokenInstallationPermissionsDeployments.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsEnvironments {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsEnvironments(this.value);
  factory GithubTokenInstallationPermissionsEnvironments.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsIssues {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsIssues(this.value);
  factory GithubTokenInstallationPermissionsIssues.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsMetadata {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsMetadata(this.value);
  factory GithubTokenInstallationPermissionsMetadata.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsPackages {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsPackages(this.value);
  factory GithubTokenInstallationPermissionsPackages.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsPages {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsPages(this.value);
  factory GithubTokenInstallationPermissionsPages.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsPullRequests {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsPullRequests(this.value);
  factory GithubTokenInstallationPermissionsPullRequests.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsRepositoryAnnouncementBanners {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsRepositoryAnnouncementBanners(
    this.value,
  );
  factory GithubTokenInstallationPermissionsRepositoryAnnouncementBanners.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsRepositoryHooks {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsRepositoryHooks(this.value);
  factory GithubTokenInstallationPermissionsRepositoryHooks.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsRepositoryProjects {
  read('read'),
  write('write'),
  admin('admin');

  final String value;
  const GithubTokenInstallationPermissionsRepositoryProjects(this.value);
  factory GithubTokenInstallationPermissionsRepositoryProjects.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsSecretScanningAlerts {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsSecretScanningAlerts(this.value);
  factory GithubTokenInstallationPermissionsSecretScanningAlerts.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsSecrets {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsSecrets(this.value);
  factory GithubTokenInstallationPermissionsSecrets.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsSecurityEvents {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsSecurityEvents(this.value);
  factory GithubTokenInstallationPermissionsSecurityEvents.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsSingleFile {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsSingleFile(this.value);
  factory GithubTokenInstallationPermissionsSingleFile.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsStatuses {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsStatuses(this.value);
  factory GithubTokenInstallationPermissionsStatuses.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsVulnerabilityAlerts {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsVulnerabilityAlerts(this.value);
  factory GithubTokenInstallationPermissionsVulnerabilityAlerts.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsWorkflows {
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsWorkflows(this.value);
  factory GithubTokenInstallationPermissionsWorkflows.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsMembers {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsMembers(this.value);
  factory GithubTokenInstallationPermissionsMembers.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationAdministration {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationAdministration(
    this.value,
  );
  factory GithubTokenInstallationPermissionsOrganizationAdministration.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationCustomRoles {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationCustomRoles(this.value);
  factory GithubTokenInstallationPermissionsOrganizationCustomRoles.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationAnnouncementBanners {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationAnnouncementBanners(
    this.value,
  );
  factory GithubTokenInstallationPermissionsOrganizationAnnouncementBanners.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationHooks {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationHooks(this.value);
  factory GithubTokenInstallationPermissionsOrganizationHooks.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationPlan {
  read('read');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationPlan(this.value);
  factory GithubTokenInstallationPermissionsOrganizationPlan.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationProjects {
  read('read'),
  write('write'),
  admin('admin');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationProjects(this.value);
  factory GithubTokenInstallationPermissionsOrganizationProjects.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationPackages {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationPackages(this.value);
  factory GithubTokenInstallationPermissionsOrganizationPackages.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationSecrets {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationSecrets(this.value);
  factory GithubTokenInstallationPermissionsOrganizationSecrets.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationSelfHostedRunners {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationSelfHostedRunners(
    this.value,
  );
  factory GithubTokenInstallationPermissionsOrganizationSelfHostedRunners.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsOrganizationUserBlocking {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsOrganizationUserBlocking(this.value);
  factory GithubTokenInstallationPermissionsOrganizationUserBlocking.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationPermissionsTeamDiscussions {
  read('read'),
  write('write');

  final String value;
  const GithubTokenInstallationPermissionsTeamDiscussions(this.value);
  factory GithubTokenInstallationPermissionsTeamDiscussions.fromJson(
    Object? json,
  ) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}

enum GithubTokenInstallationRepositorySelection {
  all('all'),
  selected('selected');

  final String value;
  const GithubTokenInstallationRepositorySelection(this.value);
  factory GithubTokenInstallationRepositorySelection.fromJson(Object? json) =>
      values.firstWhere((v) => v.value == json);
  String toJson() => value;
}
