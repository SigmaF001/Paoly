import 'package:flutter/foundation.dart';

const nativeAuthRedirect = 'com.paoly.app://login-callback/';

/// Do not carry callback codes, query parameters or hash routes into a new link.
String authRedirectUrl({bool? web, Uri? base}) {
  if (!(web ?? kIsWeb)) return nativeAuthRedirect;
  final uri = base ?? Uri.base;
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  ).toString();
}
