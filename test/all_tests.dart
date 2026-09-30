import 'package:flutter_test/flutter_test.dart';

import 'core/auth/auth_notifier_test.dart' as auth_notifier_test;
import 'core/personal_allowance_test.dart' as personal_allowance_test;
import 'core/services/app_version_service_test.dart' as app_version_service_test;
import 'core_model_mapping_test.dart' as core_model_mapping_test;
import 'services/convoy_telemetry_test.dart' as convoy_telemetry_test;
import 'services/departure_advisory_service_test.dart' as departure_advisory_service_test;
import 'services/geofence_arrival_service_test.dart' as geofence_arrival_service_test;
import 'services/google_maps_parser_service_test.dart' as google_maps_parser_service_test;
import 'services/osrm_routing_service_test.dart' as osrm_routing_service_test;
import 'services/route_optimization_service_test.dart' as route_optimization_service_test;

void main() {
  group('Tara Travel Unified Test Suite', () {
    auth_notifier_test.main();
    personal_allowance_test.main();
    app_version_service_test.main();
    core_model_mapping_test.main();
    google_maps_parser_service_test.main();
    departure_advisory_service_test.main();
    osrm_routing_service_test.main();
    route_optimization_service_test.main();
    geofence_arrival_service_test.main();
    convoy_telemetry_test.main();
  });
}
