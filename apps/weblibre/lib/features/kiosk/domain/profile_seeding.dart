/*
 * This file is part of Social Clone
 * (see https://github.com/fnjlabs-arch/Social-Clone).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:weblibre/features/kiosk/domain/allowlist.dart';
import 'package:weblibre/domain/entities/profile.dart';
import 'package:weblibre/features/license/domain/license_repository.dart';
import 'package:weblibre/features/user/domain/repositories/profile.dart';

/// One-time migration that pre-seeds the permanent TempMail36 profiles
/// (mia, lilly, tina, mina, shilly, laurean, sara, nina, riya, zoe —
/// [permanentProfileEmails], in that order).
///
/// Runs once, after license activation, guarded by a persisted flag in
/// secure storage. It is deliberately best-effort: a failure here must
/// never block the app from opening — the profiles list still works
/// without it, and the legacy creation-order mapping covers profiles
/// that never got a stored address.
///
/// v2 (TikTok-only build): the v1 flag is NOT reused, so this runs once
/// more on devices that already ran v1 — backfilling a stored address
/// onto any profile that still lacks one. A profile is NEVER left
/// without its permanent address: every existing profile gets one
/// (creation order, first still-free address), and the missing ones
/// are created as new profiles, until the licensed cap (SC5: 5,
/// SC10: 10 — never more than the 10 permanent addresses).
///
/// Rules:
/// - The existing first profile (creation order, i.e. the "Default"
///   that holds the user's data/tabs) is kept, renamed to "mia"
///   (metadata-only, so no restart and no data loss) when it receives
///   mia@ai.socialclone.app — unless another profile is already called
///   "mia", in which case its name is left alone and only the address
///   is stored. A profile that already has a stored address is never
///   touched.
/// - If the profiles list is empty (no default profile yet), nothing is
///   marked done: the flag is left unset so the next launch retries.
/// - If the user already has as many profiles as the licensed cap,
///   nothing new is created — but any profile still missing its stored
///   address is backfilled.
Future<void> seedPermanentProfiles(WidgetRef ref) async {
  const storage = FlutterSecureStorage();
  const seededKey = 'social_clone_profiles_seeded_v2';

  try {
    if (await storage.read(key: seededKey) != null) {
      return;
    }

    final repository = ref.read(profileRepositoryProvider.notifier);

    var profiles = await ref.read(profileRepositoryProvider.future);
    if (profiles.isEmpty) {
      // No default profile yet — leave the flag unset so a later
      // launch retries once the default profile exists.
      return;
    }

    // Licensed cap (SC5: 5, SC10: 10); never more than the 10
    // permanent addresses. createProfile enforces the same cap, so
    // the loop below can never overshoot it.
    final licensedCap =
        ref.read(licenseRepositoryProvider).value?.tier.maxProfiles ?? 10;
    final cap = licensedCap < permanentProfileEmails.length
        ? licensedCap
        : permanentProfileEmails.length;

    final assigned = <String>{
      for (final profile in profiles)
        if (profile.permanentEmail != null) profile.permanentEmail!,
    };

    // Backfill: every existing profile without a stored address gets
    // one, in creation order, first still-free address first. The
    // profile that receives mia@ is renamed "mia" (metadata-only)
    // unless the name is already taken.
    for (final profile in profiles) {
      if (profile.permanentEmail != null) {
        continue;
      }
      final free = permanentProfileEmails.firstWhereOrNull(
        (email) => !assigned.contains(email),
      );
      if (free == null) {
        break;
      }
      var name = profile.name;
      if (free == permanentProfileEmails.first) {
        final nameTaken = profiles.any(
          (other) =>
              other.uuidValue != profile.uuidValue && other.name == 'mia',
        );
        if (!nameTaken) {
          name = 'mia';
        }
      }
      await repository.updateProfileMetadata(
        Profile(
          id: profile.id,
          name: name,
          permanentEmail: free,
          authSettings: profile.authSettings,
        ),
      );
      assigned.add(free);
    }

    // The rest, in email order, until the licensed cap.
    for (final email in permanentProfileEmails) {
      if (assigned.contains(email)) {
        continue;
      }
      profiles = await ref.read(profileRepositoryProvider.future);
      if (profiles.length >= cap) {
        break;
      }
      await repository.createProfile(
        name: email.split('@').first,
        permanentEmail: email,
      );
      assigned.add(email);
    }

    await storage.write(key: seededKey, value: '1');
  } catch (_) {
    // Best-effort only: leave the flag unset so a later launch retries,
    // and never let seeding break app startup.
  }
}
