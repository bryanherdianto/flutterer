# Flutterer App

A Flutter app offering a set of AI / Machine Learning tools (text recognition,
barcode scanning, image labeling, and face detection) backed by Firebase
authentication and Supabase storage. Still in active development.

## Getting Started

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Supabase credentials

The app reads its Supabase URL and publishable key at build time via
`--dart-define`, so they are **not** hardcoded. Copy the template and fill in
your project's values:

```bash
cp env/supabase.example.json env/supabase.json
```

Then edit `env/supabase.json`:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

`env/supabase.json` is git-ignored, so your credentials stay out of version
control. Find both values in the Supabase dashboard under **Settings → API**.

Your Supabase project also needs a **public** storage bucket named `images`,
with policies that allow the app to upload, list, and delete objects.

### 3. Run the app

Pass the credentials file with `--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=env/supabase.json
```

To build a release APK:

```bash
flutter build apk --release --dart-define-from-file=env/supabase.json
```

> If you launch without the `--dart-define-from-file` flag, the app throws a
> `StateError` at startup explaining that the Supabase credentials are missing.

## Notes

- Firebase (project `auth-flutterer`) backs email/password and Google sign-in;
  its config lives in `lib/firebase_options.dart`. To point at a different
  Firebase project, run `flutterfire configure`.
- Google ML Kit runs entirely on-device — no API key or account required.
