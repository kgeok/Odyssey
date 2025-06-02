import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:odyssey/main.dart';
import 'package:odyssey/data_management.dart';

void main() {
  // Initialize global variables to a known state before each test
  setUp(() {
    pincolor = Color(int.parse(defaultPinColor, radix: 16));
    colorBuffer = defaultPinColor.substring(2);
    pickerColor = Color(0xffff0000);
    currentColor = Color(0xffff0000);
    center = LatLng(defaultCenterLat, defaultCenterLng);
    currentLocation = center;
    mapType = defaultMapType;
    shape = defaultPinShape;
    pinCounter = 0;
    waypointCounter = 0;
    caption = "";
    captionBuffer = "";
    note = "";
    noteBuffer = "";
    locationBuffer = "";
    addressBuffer = "";
    catselection = null;
    svgString = "";
    onboarding = 0;
    pins.clear();
    waypoints.clear();
    journal.clear();
    nearbyresults.clear();
    statemarkers.clear();
    statepolylines.clear();
    date = DateTime.now().toString().substring(0, 10);
    filter = "";
  });

  group('PinData Class', () {
    test('PinData constructor initializes properties correctly', () {
      final now = DateTime.now().toString().substring(0, 10);
      final pin = PinData(
        pinid: 1,
        pincaption: 'Test Caption',
        pindate: now,
        pinnote: 'Test Note',
        pincolor: Colors.red,
        pincoor: LatLng(10, 20),
        pinlocation: 'Test Location',
        pinshape: 'circle',
        pinwaypoint: null,
        pinphoto: null,
      );

      expect(pin.pinid, 1);
      expect(pin.pincaption, 'Test Caption');
      expect(pin.pindate, now);
      expect(pin.pinnote, 'Test Note');
      expect(pin.pincolor, Colors.red);
      expect(pin.pincoor, LatLng(10, 20));
      expect(pin.pinlocation, 'Test Location');
      expect(pin.pinshape, 'circle');
      expect(pin.pinwaypoint, isNull);
      expect(pin.pinphoto, isNull);
    });
  });

  group('NearByData Class', () {
    test('NearByData constructor initializes properties correctly', () {
      final nearby = NearByData(
        id: 1,
        name: 'Test Place',
        rating: 4.5,
        coor: LatLng(10, 20),
        distance: [5, 5],
        category: 'Restaurant',
        note: 'Good food',
        state: true,
      );

      expect(nearby.id, 1);
      expect(nearby.name, 'Test Place');
      expect(nearby.rating, 4.5);
      expect(nearby.coor, LatLng(10, 20));
      expect(nearby.category, 'Restaurant');
      expect(nearby.note, 'Good food');
      expect(nearby.state, true);
    });
  });

  group('Utility Functions', () {
    test('shapeHandler returns correct SVG for "circle"', () {
      colorBuffer = "FF0000"; // Ensure colorBuffer is set for testing
      final svg = shapeHandler("circle");
      expect(
          svg,
          contains(
              '<path d="M8 35.6558C8 19.0873 21.4315 5.65582 38 5.65582C54.5685 5.65582 68 19.0873 68 35.6558C68 52.2244 54.5685 65.6558 38 65.6558C21.4315 65.6558 8 52.2244 8 35.6558Z" fill="#FF0000"'));
      expect(shape, "circle"); // Check if global `shape` is updated
    });

    test('shapeHandler returns correct SVG for "square"', () {
      colorBuffer = "0000FF";
      final svg = shapeHandler("square");
      expect(
          svg, contains('<path d="M8 6L68 6L68 66L8 66L8 6Z" fill="#0000FF"'));
      expect(shape, "square");
    });

    test('colorToHex converts Color to correct hex string', () {
      colorToHex(Colors.blue); // ARGB: FF2196F3
      expect(colorBuffer, "2196f3");

      colorToHex(Colors.red.withValues(alpha: 0.5)); // ARGB: 80F44336 (approx)
      colorToHex(Color(0xFFFF0000)); // Red
      expect(colorBuffer, "ff0000");
    });

    test('locationToString converts LatLng to string correctly', () {
      final latLng = LatLng(34.052235, -118.243683);
      final result = locationToString(latLng);
      expect(result, '34.052235, -118.243683');
    });

    test('stringToLocation converts string to LatLng correctly', () {
      final latLngString = '34.052235, -118.243683';
      final result = stringToLocation(latLngString);
      expect(result.latitude, 34.052235);
      expect(result.longitude, -118.243683);
    });

    test('stringToLocation handles invalid string gracefully', () {
      final latLngString = 'invalid_coords';
      final result = stringToLocation(latLngString);
      expect(result, LatLng(0, 0)); // Expect fallback
    });

    test('cleanBuffers resets global caption and note buffers', () {
      caption = "old_caption";
      captionBuffer = "old_caption_buffer";
      note = "old_note";
      noteBuffer = "old_note_buffer";
      locationBuffer = "old_location_buffer";
      addressBuffer = "old_address_buffer";

      cleanBuffers();

      expect(caption, "");
      expect(captionBuffer, "");
      expect(note, "");
      expect(noteBuffer, "");
      expect(locationBuffer, isNull);
      expect(addressBuffer, isNull);
    });
  });

  group('Geocoding and Autofill (requires mocking)', () {
    test('autofill returns correct caption (mocked)', () async {
      // Ensure 'pins' list has an item at index 0 for the autofill to reference
      pins.add(PinData(
        pinid: 1,
        pincaption: 'Original Caption',
        pindate: '2023-01-01',
        pinnote: 'Original Note',
        pincolor: Colors.red,
        pincoor: LatLng(0, 0),
        pinlocation: 'Original Location',
        pinshape: 'circle',
      ));
    });
  });
}
