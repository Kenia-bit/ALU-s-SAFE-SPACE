# ALU Safe Space

## Individual Assignment 2: Technical Report

**Campus Incident Reporting App**  
**Student:** Kenia Umutoni  
**Platform:** Flutter mobile application for Android  
**Citation style:** APA 7th edition

> **Before submitting:** Replace the GitHub and demonstration-video placeholders
> with working links, add genuine screenshots from the running app, and submit
> this report as a PDF through Canvas using the required filename format.

**GitHub repository:** [Add repository link here]  
**7–10 minute demonstration video:** [Add video link here]

## Abstract

ALU Safe Space is a Flutter mobile application that gives students a
centralized way to report campus incidents and enables approved staff to review
reports and track their resolution. A report contains a title, category,
campus location, description, optional photograph, reporter information,
status, and timestamps. Firebase Authentication supports account registration
and sign-in; Cloud Firestore stores user profiles and incident records and
provides live report updates. Supabase Storage is used for incident photographs
as a cost-conscious storage service, with the instructor's approval. The
application uses Provider for shared theme state, widget-local state for form
and filter interactions, and Firestore streams for synchronized report data.
Firestore Security Rules enforce verified-student ownership and approved-staff
access to report operations. This report describes the architecture, data
model, role controls, user experience, verification completed, implementation
decisions, and lessons from building the application.

**Keywords:** Flutter, campus safety, incident reporting, Firebase
Authentication, Cloud Firestore, Supabase Storage, Provider, role-based access

## 1. Introduction

Campus issues such as damaged facilities, power interruptions, sanitation
concerns, and safety hazards need a clear route from discovery to action. ALU
Safe Space makes reporting and follow-up more visible: a student submits a
structured report, authorized staff review the shared queue and update its
status, and students can revisit their own reports to see progress.

The application is built with Flutter and targets Android. Its primary user
journeys are account creation and sign-in, incident submission, report browsing
and filtering, and staff status management. The design combines a tab-based hub
with focused forms, status labels, validation messages, loading indicators,
and feedback after asynchronous operations.

## 2. Requirements and Implemented Features

| Requirement | Implementation |
|---|---|
| Student and staff accounts | Email/password registration and sign-in through Firebase Authentication. Students verify their ALU student email. Staff accounts begin as pending and require administrator approval. |
| Incident submission | Validated title, category, campus location, and description fields, with an optional gallery photo. |
| Persistent report records | Cloud Firestore documents in the `reports` collection, including reporter identity, current status, and timestamps. |
| Browse and track | Live report feeds, report cards with category/location/status, student-owned report views, and a staff-wide review feed. |
| Search and filtering | Text search across report title, category, location, and description, with status/category filters; staff can also switch among active, archived, and all records. |
| Staff workflow | Approved staff can change status among Waiting, In Progress, and Completed, and archive or restore completed reports. |
| Mobile experience | Android app with Home, Reports, and Profile navigation, light/dark themes, image selection, loading feedback, and error messages. |

## 3. Application Architecture and State Management

The project has a Flutter presentation layer connected to Firebase services and
Supabase Storage through their Flutter SDKs. Screens compose widgets and handle
user interactions; Firebase Authentication identifies the signed-in user;
Firestore queries and streams provide persisted report data; and Supabase
Storage handles optional photo files. Firestore Security Rules validate access
independently of the presentation layer.

```text
+------------------------+     +-------------------------+
| Flutter UI             |     | State and interaction   |
| Login / Signup         |<--->| Provider theme state    |
| Home / Report form     |     | Widget form and filter  |
| Feed / Profile         |     | state                   |
+------------------------+     +-------------------------+
            |                               |
            v                               v
+------------------------+     +-------------------------+
| Firebase Authentication|     | Cloud Firestore         |
| Email/password         |     | users and reports       |
| Student verification   |     | live report streams     |
+------------------------+     | Security Rules          |
                                +-------------------------+
                                             |
                                             | image URL
                                             v
                                +-------------------------+
                                | Supabase Storage        |
                                | report-photos bucket    |
                                +-------------------------+
```

**Figure 1.** ALU Safe Space application architecture and service boundaries.

State is handled with a method suited to each scope. Provider exposes the
shared `AppThemeProvider`, allowing the app bar and Material theme to respond
to light/dark mode changes. Stateful widgets manage short-lived interface
state such as the active tab, form fields, submission/loading indicators,
selected image, and search/filter selections. Firestore snapshot streams drive
report lists and dashboard updates, so persisted changes appear in the
relevant views without manually copying report data between screens. This
combination keeps interactive UI state close to its widgets while shared
presentation preferences and backend-owned records are handled at their
appropriate scopes. This is a practical fit for the application's current
feature set and follows Flutter's guidance to adapt architecture to an
application's needs (Flutter, n.d.).

Asynchronous operations are awaited and provide user-facing progress or error
feedback. Examples include authentication, loading a selected image, uploading
a photo, writing a report, and updating status or archive metadata.

## 4. User Experience and Navigation

The home screen greets the signed-in user, shows campus context, and presents
role-relevant actions and report updates. Bottom navigation provides access to
Home, Reports, and Profile. Students can start a report from a prominent action
card; staff use the reports feed as their review workspace. A shared visual
language uses navy/blue accents, cards, clear labels, and status colors, with a
light/dark theme toggle.

The report form asks for an issue title, category, location, explanation, and
optional photo. Required fields are validated before submission. The image
preview can be removed before the report is sent. On successful submission,
feedback confirms the result; when optional image upload fails, the user is
told that the report was still submitted without the image. Report cards show
the issue category, title, location, description, photo when available, and
status. Staff receive a status selector and completed-report archive controls.

### Application screenshots

Replace each placeholder with a real screenshot from the running Android app.
Use screenshots of your own test accounts and sample reports; do not include
passwords, verification links, or private account details.

**Figure 2. Authentication workflow**

> [Insert screenshot: ALU Safe Space sign-in or registration screen.]

**Figure 3. Student incident submission**

> [Insert screenshot: completed report form showing category, location,
> description, and selected photo.]

**Figure 4. Student report browsing and status tracking**

> [Insert screenshot: student report list showing search/filter controls and a
> persisted report status.]

**Figure 5. Staff report-management workflow**

> [Insert screenshot: approved staff view showing a report status update or
> archive control.]

## 5. Authentication, Roles, and Access Control

Firebase Authentication is initialized at application startup. Registration
creates an email/password account and records a display name. Student addresses
must use the configured `@alustudent.com` domain; student verification email
is sent before the student can access student functionality. Login reloads
the Firebase user and checks verification. If verification is incomplete, the
app requests a new link, signs the user out, and displays guidance to use the
newest link. Firebase Authentication's Flutter SDK supports these account and
verification workflows (Google, n.d.-a).

Staff addresses use the configured `@alustaff.com` domain. A newly created
staff profile receives the `pending` role. An administrator confirms the
staff member and changes the corresponding Firestore profile role to `staff`;
the app then permits staff access on sign-in. This approval step distinguishes
staff identity from staff authorization.

| Role | Application behavior | Firestore authorization |
|---|---|---|
| Student | Create reports; read reports whose `reporterUid` matches the signed-in user; see status updates. | Requires verified student-domain email and a matching `users/{uid}` profile with role `student`. Report creation requires the authenticated UID and email to match the report fields. |
| Pending staff | Cannot enter staff functionality until an administrator approves the profile. | Does not satisfy the approved-staff role check. |
| Approved staff | Review the shared feed, update report status, and archive/restore completed reports. | Requires a staff-domain email and a matching user profile with role `staff`. Rules limit editable report fields to status/timestamps/archive metadata. |

Firestore Security Rules are the enforcement boundary, not just the UI. They
constrain profile creation and role transitions, student report ownership,
staff report updates, required fields, status values, and archive conditions.
Client-side permanent deletion is denied; the implemented lifecycle uses
archive and restore operations instead. Firebase recommends combining
Authentication with Firestore Rules for user- and role-based access control
(Google, n.d.-c).

## 6. Firebase Data Structure and Photo Storage

Cloud Firestore uses document-oriented collections. User profiles are keyed by
Firebase UID so authorization can compare the signed-in UID directly to the
document ID. Reports use generated document IDs and retain reporter identity
fields for ownership filtering and staff context. Firestore supports this
collection/document structure for application data that grows over time
(Google, n.d.-b).

```text
users/{uid}
  name
  email
  role: student | pending | staff
  createdAt

reports/{reportId}
  title
  category
  location
  description
  imageUrl
  reporterUid
  reporterEmail
  reporterName
  status: Waiting | In Progress | Completed
  createdAt
  statusUpdatedAt
  archivedAt
```

**Figure 6.** Main Firestore collections and report fields.

Report status begins as `Waiting` and may progress to `In Progress` and
`Completed`. `statusUpdatedAt` records staff changes; `archivedAt`
distinguishes active records from archived records. Archiving retains the
Firestore document and photo URL, supporting restoration and historical
review.

Optional incident photographs are uploaded to the Supabase Storage bucket
`report-photos`, using a path of the form
`reports/{userId}/{reportId}/photo.ext`. The resulting public URL is saved in
the Firestore report's `imageUrl` field. This separates structured incident
metadata from binary image data. Supabase Storage supports uploading files to
a bucket and retrieving public URLs for objects in a public bucket (Supabase,
n.d.).

Supabase Storage is the instructor-approved, cost-conscious choice for report
photographs in this project; Firebase Authentication and Cloud Firestore
remain the identity and incident-data services. The current demo configuration
uses a public bucket and an anon-key upload policy scoped to the bucket and
image extensions. As a result, a photo URL is readable by anyone who obtains
it, and the client upload policy is not itself a Firebase-user authorization
check. The storage setup and production considerations are also documented in
the project setup instructions below.

## 7. Core Workflows

### 7.1 Student submits an incident

1. The student registers with an ALU student address, follows the verification
   link, and signs in.
2. The student opens the report form, enters a title, chooses a category,
   specifies a campus location, and describes the issue.
3. The student may select an image from the gallery. The app displays a
   preview before submission.
4. After validation, the app creates a Firestore report ID, attempts the
   optional photo upload to Supabase Storage, and writes the report fields to
   Firestore.
5. The report appears in the student's live feed. If the optional photo
   cannot be uploaded, the report can still be submitted and the user is shown
   an explicit message.

### 7.2 Student tracks a report

The student report query is scoped to the signed-in UID. Snapshot updates
refresh the list as Firestore data changes. Search matches report text, while
status and category controls narrow the visible results. A status timestamp
supports dashboard updates for reports whose status has changed.

### 7.3 Staff reviews and updates a report

An administrator first approves a staff profile in Firestore. After approved
staff sign in, the staff feed reads reports across users. Staff can change a
report's status; Firestore Rules verify the role and limit the fields that can
be changed. Completed reports may be archived and later restored. When no
Firestore reports exist, the staff feed shows local demonstration examples;
changes to these examples are temporary and are not represented as persisted
backend records.

## 8. Testing and Verification

The development workspace was checked with static analysis and the existing
widget test:

- `flutter analyze` completed with **No issues found**.
- `flutter test` passed the widget test that verifies the login screen
  presents the ALU Safe Space heading, email field, password field, and
  sign-in action.

These checks confirm the code is analyzable and the login view renders the
expected primary controls. They do not replace integration testing with
configured Firebase/Supabase services or manual device testing. Before
recording the demonstration, verify the following end-to-end on an Android
emulator or physical device and capture genuine screenshots:

1. Register a student, verify the address, sign in, and confirm the student
   profile in Firebase Authentication and Firestore.
2. Submit a report with all required fields and a photo; confirm the report
   document, Storage object, and displayed photo URL.
3. Search and filter the student's reports; confirm only that student's
   records are visible.
4. Sign in as approved staff, update a report status, then confirm the changed
   value and timestamp in Firestore and in the student's view.
5. Archive and restore a completed report, and verify both transitions
   persist.
6. Check validation and visible error feedback for missing fields, denied
   permissions, unavailable network, and optional photo-upload failure.

For Firebase-backed testing, use the Firebase Console to inspect
Authentication users, corresponding `users` profiles, and report documents.
Inspect uploaded photos in the Supabase project dashboard.

## 9. Implementation Decisions, Challenges, and Lessons

**Role approval.** A staff email domain alone does not grant staff privileges.
New staff begin as pending, and an administrator approves the Firestore role.
The app and Firestore Rules both check that role, illustrating the difference
between identifying an account and authorizing an operation.

**Asynchronous reporting.** A report may include a photograph, but a photo is
optional. Separating the photo upload from the Firestore write allows a useful
report to be created even if the image service is not configured or an upload
fails; the user receives feedback about the missing photo rather than a
false image-success state.

**Live data and local interaction state.** Search, filters, form inputs, and
theme selection have different lifetimes and scopes from reports stored in the
backend. Provider, widget state, and Firestore streams are used together so
that each part of the interface has a clear source of state.

**Archive instead of client deletion.** Permanent deletion is denied by the
client rules. Archive/restore provides a reversible staff workflow while
retaining report history and any photo reference.

Key lessons are that role checks must be enforced by backend rules,
asynchronous actions need clear loading/error feedback, and data ownership
should be represented explicitly in each record. A further lesson is to
distinguish persisted records from local demonstration examples so staff do
not mistake sample data for real campus reports. Any broader deployment
should review the storage policy and photo access model against institutional
privacy requirements.

## 10. Demonstration and Submission Checklist

- **GitHub repository:** [Add the repository link here.]
- **Demonstration video:** [Add the 7–10 minute video link here.]
- **Screenshots:** Replace the four placeholders above with genuine app
  screenshots.
- **Demonstration flow:** Show student registration/sign-in and email
  verification; submit a report with a photo; browse, search, and filter
  student reports; sign in as approved staff and update report status; and
  show the relevant Firebase Console records and explain the architecture,
  state-management approach, and approved Supabase photo-storage choice.
- **Canvas filename:** `Kenia_Umutoni_Assignment2.pdf`

## 11. Conclusion

ALU Safe Space brings student incident submission and staff follow-up into one
Android-oriented Flutter application. Firebase Authentication provides account
identity, Cloud Firestore persists profiles and report lifecycles, and Supabase
Storage provides cost-conscious photo storage with the instructor's approval.
Provider-managed theme state, local widget interaction state, and Firestore
snapshot streams work together to keep the interface responsive and report
data current. Role-aware Firestore Rules, verified student accounts, staff
approval, required-field validation, and explicit asynchronous feedback
support a clear reporting experience. The final submission should include the
working repository and demonstration links, plus authentic workflow
screenshots in this report.

## References

Flutter. (n.d.). *Guide to app architecture*.
https://docs.flutter.dev/app-architecture/guide

Google. (n.d.-a). *Get started with Firebase Authentication on Flutter*.
Firebase Documentation.
https://firebase.google.com/docs/auth/flutter/start

Google. (n.d.-b). *Structure data in Cloud Firestore*. Firebase Documentation.
https://firebase.google.com/docs/firestore/manage-data/structure-data

Google. (n.d.-c). *Get started with Cloud Firestore Security Rules*. Firebase
Documentation. https://firebase.google.com/docs/firestore/security/get-started

Supabase. (n.d.). *Standard uploads*. Supabase Documentation.
https://supabase.com/docs/guides/storage/uploads/standard-uploads

---

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