/*
 * This file is part of Social Clone
 * (see https://github.com/fnjlabs-arch/Social-Clone).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

/// Kiosk allowlist: the only hosts Social Clone may navigate to.
///
/// TikTok-only build: TikTok + TempMail36, no Facebook. Besides the
/// apps themselves, the CDNs and auth helpers they need are included.
/// Everything else is blocked by [AllowlistGuard].
const _allowedHostSuffixes = <String>[
  // TikTok
  'tiktok.com',
  'tiktokv.com',
  'tiktokcdn.com',
  'tiktokcdn-us.com',
  'tiktokcdn-eu.com',
  'ibyteimg.com',
  'ibytedtos.com',
  // TempMail36 (in-app tab; ?app_source=socialclone gives 24h addresses)
  'tempmail36.app',
];

/// Home destinations offered on the Social Clone home screen.
const tiktokHomeUrl = 'https://www.tiktok.com/';

/// TempMail36 home, opened inside Social Clone. The app_source param is
/// what earns the 24h tier (86400s) from the TempMail36 Worker; without
/// it, addresses created on the site get the 1h tier instead.
const tempMailHomeUrl = 'https://tempmail36.app/?app_source=socialclone';

/// Permanent TempMail36 addresses, in profile order (profile 1 = mia,
/// …, profile 10 = zoe). LEGACY fallback only: new profiles store their
/// own address on the profile itself (see [Profile.permanentEmail]).
/// Kept so profiles created before per-profile storage still open the
/// right inbox. Personal-only build: these are Qasim's own
/// @ai.socialclone.app addresses, baked in from the repo — never shown
/// or offered to anyone else. They live in the TempMail36 backend with
/// tier 'permanent' (never expire) and are read-gated by the shared key
/// below.
const permanentProfileEmails = <String>[
  'mia@ai.socialclone.app',
  'lilly@ai.socialclone.app',
  'tina@ai.socialclone.app',
  'mina@ai.socialclone.app',
  'shilly@ai.socialclone.app',
  'laurean@ai.socialclone.app',
  'sara@ai.socialclone.app',
  'nina@ai.socialclone.app',
  'riya@ai.socialclone.app',
  'zoe@ai.socialclone.app',
];

/// Read key for tier='permanent' inboxes, injected at build time from
/// the TM36_PERMANENT_KEY repo secret (--dart-define). Empty in local
/// builds — permanent inboxes simply stay unread there. The value is
/// never stored in the repo.
const permanentReadKey = String.fromEnvironment('TM36_PERMANENT_KEY');

/// TempMail URL for a profile: the profile's stored permanent address
/// pre-loaded, with the read key.
///
/// [permanentEmail] is the address stored on the profile itself — the
/// authority. [legacyIndex] is only the fallback for profiles created
/// before addresses were stored per profile: their address still comes
/// from the creation-order list below. Falls back to the plain app URL
/// when there is no address at all or no key was injected (local
/// builds).
String tempMailUrlForProfile({String? permanentEmail, int legacyIndex = -1}) {
  final email =
      permanentEmail ??
      (legacyIndex >= 0 && legacyIndex < permanentProfileEmails.length
          ? permanentProfileEmails[legacyIndex]
          : null);
  if (email == null || permanentReadKey.isEmpty) {
    return tempMailHomeUrl;
  }
  final uri = Uri.parse(tempMailHomeUrl);
  final params = Map<String, String>.from(uri.queryParameters)
    ..['address'] = email
    ..['key'] = permanentReadKey;
  return uri.replace(queryParameters: params).toString();
}

/// Returns true when [url] may load inside Social Clone.
///
/// Blank/unparsed/non-http(s) URLs (about:blank, loading states) are
/// allowed: they carry no external destination.
bool isAllowedUrl(String? url) {
  if (url == null || url.isEmpty) {
    return true;
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return true;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return true;
  }
  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return true;
  }
  return _allowedHostSuffixes.any(
    (suffix) => host == suffix || host.endsWith('.$suffix'),
  );
}
