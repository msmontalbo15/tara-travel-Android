# Tara Travel - Security Recommendations & Action Items

## Overview
Tara Travel has strong encryption and session management foundations. This document outlines 12 key areas for security improvement, organized by priority and implementation difficulty.

---

## 🔴 High Priority (Critical Security Gaps)

### 1. HTTPS Certificate Pinning
**Current State:** Soft validation only (checks `scheme == 'https'`), no certificate pinning.
**Risk:** Vulnerable to MITM attacks if a Certificate Authority is compromised.
**Action Items:**
- [ ] Extract SHA-256 fingerprints of Supabase domain certificate(s)
- [ ] Implement certificate pinning via `Dio` HTTP client interceptor
- [ ] Add pinning for any other critical API endpoints
- [ ] Test pinning with self-signed cert (verify app blocks connection)
- [ ] Document certificate rotation procedures

**Implementation Reference:**
```dart
// In your Dio setup, add:
dio.httpClientAdapter = DefaultHttpClientAdapter()
  ..onHttpClientCreate = (HttpClient client) {
    client.badCertificateCallback = (cert, host, port) {
      // Verify against pinned certificates
      return _verifyPinnedCertificate(cert, host);
    };
  };
```

---

### 2. Supabase Row-Level Security (RLS) Audit
**Current State:** No visible RLS policies in codebase; auth delegated to backend.
**Risk:** If RLS is misconfigured, users could access/modify others' data.
**Action Items:**
- [ ] Log into Supabase PostgreSQL editor
- [ ] Audit RLS policies on all tables: `users`, `trips`, `members`, `expenses`, `chat_messages`, etc.
- [ ] Verify each policy enforces `auth.uid() = user_id` or equivalent ownership check
- [ ] Test with JWT impersonation: verify a user cannot query another user's trips
- [ ] Document RLS policy intent for each table (create SECURITY.md in supabase/ folder)
- [ ] Enable RLS enforcement mode: set `pgrst.db_pre_request_check = true` in Supabase settings

**Documentation Template:**
```sql
-- users table: only the user can read/update their own record
CREATE POLICY "Users can read own record" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own record" ON users
  FOR UPDATE USING (auth.uid() = id);

-- trips table: owner can do anything; members can read
CREATE POLICY "Trip owner full access" ON trips
  FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "Trip members can read" ON trips
  FOR SELECT USING (
    auth.uid() = owner_id 
    OR EXISTS (SELECT 1 FROM trip_members WHERE trip_id = trips.id AND user_id = auth.uid())
  );
```

---

### 3. Dependency Vulnerability Scanning
**Current State:** No automated scanning mentioned.
**Risk:** Known vulnerabilities in `pointycastle`, `encrypt`, `supabase_flutter`, etc. could be exploited.
**Action Items:**
- [ ] Run `flutter pub audit` locally and fix any `high` or `critical` issues
- [ ] Add GitHub Actions workflow for continuous scanning
- [ ] Set up Dependabot to auto-create PRs for vulnerable dependencies
- [ ] Configure branch protection: block merge if audit fails
- [ ] Document vulnerability response time (e.g., patch within 48h)

**GitHub Actions Example:**
```yaml
name: Dependency Audit
on: [pull_request, push]
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter pub audit --exit-on-error
```

---

### 4. Sensitive Data Logging & Redaction
**Current State:** Debug prints may leak tokens, user IDs, exception messages in crash reports.
**Risk:** Sensitive data exposed to Sentry, Firebase Crashlytics, or device logs.
**Action Items:**
- [ ] Create `SecureLogger` utility that redacts PII/auth tokens before logging
- [ ] Replace all `debugPrint` with `SecureLogger.debug()`
- [ ] Disable debug logs in release builds (use `kReleaseMode` guard)
- [ ] Configure crash reporters (Sentry/Firebase) to exclude sensitive fields
- [ ] Add lint rule to catch `print()` / `debugPrint()` without context
- [ ] Audit `main.dart`, `auth_notifier.dart`, `three_layer_encryption_service.dart` for token logging

**SecureLogger Implementation:**
```dart
class SecureLogger {
  static void debug(String message) {
    if (kDebugMode) {
      final redacted = _redactSensitiveData(message);
      debugPrint('[TARA] $redacted');
    }
  }

  static String _redactSensitiveData(String msg) {
    return msg
      .replaceAll(RegExp(r'(eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)'), '[JWT_REDACTED]')
      .replaceAll(RegExp(r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'), '[UUID_REDACTED]')
      .replaceAll(RegExp(r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'), '[EMAIL_REDACTED]');
  }
}
```

---

## 🟠 Medium Priority (Important Improvements)

### 5. Server-Side Audit Log Ingestion
**Current State:** Audit logs stored locally in `flutter_secure_storage` only; no server-side retention.
**Risk:** Logs lost on app uninstall; compliance audits cannot trace user activity.
**Action Items:**
- [ ] Create Supabase RLS-protected table: `audit_logs` (user_id, timestamp, method, path, status)
- [ ] Add background job to flush logs to server on sign-out
- [ ] Implement retention policy: keep server logs for 90 days (compliance requirement)
- [ ] Create admin dashboard to query audit logs (for security investigations)
- [ ] Document GDPR data deletion: remove audit logs when user deletes account

**Supabase Table:**
```sql
CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  method TEXT NOT NULL,
  path TEXT NOT NULL,
  status_code INTEGER,
  latency_ms INTEGER,
  offline BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own logs" ON audit_logs
  FOR SELECT USING (auth.uid() = user_id);
```

---

### 6. Password Strength Enforcement
**Current State:** Email/password auth available, but no documented strength requirements.
**Risk:** Weak passwords enable account takeover; fails regulatory compliance (NIST, PCI-DSS).
**Action Items:**
- [ ] Define password policy: minimum 12 chars, no character-class restrictions, entropy check
- [ ] Integrate haveibeenpwned.com API to block compromised passwords
- [ ] Add `password_strength` indicator to sign-up screen
- [ ] Enforce policy server-side in Supabase auth extension (SQL trigger)
- [ ] Document policy in app help/settings

**Client-Side Validation:**
```dart
class PasswordValidator {
  static const minLength = 12;

  static ValidationResult validate(String password) {
    if (password.length < minLength) {
      return ValidationResult(valid: false, message: 'Min $minLength characters');
    }
    // Check haveibeenpwned
    final isPwned = _checkPwnedPasswords(password);
    if (isPwned) {
      return ValidationResult(valid: false, message: 'Password in breach database');
    }
    return ValidationResult(valid: true);
  }

  static Future<bool> _checkPwnedPasswords(String password) async {
    // Call https://api.pwnedpasswords.com/range/{prefix}
  }
}
```

---

### 7. Biometric Re-Auth for Sensitive Operations
**Current State:** Biometric auth is sticky; no re-prompt for sensitive actions.
**Risk:** If phone is unlocked and stolen, attacker can delete trips or change settings.
**Action Items:**
- [ ] Define sensitive operations: delete trip, change password, remove member, change payment method
- [ ] Implement `SensitiveActionWrapper` that re-prompts for biometric before executing
- [ ] Add 15-minute session timeout: re-auth required even if app stays open
- [ ] Store last biometric timestamp in secure storage; check against `DateTime.now()`
- [ ] Test with biometric spoofing (weak auth should not proceed)

**Implementation:**
```dart
class SensitiveActionWrapper {
  static Future<bool> requireBiometric(BuildContext context, String reason) async {
    final lastAuth = await _getLastBiometricAuth();
    final now = DateTime.now();
    
    if (lastAuth == null || now.difference(lastAuth).inMinutes > 15) {
      final authenticated = await BiometricAuthService.instance.authenticate(
        reason: reason,
      );
      if (authenticated) {
        await _recordBiometricAuth();
        return true;
      }
      return false;
    }
    return true;
  }
}
```

---

### 8. Cryptographic Entropy Verification
**Current State:** RSA key generation seeds Fortuna with `Random.secure()` output.
**Risk:** If `Random.secure()` is weak on a platform, key entropy is compromised.
**Action Items:**
- [ ] Document `Random.secure()` sources for each platform:
  - [ ] Android: verify uses `SecureRandom` (Java)
  - [ ] iOS: verify uses `SecRandomCopyBytes`
  - [ ] Linux: verify uses `/dev/urandom`
- [ ] Add runtime entropy test (optional): validate generated keys have high entropy
- [ ] Consider explicit platform channels for entropy if `Random.secure()` is insufficient
- [ ] Add unit test: generate 100 RSA keypairs, verify each is unique (no collision)

**Test Example:**
```dart
test('RSA key generation has high entropy', () async {
  final service = ThreeLayerEncryptionService.instance;
  await service.init();
  
  final keys = <String>[];
  for (int i = 0; i < 100; i++) {
    await service._getOrGenerateRsaKeys();
    keys.add(service._cachedPublicKey!.modulus.toString());
  }
  
  final unique = keys.toSet();
  expect(unique.length, 100, reason: 'All RSA keys should be unique');
});
```

---

### 9. Audit AES-256-GCM Implementation
**Current State:** Uses `encrypt` package; no verification of constant-time tag comparison.
**Risk:** Timing side-channel could leak plaintext information via failed MAC.
**Action Items:**
- [ ] Review `encrypt` package source: verify GCM tag uses constant-time comparison
- [ ] Check if `pointycastle` has any known GCM vulnerabilities
- [ ] Run `flutter pub outdated` and upgrade to latest stable versions
- [ ] Add integration test: encrypt/decrypt with tampered ciphertext (should fail)
- [ ] Monitor package releases for security patches

**Integration Test:**
```dart
test('GCM detects tampering', () async {
  final service = ThreeLayerEncryptionService.instance;
  await service.init();
  
  final plaintext = 'sensitive data';
  final encrypted = await service.encryptData(plaintext);
  
  // Tamper with the ciphertext
  final tampered = encrypted.replaceFirst('A', 'B');
  
  // Decryption should fail or return wrong data
  final decrypted = await service.decryptData(tampered);
  expect(decrypted, isNot(plaintext));
});
```

---

### 10. Token Expiry Pre-Check
**Current State:** `recoverSession()` handles expiry server-side; no client-side check.
**Risk:** Unnecessary network calls if token is known to be expired; potential UX delay.
**Action Items:**
- [ ] Add local expiry timestamp check in `SecureSessionRepository.restoreSession()`
- [ ] If token expiry is < 1 min in the future, skip network call and clear session
- [ ] Log when tokens are rejected due to expiry
- [ ] Add unit test: verify expired tokens are rejected locally

**Implementation:**
```dart
Future<User?> restoreSession() async {
  // ... read tokens ...
  
  final expiryEpoch = await _storage.read(key: _kExpiryEpoch);
  if (expiryEpoch != null) {
    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryEpoch) * 1000);
    if (DateTime.now().isAfter(expiry)) {
      debugPrint('[SecureSessionRepository] Token expired locally, clearing.');
      await clearSession();
      return null;
    }
  }
  
  // ... continue with recoverSession() ...
}
```

---

### 11. Data Backup Exclusion
**Current State:** `flutter_secure_storage` storage; backup behavior not documented.
**Risk:** Device backups may include secure storage; restored on new device, tokens are stale.
**Action Items:**
- [ ] On Android: verify `FlutterSecureStorage` excludes itself from backups (check AndroidManifest.xml)
- [ ] On iOS: set `NSFileProtectionKey` to `NSFileProtectionComplete` for secure storage
- [ ] Document in app help: "Biometric auth will not work after restoring from backup"
- [ ] Add onboarding warning: "Sign in again after device restore"
- [ ] Test: uninstall app, restore from backup, verify biometric is cleared

**Android (AndroidManifest.xml):**
```xml
<application
  android:allowBackup="false"
  android:supportsRtl="true">
  <!-- or use selective exclusion for flutter_secure_storage -->
</application>
```

---

### 12. OAuth Scope Audit
**Current State:** Google Sign-In requests `['email', 'profile', 'openid']`.
**Risk:** Unused scopes increase privacy risk; unnecessary data access.
**Action Items:**
- [ ] Verify which scopes are actually used: check `GoogleSignInAccount` usage
- [ ] Remove `profile` if only email is needed
- [ ] Remove `openid` if not needed for ID token
- [ ] Document why each scope is required
- [ ] Test: sign in and verify no unnecessary user data is fetched

**Audit:**
```dart
// Search codebase for GoogleSignInAccount usage:
// - googleAccount.email ✓ (used)
// - googleAccount.displayName ? (check if used)
// - googleAccount.photoUrl ? (check if used)

// If not used, reduce scopes to: ['email']
```

---

## 🟡 Low Priority (Nice-to-Have Improvements)

### 13. Automated Security Testing
**Current State:** No security-focused tests mentioned.
**Action Items:**
- [ ] Add `integration_test/` suite for auth flows (login, logout, biometric)
- [ ] Test RLS enforcement: verify cross-user data access is blocked
- [ ] Test audit logging: verify all sensitive operations are logged
- [ ] Run tests in CI/CD on every PR

### 14. Security Documentation
**Current State:** Good inline comments; no external security guide.
**Action Items:**
- [ ] Create `docs/SECURITY.md` with architecture overview
- [ ] Document threat model: which assets are protected, from which actors
- [ ] Include incident response plan (what to do if keys are leaked)
- [ ] Add security FAQ for users (how are passwords stored, etc.)

### 15. Rate Limiting
**Current State:** Auth notifier has 2s throttle; no API-level rate limiting.
**Action Items:**
- [ ] Verify Supabase rate limits are enabled (check settings dashboard)
- [ ] Add client-side rate limiting for non-auth API calls
- [ ] Document rate limit behavior (what happens when limit is hit)

---

## Implementation Roadmap

### Phase 1 (Week 1-2): Critical Security
1. HTTPS Certificate Pinning
2. Supabase RLS Audit
3. Dependency Vulnerability Scanning
4. Sensitive Data Logging Redaction

### Phase 2 (Week 3-4): Important Improvements
5. Server-Side Audit Log Ingestion
6. Password Strength Enforcement
7. Biometric Re-Auth for Sensitive Operations

### Phase 3 (Ongoing): Maintenance & Testing
8-15. Verification, documentation, automated testing

---

## Compliance Considerations

- **GDPR:** Server-side audit logs required for data subject access requests
- **PCI-DSS:** Password strength, no storage of payment card data (use Supabase Secure)
- **SOC 2:** RLS enforcement, audit logging, incident response procedures
- **HIPAA:** If handling health data, add audit retention for 6 years

---

## Questions for Your Team

1. Do you store payment card data? (If yes, must comply with PCI-DSS)
2. Which regions do users come from? (GDPR applies in EU)
3. Is there a threat model/security requirements document?
4. Who is responsible for security patches in production?
5. What is your incident response time target (e.g., 24h for critical vulnerabilities)?

---

## References

- [OWASP Mobile Security Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Flutter Security Best Practices](https://flutter.dev/security)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [NIST Digital Identity Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)
- [Have I Been Pwned API](https://haveibeenpwned.com/API/v3)
