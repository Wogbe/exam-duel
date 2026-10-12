---
name: store-checklist
description: Research the current Apple App Store and Google Play publishing requirements and produce a checklist for Exam Duel, marked done, missing or unknown against what the repo actually has. Use when preparing a release, when the user asks about publishing or store requirements, or to refresh the checklist (policies change often). Runs on Sonnet in a separate context and saves docs/store-checklist.md.
model: sonnet
effort: high
context: fork
argument-hint: "[android | ios | topic]"
---

# Store checklist

Scope: $ARGUMENTS (empty means both stores).

## 1. Research live, never from memory

Store rules change several times a year. For every requirement, find the official
page (developer.apple.com, developer.android.com, support.google.com/googleplay,
play.google.com/console policy pages) with WebSearch (`extended` mode) and WebFetch,
and record the link. Cover at least:

- **Google Play**: developer account type and the closed-testing rule for new
  personal accounts; Android App Bundle (AAB) and Play App Signing / upload key;
  current target API level deadline; Data safety form; content rating (IARC);
  privacy policy URL; account deletion requirement; generative AI content policy
  (Ask Eve writes questions with Claude); Families policy if children may play;
  store listing assets (icon 512, feature graphic, screenshots).
- **Apple App Store**: Apple Developer Program; bundle id, certificates and
  provisioning; App Store Connect record; privacy "nutrition" labels; privacy
  manifest (`PrivacyInfo.xcprivacy`) and required-reason APIs used by plugins;
  account deletion (guideline 5.1.1(v)); age rating questionnaire; user-generated
  or AI content rules; Kids category rules if relevant; screenshot sizes;
  TestFlight review; export compliance (encryption).
- **Both**: privacy policy and terms; support URL or email; data the app collects
  (Supabase anonymous auth user id, nickname, answers, AI topic text sent to
  Anthropic); age and audience (an "exam" game may attract under-13s).

## 2. Audit the repo

Check what exists: `android/` and `ios/` folders, app id `com.mctech.exam_duel`,
signing config (`key.properties`; the README says the APK is debug-signed today),
`version:` in `pubspec.yaml`, icons in `assets/icon/`, permissions, the
`.github/workflows` builds (APK vs AAB), any privacy policy, and any way to delete data.

## 3. Write `docs/store-checklist.md`

Use this layout (overwrite the file and put the date at the top):

```
# Store checklist, <date>
## Blockers (must fix before submitting)
## Google Play   - [ ] item. Status: done / missing / unknown. Where in repo. Source link.
## Apple App Store
## Both stores
## Owner actions (accounts, payments, legal text)
```

## 4. Reply

Reply with the blockers list and the file path, in at most 12 lines.
