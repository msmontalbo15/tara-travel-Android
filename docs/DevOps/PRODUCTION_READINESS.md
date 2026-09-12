# Tara Travel - Production Readiness Checklist

## Overview
Your app has solid CI/CD infrastructure via GitHub Actions. This checklist identifies what's **done**, what's **critical for launch**, and what's **nice-to-have**.

---

## ✅ What You Have (Already Configured)

| Component | Status | Details |
|-----------|--------|---------|
| **CI/CD Pipeline** | ✅ Configured | GitHub Actions: auto_release.yml with quality gates, versioning, builds |
| **Android Build** | ✅ Configured | APK + AAB (R8 obfuscation), split per ABI, release signing via secrets |
| **Static Analysis** | ✅ Configured | `flutter analyze --fatal-infos`, zero lints requirement |
| **Unit Tests** | ✅ Configured | Coverage gates with LCOV, test/all_tests.dart |
| **Distribution** | ✅ Configured | 3-channel: Supabase OTA + GitHub Releases + Firebase App Distribution |
| **Secrets Management** | ✅ Configured | .env at build time, GitHub Actions secrets for signing + Supabase keys |
| **Version Management** | ✅ Automated | Auto-increment build number, semantic versioning |
| **Firebase Setup** | ✅ Partial | google-services.json configured, needs token + app ID setup |
| **Splash Screen & Icons** | ✅ Configured | flutter_native_splash, flutter_launcher_icons in pubspec.yaml |

---

## 🔴 CRITICAL - Must Complete Before Launch

### 1. **iOS Build & Release**
**Current State:** Only Android configured.
**Action Items:**
- [ ] Set up Apple Developer Account and code signing certificates
- [ ] Create provisioning profiles for development + release (AppStore, TestFlight)
- [ ] Configure `ios/Runner.xcodeproj` with team ID and signing capabilities
- [ ] Add iOS build to GitHub Actions workflow
- [ ] Generate iOS build artifacts (IPA for TestFlight or App Store)
- [ ] Test TestFlight release build on actual iOS device

**GitHub Actions Addition:**
```yaml
build-ios:
  name: 🍎 Compile iOS Release IPA
  needs: [quality-gate, prepare-release]
  runs-on: macos-latest
  steps:
    - name: 🛎️ Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.41.6'
        channel: 'stable'
    
    - name: 📦 Install Dependencies
      run: flutter pub get
    
    - name: 🔐 Import Code Signing Certificate
      run: |
        # Install certificate from GitHub secrets
        echo "${{ secrets.IOS_CERTIFICATE_BASE64 }}" | base64 --decode > ios.p12
        security import ios.p12 -P "${{ secrets.IOS_CERTIFICATE_PASSWORD }}" -k ~/Library/Keychains/login.keychain
    
    - name: 🔨 Compile Release IPA
      run: |
        flutter build ios --release --no-tree-shake-icons \
          --build-name="${{ needs.prepare-release.outputs.version_name }}" \
          --build-number="${{ needs.prepare-release.outputs.build_number }}"
    
    - name: 📤 Upload to Artifact Storage
      uses: actions/upload-artifact@v4
      with:
        name: tara-travel-ios-release
        path: build/ios/iphoneos/Runner.app
```

---

### 2. **Google Play Store Setup & Release**
**Current State:** APK/AAB builds work, but no Play Store configuration.
**Action Items:**
- [ ] Create Google Play Developer account ($25 one-time fee)
- [ ] Create app listing on Google Play Console
- [ ] Set app category, target audience, rating (ESRB)
- [ ] Upload privacy policy URL (required; link to docs/PRIVACY_POLICY.md)
- [ ] Upload screenshots, app description, and store listing
- [ ] Generate OAuth 2.0 credentials for Play Store API (for automated releases)
- [ ] Configure Play Store signing key (can reuse Android keystore from CI/CD)
- [ ] Add `fastlane` or manual upload step to CI/CD for automated Play Store releases
- [ ] Submit for internal testing first, then closed beta, then live

**GitHub Actions Addition (Fastlane):**
```yaml
deploy-play-store:
  name: 📱 Deploy to Google Play Store
  needs: [build-android, prepare-release]
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/live'
  steps:
    - name: 🛎️ Checkout Repository
      uses: actions/checkout@v4
    
    - name: 📥 Retrieve Build Artifacts
      uses: actions/download-artifact@v4
      with:
        name: tara-travel-android-release
    
    - name: 🚀 Deploy AAB to Play Store Internal Testing
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJson: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
        packageName: com.taratravel.app
        releaseFiles: 'build/app/outputs/bundle/release/app-release.aab'
        track: internal
        releaseNotes: ${{ needs.prepare-release.outputs.release_notes }}
```

---

### 3. **App Store (iOS) Release**
**Current State:** Not configured.
**Action Items:**
- [ ] Create Apple App Store Connect account (free with Developer membership)
- [ ] Create app entry on App Store Connect
- [ ] Set app category, rating (IARC questionnaire)
- [ ] Upload privacy policy (docs/PRIVACY_POLICY.md)
- [ ] Upload app screenshots (for iPhone, iPad if supported)
- [ ] Set up beta testers via TestFlight
- [ ] Generate App Store Connect API key (for automated releases)
- [ ] Add release workflow to GitHub Actions
- [ ] Submit to beta review, then App Store review

**Privacy & Compliance:**
- [ ] Create PRIVACY_POLICY.md (Apple/Google require this)
- [ ] Create TERMS_OF_SERVICE.md
- [ ] Enable privacy label in app info (data collection disclosure)

---

### 4. **Crash Reporting & Monitoring Setup**
**Current State:** No crash reporter configured.
**Risk:** Production crashes have no visibility; users report via app store only.
**Action Items:**
- [ ] Choose crash reporter: Firebase Crashlytics (free + part of Firebase) or Sentry (free tier: 5k events/month)
- [ ] Add dependency: `firebase_crashlytics` or `sentry_flutter`
- [ ] Initialize in main() with error callbacks
- [ ] Test: trigger crash and verify it appears in dashboard
- [ ] Set up Slack/email alerts for critical crashes
- [ ] Enable custom error logging (not just stack traces)

**Example (Firebase Crashlytics):**
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const MyApp());
}
```

---

### 5. **API Rate Limiting & Abuse Prevention**
**Current State:** Client-side 2s throttle exists; no server-side limits visible.
**Action Items:**
- [ ] Configure Supabase rate limits (if available in plan)
- [ ] Add server-side rate limiting for auth endpoints (e.g., 5 login attempts per minute)
- [ ] Implement CAPTCHA for repeated failures (optional: use reCAPTCHA)
- [ ] Set DDoS protection on Supabase (check PostgreSQL pool settings)
- [ ] Log suspicious activity (>10 failed logins per user per hour)
- [ ] Add manual account lockout capability for admins (security dashboard)

---

### 6. **Performance Profiling & Baseline**
**Current State:** No performance benchmarks documented.
**Action Items:**
- [ ] Profile app startup time: target < 2 seconds on mid-range Android (Pixel 4a)
- [ ] Profile memory usage: target < 150MB on initial load
- [ ] Identify slow screens (use DevTools profiler):
  - [ ] Splash → Home (should be instant)
  - [ ] Create Trip flow (should complete in < 3s)
  - [ ] Chat screen (should load messages in < 1s)
- [ ] Benchmark Supabase query times (enable query logging)
- [ ] Optimize slow queries with indexes
- [ ] Document baseline metrics in `docs/PERFORMANCE.md`

**DevTools Profiler Command:**
```bash
flutter run --profile
# Then use: `dart devtools` → Performance tab
```

---

### 7. **Database Backups & Recovery Plan**
**Current State:** Relies on Supabase automatic backups (default 7 days).
**Action Items:**
- [ ] Verify Supabase backup settings (check free plan includes backups)
- [ ] Test restore procedure: export test data, delete, restore
- [ ] Document recovery time objective (RTO) and data loss tolerance (RPO)
- [ ] Create disaster recovery runbook (who to contact, how to restore)
- [ ] Set up automated backups to external storage if needed (e.g., S3)
- [ ] Document backup retention policy (legal/compliance requirement)

---

### 8. **Push Notifications Production Setup**
**Current State:** Configured for dev/Expo Go; production needs EAS or Expo Router.
**Action Items:**
- [ ] If using Expo: set up EAS (Expo Application Services) account
- [ ] Generate APNs certificate (Apple) and FCM server key (Google)
- [ ] Configure `expo-notifications` in app.json with Android + iOS channels
- [ ] Test push notifications end-to-end:
  - [ ] Send notification from Supabase → verify app receives it
  - [ ] Test notification when app is backgrounded, killed
- [ ] Set up notification dashboard (Firebase Cloud Messaging or Expo Notifications)
- [ ] Document notification delivery SLA (e.g., "99% within 5 minutes")

---

### 9. **Signing Keys Management**
**Current State:** Android keystore via GitHub secrets; needs documentation.
**Action Items:**
- [ ] Back up Android keystore to secure location (NOT in Git)
- [ ] Document keystore password (stored securely, not in Git)
- [ ] Back up iOS code signing certificates to secure location
- [ ] Document key rotation procedure (when/how to rotate signing keys)
- [ ] Ensure only authorized developers have access to signing keys
- [ ] Add signing key access log (who accessed when)
- [ ] Create incident response: if signing key is compromised, revoke + regenerate

**Backup Checklist:**
```bash
# Backup Android keystore
gpg --symmetric --cipher-algo AES256 android/app/release.keystore
# Output: release.keystore.gpg (store securely, not in Git)

# Document: keystore password + key alias + key password in secure vault
# (1Password, Bitwarden, AWS Secrets Manager, etc.)
```

---

## 🟠 HIGH PRIORITY - Do Before Public Beta

### 10. **Error & Exception Handling**
**Current State:** Crashes may not be user-friendly.
**Action Items:**
- [ ] Create custom error screen for unhandled exceptions (not raw stack traces)
- [ ] Implement error recovery: "Retry" button for network errors
- [ ] Add user-facing error messages (not technical jargon)
- [ ] Log all errors to crash reporter (with context: user ID, screen, action)
- [ ] Test error scenarios:
  - [ ] Network offline → should show friendly message + retry button
  - [ ] Auth token expired → should redirect to login
  - [ ] Database error → should show "Something went wrong" + retry
  - [ ] Memory pressure → should gracefully degrade

---

### 11. **Sensitive Operations Audit & Confirmation**
**Current State:** Some sensitive operations (delete trip) may not have confirmation.
**Action Items:**
- [ ] Add confirmation dialogs for destructive operations:
  - [ ] Delete trip
  - [ ] Remove member
  - [ ] Sign out (clear all data)
- [ ] Require biometric re-auth for sensitive operations (see SECURITY_RECOMMENDATIONS.md)
- [ ] Log all sensitive operations to audit log
- [ ] Display confirmation summary before execution

---

### 12. **Dark Mode & Accessibility**
**Current State:** Unknown if dark mode is implemented; accessibility untested.
**Action Items:**
- [ ] Audit dark mode: ensure all colors pass WCAG AA contrast ratios (4.5:1 for text)
- [ ] Test screen reader compatibility (TalkBack on Android, VoiceOver on iOS)
- [ ] Verify font sizes are scalable (users can increase via accessibility settings)
- [ ] Test with minimum font scale (70%) and maximum (200%)
- [ ] Verify color is not sole indicator (e.g., red = error should also have icon)
- [ ] Test with keyboard navigation (no touch required)

**Flutter Accessibility Audit:**
```bash
flutter analyze --fatal-infos  # Catches some accessibility issues
# Manual testing: Settings → Accessibility → Text scaling / Screen reader
```

---

### 13. **Localization (i18n)**
**Current State:** `intl: ^0.20.2` is included but usage unclear.
**Action Items:**
- [ ] List supported languages (English only for MVP, or add others?)
- [ ] Extract all user-facing strings to `.arb` files (Flutter i18n standard)
- [ ] Create locale-specific number/date formatting
- [ ] Set up translation pipeline (manual or via Crowdin)
- [ ] Test right-to-left (RTL) languages if supporting Arabic/Hebrew
- [ ] Add language selector in Settings

---

### 14. **Terms of Service & Privacy Policy**
**Current State:** Not yet created.
**Action Items:**
- [ ] Create TERMS_OF_SERVICE.md covering:
  - User responsibilities
  - Acceptable use policy
  - Liability limitations
  - Dispute resolution
- [ ] Create PRIVACY_POLICY.md covering:
  - What data is collected (auth, location, photos, etc.)
  - Why data is collected
  - How long data is stored
  - User rights (access, deletion, portability)
  - Third-party services (Supabase, Google, Firebase)
- [ ] Have legal review (or use template service like Termly)
- [ ] Link from app settings + app store listing
- [ ] Ensure GDPR compliance if serving EU users

---

### 15. **Update & Version Management**
**Current State:** Partially configured (auto_release.yml has version gates).
**Action Items:**
- [ ] Define version deprecation policy (e.g., "support last 2 major versions")
- [ ] Configure forced update trigger: if minimum_supported_version > app_version
- [ ] Set maintenance_mode flag for scheduled downtime
- [ ] Test version gate flow:
  - [ ] Old app version → force update dialog → redirect to store
  - [ ] Maintenance mode → show maintenance screen → retry
- [ ] Document version bump triggers (security patch, feature release, etc.)

---

## 🟡 MEDIUM PRIORITY - Do Before Full Release

### 16. **Analytics & User Insights**
**Current State:** No analytics configured.
**Recommendations:**
- [ ] Choose analytics: Firebase Analytics (free) or Mixpanel (free tier)
- [ ] Track key events:
  - [ ] User sign-ups and sign-ins
  - [ ] Trip creation / completion
  - [ ] Feature adoption (chat, budget, packing list)
  - [ ] Error rates
- [ ] Set up funnels: Sign-up → First Trip → Invite Friend
- [ ] Create dashboards for stakeholders

**Firebase Analytics Example:**
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// Track event
await analytics.logEvent(
  name: 'trip_created',
  parameters: {
    'destination': destination,
    'num_members': members.length,
    'currency': tripBudgetCurrency,
  },
);
```

---

### 17. **Load Testing & Capacity Planning**
**Current State:** Unknown if system can handle >1000 concurrent users.
**Action Items:**
- [ ] Load test Supabase database: simulate >100 concurrent users
- [ ] Monitor Supabase metrics: connection pool, query latency, storage usage
- [ ] Load test APIs: auth, trips, chat, budget
- [ ] Identify bottlenecks and optimize:
  - [ ] Add database indexes for slow queries
  - [ ] Enable query caching where applicable
  - [ ] Implement pagination for large lists
- [ ] Document capacity: "System supports X concurrent users with Y RPS"
- [ ] Plan scaling: when to upgrade Supabase plan

**Example (Artillery load test):**
```bash
artillery quick --count 100 --num 1000 https://api.supabase.co/rest/v1/trips
```

---

### 18. **Documentation & Runbooks**
**Current State:** Minimal.
**Action Items:**
- [ ] Create USER GUIDE (in-app help or web docs)
- [ ] Create DEVELOPER GUIDE (for onboarding new developers)
- [ ] Create OPERATIONS RUNBOOK:
  - [ ] How to deploy a hotfix
  - [ ] How to rollback a release
  - [ ] How to diagnose performance issues
  - [ ] How to respond to security incidents
  - [ ] How to contact on-call engineer
- [ ] Create FAQ (common user questions)
- [ ] Document known issues and workarounds

---

### 19. **Monitoring & Alerting**
**Current State:** No monitoring configured.
**Action Items:**
- [ ] Set up status page (Statuspage.io or manual)
- [ ] Configure alerts for:
  - [ ] High crash rate (>5% of sessions)
  - [ ] Supabase unavailability (HTTP 500+)
  - [ ] High auth failures (>10% rate)
  - [ ] Database disk usage >80%
  - [ ] API latency >1s for 99th percentile
- [ ] Route alerts to on-call engineer (Pagerduty, Opsgenie)
- [ ] Document alert runbooks: what to do when alert fires

---

### 20. **Support & Feedback Channel**
**Current State:** No in-app support configured.
**Action Items:**
- [ ] Add in-app feedback button (sends to support email or Zendesk)
- [ ] Create support email (support@taratravel.app)
- [ ] Set up support ticketing system (Zendesk, Intercom, or simple Google Form)
- [ ] Document support SLA (response time, resolution time)
- [ ] Train support team on common issues
- [ ] Link to help docs from in-app support button

---

## Implementation Timeline

### Phase 0 (Week 1): Critical Infrastructure
1. iOS build setup + App Store Connect
2. Google Play Store setup
3. Crash reporting (Firebase Crashlytics)
4. API rate limiting & abuse prevention
5. Push notifications production setup

### Phase 1 (Week 2): Hardening
6. Error & exception handling
7. Sensitive operations audit & confirmation
8. Dark mode & accessibility audit
9. Signing keys management & backup
10. Database backups & recovery

### Phase 2 (Week 3): Polish & Documentation
11. Localization setup (if multi-language)
12. Terms of Service & Privacy Policy
13. Version management & update flow
14. Analytics setup
15. Documentation & runbooks

### Phase 3 (Week 4+): Scaling & Monitoring
16. Load testing & capacity planning
17. Monitoring & alerting
18. Support channel setup
19. Performance baseline & optimization
20. Public beta feedback loop

---

## Pre-Launch Checklist (72 Hours Before)

- [ ] All critical issues fixed
- [ ] iOS + Android builds compile without warnings
- [ ] Play Store internal testing release successful
- [ ] TestFlight beta testing in progress (minimum 5 beta testers)
- [ ] Crash reporting operational
- [ ] Database backups verified
- [ ] Signing keys backed up and documented
- [ ] Terms of Service + Privacy Policy live
- [ ] Support email functional
- [ ] All team members trained on deployment procedure
- [ ] Rollback procedure documented and tested
- [ ] On-call engineer assigned for launch week

---

## Post-Launch Monitoring (Launch Week)

**Daily:**
- [ ] Check crash reports for critical issues
- [ ] Monitor user feedback (Play Store, App Store reviews)
- [ ] Monitor analytics: sign-up rate, key event completion
- [ ] Check database performance: query latency, connection pool

**If Critical Bug Found:**
1. Assess severity: does it block core functionality?
2. If yes: prepare hotfix, test on internal build, release to Play Store/App Store
3. Notify users via in-app notification or push notification
4. Post-mortem: document what went wrong and prevention

---

## Success Criteria

✅ App is live on Play Store + App Store
✅ Crash rate < 1%
✅ User sign-up conversion > 40%
✅ First trip creation completion > 60%
✅ App latency < 2s for 95th percentile
✅ Zero critical security issues in first month
✅ Support response time < 24 hours

---

## Questions for Your Team

1. Do you have an Apple Developer account? (Required for iOS App Store)
2. Do you have a Google Play Developer account? (Required for Google Play)
3. Who will manage production incidents during first month?
4. What is your target launch date?
5. How many beta testers are you planning?
6. Do you need multi-language support for launch, or English-only MVP?
7. Is there a legal team reviewing Terms/Privacy, or using a template service?

