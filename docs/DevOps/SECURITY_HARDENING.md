# Tara Travel - AI, Bot & Hacking Prevention Guide

## Overview
This document outlines defensive strategies against:
- **AI/LLM Abuse:** Automated scraping, account farming, data extraction
- **Bot Attacks:** Credential stuffing, brute force, spam, scraping
- **Hacking:** SQL injection, XSS, CSRF, privilege escalation, supply chain attacks
- **Infrastructure Abuse:** DDoS, resource exhaustion, API hammering
- **Social Engineering:** Phishing, account takeover, insider threats

---

## 🔴 CRITICAL - Implement Immediately

### 1. **Rate Limiting & Brute Force Protection**

**Current State:** 2s client-side throttle only; no server-side protection.
**Risk:** Attackers bypass client-side limits; credential stuffing attacks succeed.

**Implementation:**

#### A. Supabase RLS + PostgreSQL Rate Limiting
```sql
-- Track login attempts per IP/email
CREATE TABLE auth_attempts (
  id BIGSERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  ip_address INET NOT NULL,
  success BOOLEAN DEFAULT FALSE,
  attempted_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_auth_attempts_email_time 
  ON auth_attempts(email, attempted_at DESC);
CREATE INDEX idx_auth_attempts_ip_time 
  ON auth_attempts(ip_address, attempted_at DESC);

-- RLS: users can only see their own attempts
ALTER TABLE auth_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own attempts" ON auth_attempts
  FOR SELECT USING (auth.uid()::TEXT = email);

-- Function: check if email/IP is rate limited (5 failed attempts in 15 min = locked)
CREATE OR REPLACE FUNCTION check_login_rate_limit(p_email TEXT, p_ip INET)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth_attempts
    WHERE email = p_email
    AND ip_address = p_ip
    AND attempted_at > NOW() - INTERVAL '15 minutes'
    AND success = FALSE
    HAVING COUNT(*) >= 5
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log attempt (success or failure)
CREATE OR REPLACE FUNCTION log_auth_attempt(
  p_email TEXT,
  p_ip INET,
  p_success BOOLEAN
) RETURNS VOID AS $$
BEGIN
  INSERT INTO auth_attempts (email, ip_address, success)
  VALUES (p_email, p_ip, p_success);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup: delete attempts older than 24 hours
CREATE OR REPLACE FUNCTION cleanup_old_auth_attempts()
RETURNS VOID AS $$
BEGIN
  DELETE FROM auth_attempts WHERE attempted_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule cleanup daily
SELECT cron.schedule('cleanup-auth-attempts', '0 0 * * *', 'SELECT cleanup_old_auth_attempts()');
```

#### B. Flutter Client Implementation
```dart
// lib/core/repositories/auth_repository.dart
Future<User?> signInWithEmailPassword({
  required String email,
  required String password,
}) async {
  try {
    // 1. Check if email is rate-limited
    final rateLimitCheck = await _supabase.rpc(
      'check_login_rate_limit',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_ip': await _getClientIp(), // see implementation below
      },
    );

    if (rateLimitCheck == true) {
      throw AuthFailure(
        userMessage: 'Too many failed attempts. Please try again in 15 minutes.',
        code: 'rate_limited',
      );
    }

    // 2. Attempt login
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // 3. Log successful attempt
    await _supabase.rpc(
      'log_auth_attempt',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_ip': await _getClientIp(),
        'p_success': true,
      },
    );

    return response.user;
  } on AuthException catch (e) {
    // Log failed attempt
    await _supabase.rpc(
      'log_auth_attempt',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_ip': await _getClientIp(),
        'p_success': false,
      },
    ).catchError((_) => null); // non-fatal if logging fails

    throw AuthFailureMapper.fromAuthException(e);
  }
}

Future<String> _getClientIp() async {
  try {
    final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['ip'] as String;
    }
  } catch (_) {}
  return '0.0.0.0'; // fallback
}
```

#### C. GitHub Actions Alert
```yaml
# .github/workflows/security-alerts.yml
name: Security Alerts
on:
  schedule:
    - cron: '*/5 * * * *'  # Every 5 minutes

jobs:
  check-auth-abuse:
    runs-on: ubuntu-latest
    steps:
      - name: Check for Auth Rate Limit Abuse
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
        run: |
          # Query for IPs with >50 failed attempts in last hour
          curl -s "${SUPABASE_URL}/rest/v1/auth_attempts?select=ip_address,count:id&success=eq.false&attempted_at=gt.$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)&group_by=ip_address&having=count(id)%3E50" \
            -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" > /tmp/abusive_ips.json
          
          COUNT=$(jq 'length' /tmp/abusive_ips.json)
          if [ "$COUNT" -gt 0 ]; then
            echo "🚨 Detected $COUNT IPs with excessive login attempts"
            # Send alert to Slack/Discord
            curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
              -H 'Content-Type: application/json' \
              -d @/tmp/abusive_ips.json
          fi
```

---

### 2. **AI/Bot Detection & CAPTCHAs**

**Current State:** No bot detection; user accounts can be created by automated scripts.
**Risk:** Account farming, fake user inflation, spam trips, data pollution.

**Implementation:**

#### A. Client-Side Bot Detection
```dart
// lib/core/security/bot_detection_service.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class BotDetectionService {
  static final BotDetectionService _instance = BotDetectionService._();
  static BotDetectionService get instance => _instance;

  BotDetectionService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Detects if the client is likely a bot by checking:
  /// - Device info consistency (real devices have unique values)
  /// - Screen dimensions (bots often report fake/default values)
  /// - Sensor availability (accelerometer, gyroscope)
  /// - User agent (browser, mobile OS version)
  /// - Timing patterns (humans take >500ms between actions)
  Future<BotDetectionScore> analyzeClient() async {
    final score = BotDetectionScore();

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Check 1: Device name entropy
      if (androidInfo.device == 'generic' || androidInfo.device == 'unknown') {
        score.suspicionLevel += 20; // likely emulator/bot
      }

      // Check 2: Build fingerprint consistency
      if (androidInfo.fingerprint.contains('generic')) {
        score.suspicionLevel += 15;
      }

      // Check 3: Hardware presence
      if (!await _hasAccelerometer()) {
        score.suspicionLevel += 10; // might be server-based
      }

      // Check 4: Battery status (bots may not report battery)
      if (!await _hasBattery()) {
        score.suspicionLevel += 10;
      }
    } catch (e) {
      score.suspicionLevel += 5; // unable to verify = slight suspicion
    }

    score.isBot = score.suspicionLevel > 50;
    return score;
  }

  Future<bool> _hasAccelerometer() async {
    try {
      // Attempt to access accelerometer
      // If this throws, device likely doesn't have one
      return true; // simplified; implement actual sensor check
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasBattery() async {
    try {
      // Check battery status
      return true; // simplified
    } catch (_) {
      return false;
    }
  }
}

class BotDetectionScore {
  int suspicionLevel = 0; // 0-100
  bool isBot = false;
  DateTime createdAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'suspicion_level': suspicionLevel,
    'is_bot': isBot,
    'created_at': createdAt.toIso8601String(),
  };
}
```

#### B. reCAPTCHA Integration (Server-Side)
```dart
// lib/core/repositories/auth_repository.dart
import 'package:http/http.dart' as http;

Future<User?> signUpWithEmailPassword({
  required String email,
  required String password,
  required String reCaptchaToken,
}) async {
  // 1. Verify reCAPTCHA token on server (Supabase Edge Function)
  final reCaptchaValid = await _supabase.functions.invoke(
    'verify-recaptcha',
    body: {'token': reCaptchaToken},
  );

  if (reCaptchaValid['success'] != true) {
    throw AuthFailure(
      userMessage: 'Bot detection failed. Please try again.',
      code: 'captcha_failed',
    );
  }

  // 2. Check bot detection score
  final botScore = await BotDetectionService.instance.analyzeClient();
  if (botScore.isBot) {
    throw AuthFailure(
      userMessage: 'Suspicious activity detected. Please verify your device.',
      code: 'suspicious_device',
    );
  }

  // 3. Proceed with signup
  return await _supabase.auth.signUpWithPassword(
    email: email,
    password: password,
  );
}
```

#### C. Supabase Edge Function (verify-recaptcha)
```typescript
// supabase/functions/verify-recaptcha/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const RECAPTCHA_SECRET = Deno.env.get("RECAPTCHA_SECRET_KEY");

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const { token } = await req.json();

  const response = await fetch("https://www.google.com/recaptcha/api/siteverify", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `secret=${RECAPTCHA_SECRET}&response=${token}`,
  });

  const data = await response.json();

  return new Response(
    JSON.stringify({
      success: data.success && data.score > 0.5, // score > 0.5 = likely human
      score: data.score,
    }),
    { headers: { "Content-Type": "application/json" } }
  );
});
```

#### D. Sign-Up UI with CAPTCHA
```dart
// lib/features/auth/presentation/sign_up_screen.dart
import 'package:google_recaptcha_v3/google_recaptcha_v3.dart';

class SignUpScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(label: 'Email'),
        TextField(label: 'Password', obscureText: true),
        ElevatedButton(
          onPressed: () async {
            // Generate reCAPTCHA token
            final recaptchaToken = await GoogleRecaptchaV3.instance.executeAction(
              action: 'signup',
            );

            // Sign up with token
            await ref.read(authNotifierProvider.notifier).signUpWithEmailPassword(
              email: email,
              password: password,
              reCaptchaToken: recaptchaToken,
            );
          },
          child: Text('Sign Up'),
        ),
      ],
    );
  }
}
```

---

### 3. **SQL Injection & Query Injection Prevention**

**Current State:** Supabase client uses parameterized queries (safe by default).
**Risk:** If custom RPC functions or raw SQL is used, injection is possible.

**Implementation:**

#### A. Supabase Safe Query Patterns
```dart
// ✅ SAFE: Parameterized queries
final users = await supabase
    .from('users')
    .select()
    .eq('email', email) // email is parameter, not interpolated
    .single();

// ❌ UNSAFE: String interpolation (DO NOT USE)
final users = await supabase.rpc('raw_query', params: {
  'sql': "SELECT * FROM users WHERE email = '$email'" // INJECTION RISK!
});
```

#### B. Supabase RPC Functions (Always Use Parameters)
```sql
-- ✅ SAFE: Uses parameters
CREATE OR REPLACE FUNCTION get_user_trips(p_user_id UUID)
RETURNS TABLE(trip_id UUID, destination TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT id, destination FROM trips
  WHERE owner_id = p_user_id; -- p_user_id is parameter
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ❌ UNSAFE: String concatenation (DO NOT USE)
CREATE OR REPLACE FUNCTION unsafe_query(p_sql TEXT)
RETURNS SETOF trips AS $$
BEGIN
  RETURN QUERY EXECUTE p_sql; -- INJECTION RISK!
END;
$$ LANGUAGE plpgsql;
```

#### C. Input Validation Filters
```dart
// lib/core/utils/input_sanitizer.dart
class InputSanitizer {
  static const _emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const _uuidRegex = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
  static const _tripNameRegex = r'^[a-zA-Z0-9\s\-.,\']{1,100}$';

  static String sanitizeEmail(String email) {
    email = email.trim().toLowerCase();
    if (!RegExp(_emailRegex).hasMatch(email)) {
      throw FormatException('Invalid email format');
    }
    return email;
  }

  static String sanitizeTripName(String name) {
    name = name.trim();
    if (!RegExp(_tripNameRegex).hasMatch(name)) {
      throw FormatException('Trip name contains invalid characters');
    }
    return name;
  }

  static String sanitizeUuid(String uuid) {
    if (!RegExp(_uuidRegex).hasMatch(uuid)) {
      throw FormatException('Invalid UUID format');
    }
    return uuid;
  }

  /// Remove all special characters except allowed ones
  static String stripSpecialChars(String input, {String allow = ''}) {
    return input.replaceAll(RegExp('[$allow]', multiLine: true), '');
  }
}
```

---

### 4. **Authentication Token Security**

**Current State:** Tokens stored in secure storage; refresh tokens used.
**Risk:** Token theft via malware, network sniffing, or compromised device.

**Implementation:**

#### A. Token Rotation Strategy
```dart
// lib/core/auth/data/secure_session_repository.dart

/// Automatically rotate tokens if they're older than 24 hours
Future<void> ensureTokenFreshness() async {
  final storedTs = await _storage.read(key: _kTokenTimestamp);
  if (storedTs != null) {
    final storedTime = DateTime.parse(storedTs);
    final age = DateTime.now().difference(storedTime);
    
    if (age.inHours > 24) {
      // Force refresh
      final refreshToken = await _storage.read(key: _kRefreshToken);
      if (refreshToken != null) {
        final newSession = await Supabase.instance.client.auth.recoverSession(
          refreshToken,
        );
        await persistSession(newSession); // Updates timestamp
      }
    }
  }
}

const _kTokenTimestamp = 'supa_token_timestamp';
```

#### B. Token Binding to Device
```dart
// lib/core/security/token_binding_service.dart
import 'package:device_info_plus/device_info_plus.dart';

class TokenBindingService {
  static final TokenBindingService _instance = TokenBindingService._();
  static TokenBindingService get instance => _instance;

  TokenBindingService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Generate a device fingerprint
  Future<String> getDeviceFingerprint() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final fingerprint = [
        androidInfo.id, // Device ID
        androidInfo.serialNumber, // Hardware serial
        androidInfo.device, // Device name
        androidInfo.manufacturer,
      ].join('|');
      
      return _hashFingerprint(fingerprint);
    } catch (e) {
      return 'unknown';
    }
  }

  /// Verify token is being used on the same device
  Future<bool> verifyTokenBinding(String? storedFingerprint) async {
    final currentFingerprint = await getDeviceFingerprint();
    return storedFingerprint == currentFingerprint;
  }

  /// Store device fingerprint with token
  Future<void> bindTokenToDevice() async {
    final fingerprint = await getDeviceFingerprint();
    await _storage.write(key: 'device_fingerprint', value: fingerprint);
  }

  String _hashFingerprint(String fingerprint) {
    return sha256.convert(utf8.encode(fingerprint)).toString();
  }
}
```

---

### 5. **Cross-Site Request Forgery (CSRF) Protection**

**Current State:** Supabase handles CSRF via secure cookies; app uses tokens.
**Risk:** If web interface is added, CSRF attacks are possible.

**Implementation:**

#### A. CSRF Token Generation
```dart
// lib/core/security/csrf_service.dart
class CsrfService {
  static final CsrfService _instance = CsrfService._();
  static CsrfService get instance => _instance;

  CsrfService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Generate a unique CSRF token for the session
  Future<String> generateToken() async {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final token = base64Url.encode(values).replaceAll('=', '');
    
    await _storage.write(key: 'csrf_token', value: token);
    return token;
  }

  /// Verify CSRF token matches stored token
  Future<bool> verifyToken(String providedToken) async {
    final storedToken = await _storage.read(key: 'csrf_token');
    return storedToken == providedToken;
  }
}
```

---

### 6. **API Rate Limiting (Global)**

**Current State:** Per-endpoint throttling exists; no global API limits.
**Risk:** API hammering, DDoS, resource exhaustion.

**Implementation:**

#### A. Supabase Global Rate Limits
```sql
-- Track API calls per user
CREATE TABLE api_calls (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INTEGER,
  called_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_api_calls_user_time ON api_calls(user_id, called_at DESC);

-- Function: check if user has exceeded rate limit
CREATE OR REPLACE FUNCTION check_api_rate_limit(p_user_id UUID, p_limit INT DEFAULT 100)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT COUNT(*) FROM api_calls
    WHERE user_id = p_user_id
    AND called_at > NOW() - INTERVAL '1 hour'
  ) < p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### B. Dio Interceptor for Client-Side Rate Limiting
```dart
// lib/core/network/rate_limit_interceptor.dart
class RateLimitInterceptor extends Interceptor {
  final Map<String, List<DateTime>> _endpointCalls = {};
  final int maxCallsPerMinute = 60;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final endpoint = options.path;
    final now = DateTime.now();
    
    if (!_endpointCalls.containsKey(endpoint)) {
      _endpointCalls[endpoint] = [];
    }

    // Remove calls older than 1 minute
    _endpointCalls[endpoint]!
        .removeWhere((call) => now.difference(call).inSeconds > 60);

    if (_endpointCalls[endpoint]!.length >= maxCallsPerMinute) {
      handler.reject(DioException(
        requestOptions: options,
        error: 'Rate limit exceeded. Max $maxCallsPerMinute calls per minute.',
      ));
      return;
    }

    _endpointCalls[endpoint]!.add(now);
    handler.next(options);
  }
}
```

---

## 🟠 HIGH PRIORITY - Implement Before Launch

### 7. **Prevent Account Enumeration**

**Risk:** Attacker can determine if email is registered by checking auth responses.
**Implementation:**

```dart
// ✅ DO: Same response regardless of email existence
Future<void> requestPasswordReset(String email) async {
  try {
    await _supabase.auth.resetPasswordForEmail(email);
  } catch (e) {
    // Don't reveal if email exists or doesn't
    debugPrint('Password reset requested (may or may not succeed)');
  }
  
  // Always show: "Check your email for password reset link"
  // Even if email doesn't exist
}

// ❌ DON'T: Different responses for found/not found
if (userExists(email)) {
  await sendPasswordReset(email);
  return 'Password reset sent';
} else {
  return 'Email not found'; // ← Reveals email doesn't exist!
}
```

---

### 8. **Prevent Data Scraping & Enumeration**

**Risk:** Attackers scrape trip data, user profiles, or export entire database.
**Implementation:**

#### A. Rate Limit List Endpoints
```sql
-- Limit SELECT queries per user
CREATE OR REPLACE FUNCTION check_list_rate_limit(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT COUNT(*) FROM api_calls
    WHERE user_id = p_user_id
    AND method = 'GET'
    AND called_at > NOW() - INTERVAL '1 minute'
  ) < 30; -- max 30 GET requests per minute
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### B. Pagination Enforcement
```dart
// lib/core/repositories/trip_repository.dart
Future<List<Trip>> getAllTrips({
  required int page,
  int pageSize = 20, // max 20 per page
}) async {
  if (pageSize > 20) pageSize = 20; // enforce max
  if (page < 1) page = 1;

  final offset = (page - 1) * pageSize;

  return await _supabase
      .from('trips')
      .select()
      .eq('owner_id', _supabase.auth.currentUser!.id)
      .range(offset, offset + pageSize - 1); // Use range, not offset
}
```

#### C. Disable Bulk Exports
```sql
-- RLS policy: prevent downloading entire database
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
CREATE POLICY "No bulk export" ON trips
  FOR SELECT USING (
    auth.uid() = owner_id
    AND (
      -- Limit to authenticated users only
      auth.role() = 'authenticated'
    )
  );

-- Prevent CSV/JSON exports of sensitive tables
REVOKE CONNECT ON DATABASE postgres FROM anon;
```

---

### 9. **Prevent Privilege Escalation**

**Risk:** Users modify their own roles/permissions, bypass RLS.
**Implementation:**

#### A. Immutable Role Assignment
```sql
-- Roles are stored and NEVER modified by the user
CREATE TABLE user_roles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  role TEXT NOT NULL DEFAULT 'member', -- member | admin | moderator
  created_at TIMESTAMP DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id), -- audit trail
  updated_at TIMESTAMP
);

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own role" ON user_roles
  FOR SELECT USING (auth.uid() = user_id);

-- CRITICAL: Only allow admins to update roles
CREATE POLICY "Only admins can update roles" ON user_roles
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM user_roles WHERE role = 'admin'
    )
  );

-- Users CANNOT insert/delete/update their own role
CREATE POLICY "Users cannot modify own role" ON user_roles
  FOR ALL USING (auth.uid() != user_id);
```

#### B. Audit Trail for Privilege Changes
```sql
CREATE TABLE role_change_audit (
  id BIGSERIAL PRIMARY KEY,
  target_user_id UUID NOT NULL,
  old_role TEXT,
  new_role TEXT,
  changed_by UUID NOT NULL REFERENCES auth.users(id),
  changed_at TIMESTAMP DEFAULT NOW(),
  reason TEXT
);

-- Log all role changes
CREATE OR REPLACE FUNCTION audit_role_change()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO role_change_audit (target_user_id, old_role, new_role, changed_by)
  VALUES (NEW.user_id, OLD.role, NEW.role, auth.uid());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER role_change_trigger
AFTER UPDATE ON user_roles
FOR EACH ROW
EXECUTE FUNCTION audit_role_change();
```

---

### 10. **Prevent Account Takeover (ATO)**

**Risk:** Attackers gain access via phishing, malware, or leaked passwords.
**Implementation:**

#### A. Login Anomaly Detection
```dart
// lib/core/security/login_anomaly_service.dart
class LoginAnomalyService {
  static final LoginAnomalyService _instance = LoginAnomalyService._();
  static LoginAnomalyService get instance => _instance;

  LoginAnomalyService._();

  /// Detect suspicious login: new device, new location, unusual time
  Future<bool> isLoginAnomalous({
    required String userId,
    required String ipAddress,
    required String deviceId,
  }) async {
    // Get last 5 successful logins
    final previousLogins = await Supabase.instance.client
        .from('login_history')
        .select('ip_address, device_id, logged_in_at')
        .eq('user_id', userId)
        .eq('success', true)
        .order('logged_in_at', ascending: false)
        .limit(5);

    if (previousLogins.isEmpty) {
      return false; // First login, not anomalous
    }

    // Check if IP or device ID matches any recent login
    final isKnownIp = previousLogins.any((l) => l['ip_address'] == ipAddress);
    final isKnownDevice = previousLogins.any((l) => l['device_id'] == deviceId);

    // Anomalous if BOTH IP and device are unknown
    return !(isKnownIp && isKnownDevice);
  }

  /// If anomalous, require additional verification
  Future<bool> requireAnomalyVerification(String userId) async {
    // Send verification email/SMS
    // or require biometric re-authentication
    return true;
  }
}
```

#### B. Session Invalidation on Suspicious Activity
```sql
-- Invalidate all sessions if anomalous login detected
CREATE OR REPLACE FUNCTION invalidate_user_sessions(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE auth.sessions
  SET revoked = TRUE
  WHERE user_id = p_user_id
  AND aud = 'authenticated';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### C. Login History Table
```sql
CREATE TABLE login_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  ip_address INET NOT NULL,
  device_id TEXT NOT NULL,
  user_agent TEXT,
  success BOOLEAN DEFAULT TRUE,
  logged_in_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_login_history_user_time 
  ON login_history(user_id, logged_in_at DESC);
```

---

### 11. **Protect Against XSS (Cross-Site Scripting)**

**Risk:** If web app is added, XSS can steal tokens or modify DOM.
**Implementation:**

#### A. Content Security Policy (CSP)
```dart
// lib/main.dart - for web build
void main() {
  // Set CSP headers (web only)
  if (kIsWeb) {
    _setWebSecurityHeaders();
  }
  runApp(const MyApp());
}

void _setWebSecurityHeaders() {
  // This requires web server configuration (e.g., Firebase Hosting)
  // Set in firebase.json or web/index.html:
  // <meta http-equiv="Content-Security-Policy" content="
  //   default-src 'self';
  //   script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;
  //   style-src 'self' 'unsafe-inline';
  //   img-src 'self' https: data:;
  //   font-src 'self' https:;
  //   connect-src 'self' https://supabase.co https://api.ipify.org;
  //   frame-ancestors 'none';
  //   base-uri 'self';
  //   form-action 'self';
  // ">
}
```

#### B. HTML Escaping for User Input
```dart
// lib/core/utils/html_escape.dart
import 'dart:html' as html;

String escapeHtml(String input) {
  final element = html.DivElement();
  element.text = input;
  return element.innerHtml!;
}

// Usage in chat/messages:
final escapedMessage = escapeHtml(userMessage);
await _supabase
    .from('chat_messages')
    .insert({'content': escapedMessage}); // Safe
```

---

### 12. **Supply Chain Security**

**Risk:** Compromised dependencies (pub.dev packages) could introduce malware.
**Implementation:**

#### A. Dependency Audit & Scanning
```bash
# Audit all dependencies
flutter pub outdated
flutter pub audit

# Lock to specific versions (prevent supply chain attacks via auto-updates)
# In pubspec.lock, use exact versions
```

#### B. GitHub Actions Dependency Scanning
```yaml
# .github/workflows/dependency-check.yml
name: Dependency Scanning
on: [pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter pub audit --exit-on-error
      - run: |
          # Use OWASP Dependency-Check
          wget https://github.com/jeremylong/DependencyCheck_Action/releases/download/v7.0.0/dependency-check.jar
          java -jar dependency-check.jar --project "Tara Travel" --scan .
```

#### C. Vendoring Critical Dependencies (Optional)
```bash
# For ultra-critical packages, consider vendoring (copying source into repo)
# This prevents dependency compromise, but requires manual updates
mkdir -p vendor
cp -r ~/.pub-cache/hosted/pub.dev/critical_package-1.0.0 vendor/
```

---

## 🟡 MEDIUM PRIORITY - Ongoing Monitoring

### 13. **Intrusion Detection & Logging**

**Implementation:**

```dart
// lib/core/middleware/intrusion_detector.dart
class IntrusionDetector {
  static final IntrusionDetector _instance = IntrusionDetector._();
  static IntrusionDetector get instance => _instance;

  /// Log all database modifications for audit trail
  Future<void> logDatabaseWrite({
    required String table,
    required String operation, // INSERT, UPDATE, DELETE
    required String userId,
    required Map<String, dynamic> newData,
    Map<String, dynamic>? oldData,
  }) async {
    await Supabase.instance.client.from('database_audit_log').insert({
      'table_name': table,
      'operation': operation,
      'user_id': userId,
      'new_data': newData,
      'old_data': oldData,
      'ip_address': await _getClientIp(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Detect suspicious patterns
  Future<List<String>> detectSuspiciousActivity(String userId) async {
    final warnings = <String>[];

    // Check 1: Bulk delete attempts
    final recentDeletes = await Supabase.instance.client
        .from('database_audit_log')
        .select()
        .eq('user_id', userId)
        .eq('operation', 'DELETE')
        .gt('timestamp', DateTime.now().subtract(Duration(minutes: 5)).toIso8601String())
        .limit(100);

    if ((recentDeletes as List).length > 10) {
      warnings.add('Bulk delete detected');
    }

    // Check 2: Rapid API calls
    final recentCalls = await Supabase.instance.client
        .from('api_calls')
        .select()
        .eq('user_id', userId)
        .gt('called_at', DateTime.now().subtract(Duration(minutes: 1)).toIso8601String());

    if ((recentCalls as List).length > 100) {
      warnings.add('High API call rate detected');
    }

    // Check 3: Access to other users' data
    // (Detected via RLS violations in logs)

    return warnings;
  }

  Future<String> _getClientIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['ip'] as String;
    } catch (_) {
      return '0.0.0.0';
    }
  }
}
```

---

### 14. **Implement Web Application Firewall (WAF)**

**Risk:** Attacks targeting API endpoints or web interface.
**Implementation:**

#### A. Cloudflare WAF (Recommended)
```
1. Enable Cloudflare on domain
2. Settings → Security → WAF Rules
3. Enable OWASP ModSecurity Core Rules
4. Create custom rules for:
   - Rate limiting: 100 requests per minute per IP
   - SQL Injection detection
   - XSS detection
   - Bot Management (Cloudflare Bot Score)
5. Set to "Challenge" for suspicious traffic
```

#### B. Supabase Edge Functions with Rate Limiting
```typescript
// supabase/functions/api-guard/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

serve(async (req) => {
  const clientIp = req.headers.get("cf-connecting-ip") || "unknown";
  const now = Date.now();

  // Rate limit: 100 requests per minute
  const key = `${clientIp}:${Math.floor(now / 60000)}`;
  const limit = rateLimitStore.get(key) || { count: 0, resetTime: now + 60000 };

  if (limit.count >= 100) {
    return new Response("Too many requests", { status: 429 });
  }

  limit.count++;
  rateLimitStore.set(key, limit);

  // Clean up old entries
  if (Math.random() < 0.01) {
    for (const [k, v] of rateLimitStore.entries()) {
      if (v.resetTime < now) rateLimitStore.delete(k);
    }
  }

  return new Response("OK", { status: 200 });
});
```

---

### 15. **Monitoring & Alerting**

**Implementation:**

```yaml
# .github/workflows/security-monitoring.yml
name: Security Monitoring
on:
  schedule:
    - cron: '0 * * * *'  # Every hour

jobs:
  check-threats:
    runs-on: ubuntu-latest
    steps:
      - name: Check for Attack Patterns
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
        run: |
          # Query for suspicious activity
          curl -s "${SUPABASE_URL}/rest/v1/database_audit_log?select=*&operation=in.(DELETE)&timestamp=gt.$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
            -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" | jq '.[] | select(.user_id != null)' > /tmp/deletes.json
          
          if [ -s /tmp/deletes.json ]; then
            echo "🚨 Suspicious delete activity detected"
            # Send to Slack
            curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
              -H 'Content-Type: application/json' \
              -d '{"text": "Suspicious activity detected", "attachments": [{"text": "$(cat /tmp/deletes.json)"}]}'
          fi
```

---

## 🔐 Summary: Defense Layers

| Layer | Attack Type | Defense |
|-------|------------|---------|
| **1. Application** | Bot/AI abuse, XSS, CSRF | reCAPTCHA, CSP, CSRF tokens |
| **2. API** | Rate limiting, DDoS, scraping | Global rate limits, pagination, RLS |
| **3. Database** | SQL injection, privilege escalation | Parameterized queries, immutable roles, RLS |
| **4. Auth** | Credential stuffing, ATO, brute force | Rate limiting, anomaly detection, MFA |
| **5. Infrastructure** | DDoS, breaches | WAF, Cloudflare, intrusion detection |
| **6. Dependencies** | Supply chain attacks | Audit, dependency scanning, vendoring |
| **7. Monitoring** | Undetected attacks | Audit logging, alerts, dashboards |

---

## Implementation Priority (4 Weeks)

### Week 1 (Critical)
- [ ] Rate limiting (auth + API)
- [ ] reCAPTCHA + bot detection
- [ ] Input sanitization
- [ ] SQL injection prevention audit
- [ ] Token security & rotation

### Week 2 (High)
- [ ] Account enumeration prevention
- [ ] Data scraping prevention
- [ ] Privilege escalation prevention
- [ ] Login anomaly detection
- [ ] CSP headers (if web app)

### Week 3 (Medium)
- [ ] Dependency scanning automation
- [ ] Intrusion detection logging
- [ ] WAF configuration (Cloudflare)
- [ ] Monitoring & alerting
- [ ] Incident response runbook

### Week 4+ (Ongoing)
- [ ] Regular penetration testing
- [ ] Dependency updates
- [ ] Attack surface review
- [ ] User security awareness training

---

## Testing Your Defenses

```bash
# 1. Test rate limiting
for i in {1..200}; do curl http://localhost:8080/api/trips; done
# Should get 429 (Too Many Requests) after limit

# 2. Test SQL injection protection
curl "http://localhost:8080/api/trips?id=1'; DROP TABLE trips; --"
# Should NOT execute; should return safe error

# 3. Test XSS prevention
curl -X POST http://localhost:8080/api/trips \
  -d '{"name": "<script>alert(1)</script>"}'
# Should escape/reject script tag

# 4. Test CSRF protection
# Attempt POST without CSRF token
# Should reject with 403

# 5. Test bot detection
# Use headless browser (Selenium, Puppeteer)
# Should detect and challenge with CAPTCHA
```

---

## Resources & References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Flutter Security Best Practices](https://flutter.dev/security)
- [Supabase Row-Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Dart Security Guidelines](https://dart.dev/guides/security)
- [API Security Checklist](https://github.com/shieldfy/API-Security-Checklist)
- [Mobile App Security Checklist](https://cheatsheetseries.owasp.org/cheatsheets/Mobile_App_Security_Verification_Standard_Cheat_Sheet.html)

