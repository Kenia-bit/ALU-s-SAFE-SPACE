# Project Setup and Demo Configuration

## Requirements

- Flutter SDK and an Android emulator or physical Android device.
- A Firebase project with Email/Password sign-in enabled, Cloud Firestore
  configured, and the reviewed rules from [`firestore.rules`](firestore.rules)
  published.
- A Supabase project with a public Storage bucket named `report-photos`.

## Firebase setup

1. Configure Firebase for the Android platform and initialize the Firebase
   project.
2. Enable Email/Password sign-in in Firebase Authentication.
3. Create a Cloud Firestore database.
4. Review `firestore.rules`, then publish them from Firebase Console under
   **Firestore Database → Rules**. Review existing `users` documents before
   publishing: remove or correct unauthorized `role: staff` values.
5. Replace the example ALU email domains in the app and Firestore Rules if the
   real institutional domains differ.

Student accounts must verify their email before they can use student
functionality. If verification fails, signing in sends a fresh link; use the
newest link and sign in again after verification. Demo staff profiles begin
as `pending`; an administrator must confirm the staff member and change the
role to `staff` before staff access is granted. In production, require
verified staff email and use a trusted administrative approval process.

To approve a demo staff account, first have the staff member create an account
with an allowed staff address and sign in once. In Firebase Console, open
**Firestore Database → Data → users**, find the document whose ID is their
Firebase Authentication UID, confirm their identity, and set `role` to
`staff`. Have them sign in again.

## Supabase Storage setup

Create a **public** Storage bucket named `report-photos`, configure a bucket
size limit and allowed image MIME types, and add an `INSERT` policy for the
`anon` role scoped to the bucket. For example:

```sql
create policy "Allow report photo uploads"
on storage.objects for insert to anon
with check (
  bucket_id = 'report-photos'
  and storage.extension(name) in ('jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif')
);
```

Public buckets make photo URLs readable by anyone who has the URL. This
client-only upload policy also permits uploads by anyone with the app's public
anon key; it does not validate Firebase users. This is the instructor-approved
cost-conscious setup for the assignment. For production, route uploads through
a trusted backend that verifies Firebase ID tokens and enforces per-user
limits.

## Run on Android

Use `flutter devices` to find an Android device ID, then run:

```sh
flutter run -d <android-device-id> \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-public-anon-key>
```

The project also supports a `SUPABASE_STORAGE_BUCKET` define if you selected a
bucket with a different name. The current application expects `report-photos`.
The iOS platform target has been removed.

## Data and report lifecycle notes

User profiles are stored in the Firestore `users` collection. Reports are
stored in the `reports` collection, with optional attached images uploaded
under `reports/{userId}/{reportId}/` in Supabase Storage. Students see their
own reports; approved staff can review reports and update their status.

Staff can archive only completed Firestore reports. Archiving sets
`archivedAt` and keeps the report document and photo URL in Firestore.
Archived reports remain available from the Archived or All view. Restoring
clears `archivedAt` and returns the report to the active feed. Archiving is
not deletion; permanent deletion is denied by the client Firestore rules.

When the staff report feed has no Firestore reports, it displays local sample
reports for demonstration. Status changes on those samples are temporary;
real Firestore reports are updated persistently.
