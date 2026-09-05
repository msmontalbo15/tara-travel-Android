import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/services/google_maps_parser_service.dart';
import 'package:tara_travel/core/models/itinerary_model.dart';

void main() {
  final parser = GoogleMapsParserService.instance;

  group('GoogleMapsParserService URL & Coordinate Detection', () {
    test('detects raw coordinates', () {
      expect(parser.isGoogleMapsOrCoordinates('14.5995, 120.9842'), isTrue);
      expect(parser.isGoogleMapsOrCoordinates('14.5995,120.9842'), isTrue);
      expect(parser.isGoogleMapsOrCoordinates('9.8354, 124.1435'), isTrue);
      expect(parser.isGoogleMapsOrCoordinates('hello world'), isFalse);
    });

    test('detects google maps URLs', () {
      expect(
        parser.isGoogleMapsOrCoordinates('https://maps.app.goo.gl/abcdef12345'),
        isTrue,
      );
      expect(
        parser.isGoogleMapsOrCoordinates(
          'https://www.google.com/maps/place/Rizal+Park/@14.5832,120.9794,17z',
        ),
        isTrue,
      );
      expect(
        parser.isGoogleMapsOrCoordinates(
          'https://www.google.com/maps/search/?api=1&query=14.5995,120.9842',
        ),
        isTrue,
      );
      expect(
        parser.isGoogleMapsOrCoordinates('Check out this spot: https://maps.app.goo.gl/xyz'),
        isTrue,
      );
    });

    test('extracts clean URL from text', () {
      const text = 'Here is the hotel: https://maps.app.goo.gl/AbCdEf123 please check it';
      final url = parser.extractUrl(text);
      expect(url, equals('https://maps.app.goo.gl/AbCdEf123'));
    });
  });

  group('StopType Inference', () {
    test('infers hotel for resorts, inns, and accommodations', () {
      expect(parser.inferStopType('El Nido Beach Resort'), equals(StopType.hotel));
      expect(parser.inferStopType('Shangri-La Hotel Manila'), equals(StopType.hotel));
      expect(parser.inferStopType('Sunset Hostel Coron'), equals(StopType.hotel));
      expect(parser.inferStopType('Batanes Homestay'), equals(StopType.hotel));
    });

    test('infers food for dining, cafes, and eateries', () {
      expect(parser.inferStopType('Jollibee Bonifacio High Street'), equals(StopType.food));
      expect(parser.inferStopType('Starbucks Coffee Reserve'), equals(StopType.food));
      expect(parser.inferStopType('Antonio’s Restaurant Tagaytay'), equals(StopType.food));
      expect(parser.inferStopType('Mang Inasal SM Mall of Asia'), equals(StopType.food));
    });

    test('infers transport for airports, stations, and terminals', () {
      expect(parser.inferStopType('NAIA Terminal 3 Airport'), equals(StopType.transport));
      expect(parser.inferStopType('Batangas Port Ferry Terminal'), equals(StopType.transport));
      expect(parser.inferStopType('Cubao Bus Terminal'), equals(StopType.transport));
    });

    test('defaults to activity for parks, museums, and landmarks', () {
      expect(parser.inferStopType('Rizal Park Intramuros'), equals(StopType.activity));
      expect(parser.inferStopType('Kayangan Lake View Deck'), equals(StopType.activity));
      expect(parser.inferStopType('Chocolate Hills Complex'), equals(StopType.activity));
    });
  });
}
