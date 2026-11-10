# Social Clone

One phone. Many TikTok and Facebook accounts.

Social Clone is a focused Android kiosk browser: every work account lives in
its own isolated profile with its own cookies and login state, so you can
switch between TikTok and Facebook accounts with one tap — no logging in and
out all day. No Gmail, no address bar, no general browsing.

- **Isolated profiles** — one profile per account, fully separate sessions
- **One-tap switching** — jump between profiles from the home screen
- **TikTok + Facebook only** — a kiosk for the two platforms you work on
- **License-code activation** — one field; the app detects your plan from the code

## Pricing

| Plan | Profiles | Price |
| --- | --- | --- |
| SC5 | 5 profiles | **$7** |
| SC10 | 10 profiles | **$9** — best value |

License codes are 30 characters (SC5) or 40 characters (SC10). Buy a plan at
[https://socialclone.app](https://socialclone.app) — email
[info@toolzo.app](mailto:info@toolzo.app) and your code is sent after payment
is confirmed.

## How to build

Social Clone is a Flutter app (see `apps/weblibre/`). A build needs the
Flutter SDK, Android SDK + NDK, Go (for the native runtime), and Node 20.

```sh
dart pub global activate melos 7.8.1
melos bootstrap
python3 scripts/merge_l10n_arb.py
melos run update-assets --no-select
melos run build-components --no-select
```

Then build the app from `apps/weblibre/` with `flutter build apk` (or
`flutter build appbundle` for a Play Store submission). The GitHub Actions
workflows in `.github/workflows/` do the same steps: `build-test-apk.yml`
(manual, test APK) and `build.yml` (runs on version tags `v*`).

Do **not** trigger a build on every push — builds run on manual dispatch or
on a `v*` tag only.

## License dashboard

`dashboard/` is a Cloudflare Workers + D1 service that issues and validates
license codes (SC5 / SC10) and reports on them. See `dashboard/README.md`.

## License

Social Clone is built on [WebLibre](https://github.com/FaFre/WebLibre), a
privacy-focused Android browser, and is released under the GNU Affero General
Public License v3 — see [COPYING](COPYING).
