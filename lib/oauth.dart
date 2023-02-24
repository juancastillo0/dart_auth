/// Support for doing something awesome.
///
/// More dartdocs go here.
library oauth;

import 'package:http/http.dart' as http;

export 'package:oxidized/oxidized.dart';

export 'src/data.dart';
export 'src/jwt_and_sessions.dart';
export 'src/oauth_base.dart';

typedef HttpClient = http.Client;
typedef HttpResponse = http.Response;

// TODO: Export any libraries intended for clients of this package.
