# Tara Travel - DevOps & Infrastructure Guide

## Overview
This document covers everything needed to operate Tara Travel in production: CI/CD, monitoring, logging, infrastructure, backups, disaster recovery, and incident response.

---

## 🔴 CRITICAL - Implement Immediately

### 1. **Infrastructure as Code (IaC) & Containerization**

**Current State:** GitHub Actions builds APK/AAB; no production infrastructure defined.
**Risk:** Infrastructure is manual, undocumented, and brittle. Difficult to reproduce or scale.

**Implementation:**

#### A. Docker Containerization (Backend Services)
If you add backend services (API gateway, WebSocket server, scheduled jobs), containerize them:

```dockerfile
# Dockerfile for backend (if needed)
FROM dart:3.3 as builder
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=builder /app/bin/server /server
CMD ["/server"]
```

```yaml
# docker-compose.yml for local development
version: '3.9'
services:
  supabase:
    image: supabase/supabase:latest
    environment:
      SUPABASE_URL: http://localhost:54321
      SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY}
    ports:
      - "54321:54321"
  
  backend:
    build: .
    environment:
      SUPABASE_URL: http://supabase:54321
    depends_on:
      - supabase
    ports:
      - "8080:8080"
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

#### B. Terraform for Supabase Infrastructure
```hcl
# terraform/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

provider "supabase" {
  api_url = var.supabase_api_url
  api_key = var.supabase_api_key
}

# Database backups
resource "supabase_backup" "daily" {
  project_id = var.supabase_project_id
  schedule   = "daily"
  retention  = 30 # 30 days
}

# Storage buckets
resource "supabase_storage_bucket" "app_releases" {
  name      = "app-releases"
  public    = true
  file_size_limit = 52428800 # 50MB
}

# Edge functions
resource "supabase_edge_function" "verify_recaptcha" {
  name   = "verify-recaptcha"
  source = file("${path.module}/../supabase/functions/verify-recaptcha/index.ts")
}
```

```hcl
# terraform/variables.tf
variable "supabase_api_url" {
  type = string
}

variable "supabase_api_key" {
  type      = string
  sensitive = true
}

variable "supabase_project_id" {
  type = string
}
```

#### C. GitHub Actions + IaC Deployment
```yaml
# .github/workflows/infrastructure.yml
name: Infrastructure Deployment
on:
  push:
    paths:
      - 'terraform/**'
      - '.github/workflows/infrastructure.yml'
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Init
        run: terraform init
        env:
          TF_VAR_supabase_api_url: ${{ secrets.SUPABASE_URL }}
          TF_VAR_supabase_api_key: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
          TF_VAR_supabase_project_id: ${{ secrets.SUPABASE_PROJECT_ID }}
      
      - name: Terraform Plan
        run: terraform plan -out=plan
        env:
          TF_VAR_supabase_api_url: ${{ secrets.SUPABASE_URL }}
          TF_VAR_supabase_api_key: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
          TF_VAR_supabase_project_id: ${{ secrets.SUPABASE_PROJECT_ID }}
      
      - name: Terraform Apply
        run: terraform apply -auto-approve plan
        env:
          TF_VAR_supabase_api_url: ${{ secrets.SUPABASE_URL }}
          TF_VAR_supabase_api_key: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
          TF_VAR_supabase_project_id: ${{ secrets.SUPABASE_PROJECT_ID }}
```

---

### 2. **Comprehensive Logging & Centralization**

**Current State:** Logs scattered (crash reports, audit logs local storage).
**Risk:** Can't diagnose production issues; no centralized debugging.

**Implementation:**

#### A. Supabase Logging Table
```sql
-- Create centralized log table
CREATE TABLE system_logs (
  id BIGSERIAL PRIMARY KEY,
  level TEXT NOT NULL, -- 'debug', 'info', 'warning', 'error', 'fatal'
  service TEXT NOT NULL, -- 'app', 'auth', 'api', 'database'
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  message TEXT NOT NULL,
  context JSONB, -- Additional context (request ID, headers, etc.)
  stack_trace TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  ttl TIMESTAMP DEFAULT NOW() + INTERVAL '30 days' -- Auto-delete after 30 days
);

CREATE INDEX idx_system_logs_level_time ON system_logs(level, created_at DESC);
CREATE INDEX idx_system_logs_service_time ON system_logs(service, created_at DESC);
CREATE INDEX idx_system_logs_user_time ON system_logs(user_id, created_at DESC);

-- Enable RLS: only admins can view logs
ALTER TABLE system_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view all logs" ON system_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );
```

#### B. Flutter Logging Service
```dart
// lib/core/services/logging_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

enum LogLevel { debug, info, warning, error, fatal }

class LoggingService {
  static final LoggingService _instance = LoggingService._();
  static LoggingService get instance => _instance;

  LoggingService._();

  final Queue<Log> _buffer = Queue();
  static const int _maxBufferSize = 100;
  Timer? _flushTimer;

  void initialize() {
    // Flush logs every 10 seconds or when buffer is full
    _flushTimer = Timer.periodic(Duration(seconds: 10), (_) => flush());
  }

  void log({
    required LogLevel level,
    required String service,
    required String message,
    String? userId,
    Map<String, dynamic>? context,
    String? stackTrace,
  }) {
    final log = Log(
      level: level.toString().split('.').last,
      service: service,
      userId: userId,
      message: message,
      context: context,
      stackTrace: stackTrace,
      createdAt: DateTime.now(),
    );

    _buffer.add(log);

    if (_buffer.length >= _maxBufferSize) {
      flush();
    }

    // Also print to console in debug mode
    if (kDebugMode) {
      debugPrint('[${log.level.toUpperCase()}:${log.service}] ${log.message}');
    }
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) return;

    try {
      final logs = _buffer.take(_maxBufferSize).toList();
      
      await Supabase.instance.client.from('system_logs').insert(
        logs.map((l) => l.toJson()).toList(),
      );

      for (int i = 0; i < logs.length; i++) {
        _buffer.removeFirst();
      }
    } catch (e) {
      debugPrint('[LoggingService] Failed to flush logs: $e');
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}

class Log {
  final String level;
  final String service;
  final String? userId;
  final String message;
  final Map<String, dynamic>? context;
  final String? stackTrace;
  final DateTime createdAt;

  Log({
    required this.level,
    required this.service,
    required this.message,
    this.userId,
    this.context,
    this.stackTrace,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'service': service,
    'user_id': userId,
    'message': message,
    'context': context,
    'stack_trace': stackTrace,
    'created_at': createdAt.toIso8601String(),
  };
}
```

#### C. Firebase Crashlytics Integration
```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Capture Flutter errors
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    LoggingService.instance.log(
      level: LogLevel.error,
      service: 'flutter',
      message: errorDetails.exceptionAsString(),
      context: {'exception': errorDetails.exception},
      stackTrace: errorDetails.stack.toString(),
    );
  };

  // Capture async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    LoggingService.instance.log(
      level: LogLevel.fatal,
      service: 'platform',
      message: error.toString(),
      stackTrace: stack.toString(),
    );
    return true;
  };

  runApp(const MyApp());
}
```

---

### 3. **Monitoring & Alerting Infrastructure**

**Current State:** Manual checking; no proactive alerts.
**Risk:** Outages go unnoticed for hours; SLA violations.

**Implementation:**

#### A. Uptime Monitoring
```bash
# Use external service like Uptime Robot, Freshping, or Grafana
# OR set up self-hosted monitoring with GitHub Actions

# .github/workflows/health-check.yml
name: Health Check Monitoring
on:
  schedule:
    - cron: '*/5 * * * *'  # Every 5 minutes

jobs:
  health-check:
    runs-on: ubuntu-latest
    steps:
      - name: Check API Health
        run: |
          # Check Supabase API
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            "${{ secrets.SUPABASE_URL }}/rest/v1/health" \
            -H "apikey: ${{ secrets.SUPABASE_ANON_KEY }}")
          
          if [ "$STATUS" != "200" ]; then
            echo "❌ Supabase API down (HTTP $STATUS)"
            # Alert
            curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
              -H 'Content-Type: application/json' \
              -d '{"text": "🚨 Supabase API down: HTTP '$STATUS'"}'
          else
            echo "✅ API healthy"
          fi
      
      - name: Check Database Connection
        run: |
          # Connect to Supabase and run test query
          curl -s -X GET \
            "${{ secrets.SUPABASE_URL }}/rest/v1/trips?select=count()&limit=1" \
            -H "apikey: ${{ secrets.SUPABASE_ANON_KEY }}" | jq .
```

#### B. Performance Monitoring (Supabase Metrics)
```sql
-- Create metrics tracking table
CREATE TABLE performance_metrics (
  id BIGSERIAL PRIMARY KEY,
  metric_name TEXT NOT NULL,
  metric_value FLOAT NOT NULL,
  tags JSONB, -- e.g., {"endpoint": "/rest/v1/trips"}
  recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_metrics_name_time ON performance_metrics(metric_name, recorded_at DESC);
```

#### C. GitHub Actions + Slack Alerts
```yaml
# .github/workflows/alerts.yml
name: Daily Alert Summary
on:
  schedule:
    - cron: '0 9 * * *'  # 9 AM UTC daily

jobs:
  daily-digest:
    runs-on: ubuntu-latest
    steps:
      - name: Fetch Critical Logs
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          # Query for critical errors in last 24 hours
          curl -s -X GET \
            "${SUPABASE_URL}/rest/v1/system_logs?level=in.(error,fatal)&created_at=gt.$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S)&limit=50" \
            -H "apikey: ${SUPABASE_ANON_KEY}" > /tmp/errors.json
          
          ERROR_COUNT=$(jq 'length' /tmp/errors.json)
          
          if [ "$ERROR_COUNT" -gt 0 ]; then
            SUMMARY=$(jq -r '.[] | "\(.level): \(.message)"' /tmp/errors.json | head -10)
            curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
              -H 'Content-Type: application/json' \
              -d @- << EOF
          {
            "text": "📊 Daily Alert Summary",
            "attachments": [{
              "color": "danger",
              "title": "Critical Errors: $ERROR_COUNT",
              "text": "$SUMMARY"
            }]
          }
          EOF
          fi
```

---

### 4. **Backup & Disaster Recovery**

**Current State:** Supabase default 7-day backups; no tested recovery procedures.
**Risk:** Data loss; RTO/RPO unknown; recovery untested.

**Implementation:**

#### A. Automated Backup Strategy
```sql
-- Enable Supabase daily backups (via dashboard or API)
-- Retention: 30 days minimum

-- Also: export critical tables to external storage
CREATE OR REPLACE FUNCTION backup_critical_data()
RETURNS VOID AS $$
BEGIN
  -- Export to CSV (could be uploaded to S3/GCS)
  COPY (SELECT * FROM users) TO '/tmp/users_backup.csv' WITH CSV HEADER;
  COPY (SELECT * FROM trips) TO '/tmp/trips_backup.csv' WITH CSV HEADER;
  COPY (SELECT * FROM chat_messages) TO '/tmp/chat_messages_backup.csv' WITH CSV HEADER;
END;
$$ LANGUAGE plpgsql;

-- Schedule daily backups
SELECT cron.schedule('backup-critical-data', '0 2 * * *', 'SELECT backup_critical_data()');
```

#### B. GitHub Actions Backup Export
```yaml
# .github/workflows/database-backup.yml
name: Database Backup Export
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Export Supabase Data
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
        run: |
          # Export key tables
          TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)
          
          for TABLE in users trips chat_messages expenses; do
            curl -s -X GET \
              "${SUPABASE_URL}/rest/v1/${TABLE}?limit=100000" \
              -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
              -H "Accept: text/csv" > "backup_${TABLE}_${TIMESTAMP}.csv"
          done
          
          # Upload to GitHub Releases (or S3)
          gh release create "backup-${TIMESTAMP}" \
            backup_*.csv \
            --title "Database Backup $TIMESTAMP" \
            --notes "Automated backup"
        env:
          GH_TOKEN: ${{ github.token }}
      
      - name: Cleanup Old Backups
        run: |
          # Keep only last 30 backups
          gh release list --limit 100 | grep "backup-" | tail -n +31 | awk '{print $1}' | while read RELEASE; do
            gh release delete "$RELEASE" -y --cleanup-tag
          done
        env:
          GH_TOKEN: ${{ github.token }}
```

#### C. Disaster Recovery Runbook
```markdown
# Disaster Recovery Procedures

## Database Corruption (Partial Data Loss)
1. **Assess**: Query error logs to determine affected tables/time range
2. **Backup Current State**: Export current database to external storage
3. **Restore Point-in-Time**: Use Supabase backup to restore to point before corruption
4. **Verify**: Run integrity checks on restored data
5. **Notify Users**: Send notification if user data was affected
6. **Post-Mortem**: Determine root cause and implement prevention

## Complete Database Loss
1. **Declare Incident**: Page on-call team
2. **Assess Backups**: Check Supabase backup availability
3. **Restore from Backup**: Restore to latest available backup
4. **Verify Integrity**: Run full data consistency checks
5. **RTO/RPO**: Document actual recovery time & data loss
6. **Communication**: Post status updates to status page

## Service Degradation (API Latency/Timeouts)
1. **Monitor**: Check Supabase metrics dashboard
2. **Scale**: If needed, upgrade Supabase plan tier
3. **Optimize**: Review slow queries; add indexes
4. **Fallback**: Enable cache if applicable
5. **Status Update**: Communicate with users

RTO: 1 hour
RPO: 1 day (24-hour backup retention)
```

---

### 5. **Secrets Management**

**Current State:** Secrets in GitHub Actions secrets; no rotation policy.
**Risk:** Leaked secrets; no audit trail; no rotation.

**Implementation:**

#### A. Secrets Rotation Strategy
```yaml
# .github/workflows/rotate-secrets.yml
name: Quarterly Secrets Rotation
on:
  schedule:
    - cron: '0 0 1 */3 *'  # First day of every quarter

jobs:
  rotate-secrets:
    runs-on: ubuntu-latest
    steps:
      - name: Generate New API Keys
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
        run: |
          echo "🔄 Rotating secrets (quarterly)"
          
          # 1. Rotate Supabase JWT secret
          # (Done via Supabase dashboard)
          
          # 2. Rotate Firebase service account key
          # (Done via Firebase Console)
          
          # 3. Rotate GitHub Personal Access Token
          # (Manual step: delete old PAT, create new one)
          
          # 4. Audit trail
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{"text": "🔄 Scheduled secrets rotation completed"}'

      - name: Send Rotation Reminder
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{
              "text": "⏰ Reminder: Manually rotate secrets",
              "attachments": [{
                "title": "Secrets to Rotate",
                "text": "• Firebase Admin SDK key\n• Google OAuth credentials\n• Supabase JWT secret"
              }]
            }'
```

#### B. Secrets Access Audit
```sql
-- Log all secrets access (for compliance)
CREATE TABLE secrets_audit_log (
  id BIGSERIAL PRIMARY KEY,
  secret_name TEXT NOT NULL,
  accessed_by TEXT NOT NULL, -- GitHub Actions workflow or user
  accessed_at TIMESTAMP DEFAULT NOW(),
  ip_address INET,
  reason TEXT
);

-- Alert on unauthorized access
CREATE OR REPLACE FUNCTION check_secrets_access()
RETURNS TRIGGER AS $$
BEGIN
  -- If accessed outside normal hours or from unusual IP, alert
  IF (EXTRACT(HOUR FROM NOW()) NOT BETWEEN 6 AND 22) THEN
    -- Send alert
    PERFORM http_post(
      'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
      jsonb_build_object('text', 'Unusual secrets access: ' || NEW.secret_name)::text
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

### 6. **Incident Response & On-Call**

**Current State:** No on-call schedule; no incident response plan.
**Risk:** No clear escalation path; slow MTTR (Mean Time To Recovery).

**Implementation:**

#### A. On-Call Scheduling
Use service like PagerDuty, Opsgenie, or Grafana OnCall:

```yaml
# .github/workflows/on-call-alert.yml
name: Send Alert to On-Call
on:
  workflow_run:
    workflows: [Health Check Monitoring]
    types: [completed]

jobs:
  alert-oncall:
    if: failure()
    runs-on: ubuntu-latest
    steps:
      - name: Page On-Call Engineer
        run: |
          # Get current on-call engineer from PagerDuty API
          ON_CALL=$(curl -s -X GET \
            "https://api.pagerduty.com/oncalls?schedule_ids[]=SCHEDULE_ID&include[]=users" \
            -H "Authorization: Token token=${{ secrets.PAGERDUTY_TOKEN }}" \
            | jq -r '.oncalls[0].user.summary')
          
          echo "Paging $ON_CALL..."
          
          # Trigger incident
          curl -X POST https://api.pagerduty.com/incidents \
            -H "Authorization: Token token=${{ secrets.PAGERDUTY_TOKEN }}" \
            -H "Content-Type: application/json" \
            -d @- << EOF
          {
            "incidents": [{
              "type": "incident",
              "title": "Tara Travel Production Alert",
              "urgency": "high",
              "body": {
                "type": "incident_body",
                "details": "Automated health check detected issue"
              }
            }]
          }
          EOF
```

#### B. Incident Response Runbook
```markdown
# Incident Response Procedures

## Severity Levels

### SEV1 (Critical) - Data Loss / Complete Outage
- **Response Time:** Immediate (< 5 min)
- **Team:** On-call engineer + Tech Lead + Backend team
- **Escalation:** CTO if > 15 min unresolved

### SEV2 (High) - Major Functionality Down / >10% Users Affected
- **Response Time:** < 15 minutes
- **Team:** On-call engineer + Backend team
- **Escalation:** Tech Lead if > 30 min unresolved

### SEV3 (Medium) - Feature Degradation / <10% Users Affected
- **Response Time:** < 1 hour
- **Team:** On-call engineer
- **Escalation:** Tech Lead if > 2 hours unresolved

### SEV4 (Low) - Minor Bugs / UI Issues
- **Response Time:** Next business day
- **Team:** Regular on-call rotation

## Incident Response Flow

1. **Detection** → Automated alert via Slack/PagerDuty
2. **Acknowledgment** → On-call engineer confirms receipt (< 2 min)
3. **Assessment** → Determine severity and scope (< 5 min)
4. **Mitigation** → Take immediate action (rollback, hotfix, failover)
5. **Communication** → Post status updates every 15 min
6. **Resolution** → Deploy fix or restore from backup
7. **Validation** → Verify fix is working (health checks pass)
8. **Post-Mortem** → Analyze root cause (within 24 hours)

## Common Incidents & Responses

### API Timeouts
- Check Supabase dashboard for slow queries
- Look for database connection pool exhaustion
- Review recent deployments for regression
- If needed: restart Supabase or upgrade tier

### High Error Rate
- Check error logs in Firebase Crashlytics
- Look for new errors introduced in latest deploy
- Rollback if recent deploy is cause
- Otherwise, investigate root cause in logs

### Data Consistency Issues
- Stop accepting writes (read-only mode)
- Assess data corruption scope
- Restore from backup if corruption is widespread
- Replay writes from transaction logs if possible
```

---

## 🟠 HIGH PRIORITY - Before Launch

### 7. **Configuration Management**

**Implementation:**

```yaml
# config/production.yaml
app:
  name: "Tara Travel"
  version: "1.0.0"
  environment: "production"

supabase:
  url: "${SUPABASE_URL}"
  anon_key: "${SUPABASE_ANON_KEY}"
  service_role_key: "${SUPABASE_SERVICE_ROLE_KEY}"
  region: "us-east-1"

firebase:
  project_id: "tara-travel-30b8e"
  api_key: "${FIREBASE_API_KEY}"

monitoring:
  error_tracking:
    service: "firebase_crashlytics"
    enabled: true
  
  uptime_monitoring:
    enabled: true
    interval: "5m"
    endpoints:
      - "${SUPABASE_URL}/rest/v1/health"
  
  performance_monitoring:
    enabled: true
    sample_rate: 0.1 # Sample 10% of requests

backup:
  enabled: true
  frequency: "daily"
  retention_days: 30
  
incident_response:
  on_call_schedule: "pagerduty"
  escalation_time: "15m"
  
security:
  rate_limiting:
    auth_per_minute: 5
    api_per_hour: 100
  
  secrets_rotation:
    enabled: true
    frequency: "quarterly"
```

---

### 8. **Log Aggregation**

**Implementation:**

```dart
// lib/core/services/log_aggregation_service.dart
class LogAggregationService {
  static final LogAggregationService _instance = LogAggregationService._();
  static LogAggregationService get instance => _instance;

  LogAggregationService._();

  /// Send logs to multiple backends
  Future<void> sendLog({
    required LogLevel level,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.toString().split('.').last.toUpperCase(),
      'message': message,
      'context': context,
    };

    // 1. Send to Supabase
    await _sendToSupabase(log);

    // 2. Send to Firebase Crashlytics (if error/fatal)
    if (level == LogLevel.error || level == LogLevel.fatal) {
      await _sendToCrashlytics(message, context);
    }

    // 3. Send to external logging service (e.g., Sentry, DataDog)
    await _sendToExternalService(log);
  }

  Future<void> _sendToSupabase(Map<String, dynamic> log) async {
    try {
      await Supabase.instance.client.from('system_logs').insert(log);
    } catch (e) {
      debugPrint('Failed to send to Supabase: $e');
    }
  }

  Future<void> _sendToCrashlytics(String message, Map<String, dynamic>? context) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        message,
        null,
        reason: context.toString(),
      );
    } catch (e) {
      debugPrint('Failed to send to Crashlytics: $e');
    }
  }

  Future<void> _sendToExternalService(Map<String, dynamic> log) async {
    // TODO: Implement Sentry, DataDog, or Splunk integration
  }
}
```

---

### 9. **Automated Testing & Quality Gates**

**Current Implementation:** Needs expansion

```yaml
# .github/workflows/quality-gates.yml
name: Quality Gates
on: [pull_request, push]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze --fatal-infos

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run OWASP Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          project: "Tara Travel"
          path: "."
      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: dependency-check-report
          path: reports/
  
  performance-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: |
          flutter pub get
          flutter drive --profile -t test_driver/app.dart
```

---

### 10. **Status Page & Public Communication**

**Implementation:**

```yaml
# .github/workflows/status-page.yml
name: Update Status Page
on:
  schedule:
    - cron: '*/5 * * * *'  # Every 5 minutes

jobs:
  update-status:
    runs-on: ubuntu-latest
    steps:
      - name: Check Service Status
        id: status
        run: |
          # Check Supabase
          SUPABASE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            "${{ secrets.SUPABASE_URL }}/rest/v1/health" \
            -H "apikey: ${{ secrets.SUPABASE_ANON_KEY }}")
          
          if [ "$SUPABASE_STATUS" = "200" ]; then
            echo "supabase=operational" >> $GITHUB_OUTPUT
          else
            echo "supabase=degraded" >> $GITHUB_OUTPUT
          fi

      - name: Publish Status
        run: |
          # Update Statuspage.io (or custom status page)
          curl -X PATCH https://api.statuspage.io/v1/pages/$PAGE_ID/components/$COMPONENT_ID \
            -H "Authorization: OAuth token=${{ secrets.STATUSPAGE_TOKEN }}" \
            -H "Content-Type: application/json" \
            -d '{"component": {"status": "${{ steps.status.outputs.supabase }}"}}'
```

---

## 🟡 MEDIUM PRIORITY - Ongoing

### 11. **Capacity Planning & Scaling**

```markdown
# Capacity Planning

## Current Thresholds
- Database: Supabase Free plan (up to 500 MB)
- Storage: 1 GB
- Auth: 50,000 users (free tier)

## Scaling Triggers
- Database > 400 MB → Upgrade to Pro plan
- Auth users > 40,000 → Upgrade storage/auth
- API requests > 100k/day → Consider caching layer

## Auto-Scaling Plan
1. Monitor Supabase metrics dashboard daily
2. When threshold reached (70%):
   - Alert team
   - Plan upgrade for next sprint
   - Execute upgrade during low-traffic window (2-6 AM UTC)

## Estimated Timeline
- Q1 2024: 1,000 users, 50 MB storage
- Q2 2024: 5,000 users, 200 MB storage
- Q3 2024: 10,000 users, 400 MB storage → Consider upgrade
```

### 12. **Deployment Strategy**

```markdown
# Deployment Procedures

## Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Code review approved
- [ ] Changelog updated
- [ ] Backup scheduled
- [ ] On-call engineer available
- [ ] Status page updated

## Deployment Process
1. **Staging**: Deploy to staging environment, run smoke tests
2. **Canary**: Deploy to 10% of production users, monitor metrics
3. **Full Rollout**: If metrics look good, deploy to 100%
4. **Monitoring**: Watch error rate and latency for 1 hour
5. **Rollback**: If issues detected, automatically rollback

## Rollback Procedure
```bash
# If deployment fails
git revert HEAD
git push origin main  # Triggers re-deployment of previous version
```

## Post-Deployment
- [ ] Verify health checks passing
- [ ] Check error rate is normal
- [ ] Review user feedback / reports
```

---

### 13. **Documentation**

Create runbooks for:
- Deployment procedures
- Incident response
- Backup/restore procedures
- Scaling procedures
- On-call handover
- Emergency contacts

---

## DevOps Checklist - Priority Order

### Week 1 (Critical)
- [ ] Logging infrastructure (Supabase + Firebase Crashlytics)
- [ ] Uptime monitoring (GitHub Actions health checks)
- [ ] Backup automation (GitHub Actions export)
- [ ] Secrets management & rotation policy
- [ ] Incident response runbook & on-call schedule

### Week 2 (High)
- [ ] Infrastructure as Code (Terraform for Supabase)
- [ ] Configuration management (config files)
- [ ] Performance monitoring (metrics tracking)
- [ ] Disaster recovery procedures (tested)
- [ ] Status page setup

### Week 3 (Medium)
- [ ] Log aggregation service (multi-backend)
- [ ] Automated testing expansion
- [ ] Capacity planning document
- [ ] Deployment strategy (canary releases)
- [ ] Documentation & runbooks

### Week 4+ (Ongoing)
- [ ] Regular backup testing
- [ ] Quarterly secrets rotation
- [ ] Capacity monitoring & planning
- [ ] Incident post-mortems
- [ ] CI/CD optimization

---

## Cost Estimation

| Component | Free | Paid | Notes |
|-----------|------|------|-------|
| Supabase | $0 (500MB) | $25+ | Auto-upgrade at 70% capacity |
| Firebase | $0 (limited) | $25+ | Crashlytics included in free tier |
| Monitoring | $0 (GitHub Actions) | $50+ | Uptime Robot, Datadog, etc. |
| Backup Storage | $0 (Supabase) | $10+ | External storage like S3 |
| On-Call | $0 (manual) | $20-50 | PagerDuty, Opsgenie |
| **Total Monthly** | **$0-25** | **$100-150+** | Scale as users grow |

---

## Key Metrics to Track

1. **Availability:** Target 99.5% (43 min downtime/month)
2. **MTTR (Mean Time To Recovery):** Target < 30 minutes
3. **MTTD (Mean Time To Detect):** Target < 5 minutes
4. **Error Rate:** Target < 0.5%
5. **API Latency (P95):** Target < 1 second
6. **Database CPU:** Target < 70% under normal load
7. **Backup Success Rate:** 100%
8. **Deployment Frequency:** 1-2x per week
9. **Deploy Lead Time:** < 1 hour
10. **Change Failure Rate:** < 15%

---

## Resources

- [Google SRE Book](https://sre.google/sre-book/)
- [12 Factor App](https://12factor.net/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Supabase Operations Guide](https://supabase.com/docs/guides/platform/infrastructure)
- [Firebase Production Checklist](https://firebase.google.com/support/guides/launch-checklist)

