// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors, unused_import, avoid_print, prefer_conditional_assignment, unrelated_type_equality_checks

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:odyssey/dialogs.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:odyssey/data_management.dart';
import 'package:location/location.dart' as prefix;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:io';

void main() async {
  runApp(const MaterialApp(home: MyApp()));
  OdysseyDatabase.instance.initStatefromDB();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  MyAppState createState() => MyAppState();

  //debug
  static final MyApp instance = MyApp._init();
  const MyApp._init();
}

GlobalKey<MyAppState> key = GlobalKey();
//Variables that we will be using, will try to minimize in the future
const version = "1.0";
const release = "Release";
Color pincolor = Color(int.parse(defaultPinColor));
var colorBuffer = "FF0000"; //Default Pin Color when Map settings are un-init'd
Color pickerColor = Color(0xffff0000);
Color currentColor = Color(0xffff0000);
LatLng center = LatLng(defaultCenterLat, defaultCenterLng); //Center of the USA
MapType mapType = defaultMapType; //Default Map Type
double bearing = defaultBearing; //Rotation of Map
double mapZoom = defaultMapZoom; //Zoom of Map
int pinCounter = 0;
var caption = ""; //Null if not init'd
var captionBuffer; //Temp Buffer for the Caption before it goes into PinData
var locationBuffer; //Temp Buffer for the results for reverseGeocoder before it goes into PinData
var addressBuffer; //Temp Buffer for Pin From Address before it goes into geocoder
var currentTheme;
var pins = [];
List<int> journal = [];

void colorToHex(Color color) {
  //Color for Flutter is parsed differently from HTML and CSS HEX Color codes which apparently SVG uses
  colorBuffer = color.toString();
  colorBuffer = colorBuffer.replaceAll("Color(0xff", "");
  colorBuffer = colorBuffer.replaceAll(")", "");
}

class PinData {
  var pinid;
  late var pincaption;
  late var pindate;
  late Color pincolor;
  late LatLng pincoor;
  late var pinlocation;

  PinData(
      {this.pinid,
      this.pincaption,
      this.pindate,
      required this.pincolor,
      required this.pincoor,
      required this.pinlocation});
}

Future<BitmapDescriptor> _bitmapDescriptorFromSvg(BuildContext context) async {
  String svgString =
      '''<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="100%" version="1.1" viewBox="0 0 76 180.001">
<defs/>
<g stroke="black" stroke-width="2.5">
<path d="M38+4.5C21.4906+4.5+8.09375+17.9077+8.09375+34.4375C8.09375+49.34+19.0104+61.5861+33.25+63.875L32.875+63.875L32.875+147.656L26.4375+147.656L38+175.219L49.5625+147.656L43.125+147.656L43.125+63.875L42.75+63.875C56.9896+61.5861+67.9062+49.34+67.9062+34.4375C67.9062+17.9077+54.5094+4.5+38+4.5Z" opacity="1" fill="#''' +
          colorBuffer +
          '''"/>
</g>
</svg>
''';
  DrawableRoot svgDrawableRoot =
      await svg.fromSvgString(svgString, null.toString());
  MediaQueryData queryData = MediaQuery.of(context);
  double devicePixelRatio = queryData.devicePixelRatio;
  double width = 50 * devicePixelRatio;
  double height = 50 * devicePixelRatio;
  ui.Picture picture = svgDrawableRoot.toPicture(size: Size(width, height));
  ui.Image image = await picture.toImage(width.toInt(), height.toInt());
  ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  //print(pincolor.toString());
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

class MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};

  /* REMOVE THIS AFTER DEMO */

  void demoModeSeq1() {
    clearMarkers();
    pinCounter = 19;

    pins.add(PinData(
        pinid: 0,
        pincolor: Color.fromARGB(255, 0, 181, 21),
        pincoor: LatLng(40.7384455, -74.1709049),
        pindate: "2018-03-18",
        pincaption: "Starbucks ☕️",
        pinlocation: "Broad St: Newark NJ US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF99A45A),
        pincoor: LatLng(41.8835332, -87.619267),
        pindate: "2022-07-24",
        pincaption: "July Chicago Trip",
        pinlocation: "Maggie Daley: Chicago IL US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFFA32626),
        pincoor: LatLng(35.6835979, 139.7541839),
        pindate: "2023-11-09",
        pincaption: "Japan 2023",
        pinlocation: "Imperial Palace: Chiyoda Tokyo JP"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF0F01A3),
        pincoor: LatLng(41.0286593, -73.9690393),
        pindate: "2020-06-20",
        pincaption: "Work",
        pinlocation: "Ramland Rd: Tappan NY US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF056426),
        pincoor: LatLng(37.754208660644075, -122.42534479498104),
        pindate: "2018-03-09",
        pincaption: "Delores Park",
        pinlocation: "Dolores: San Francisco CA US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xff800000),
        pincoor: LatLng(40.7129822, -73.989463),
        pindate: "2022-02-14",
        pincaption: "✨ Date Night ✨",
        pinlocation: "New York, NY US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFFB24E4E),
        pincoor: LatLng(40.7901614, -74.0007664),
        pindate: "2021-09-23",
        pincaption: "KBBQ with Friends",
        pinlocation: "John F Kennedy Blvd: Guttenberg NJ US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFFB962B0),
        pincoor: LatLng(40.7576793, -74.181126),
        pindate: "2022-03-30",
        pincaption: "Cherry Blossoms 🌸",
        pinlocation: "Branch Brook Park: Newark NJ US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF00FF88),
        pincoor: LatLng(40.7520337, -73.9847019),
        pindate: "2021-09-11",
        pincaption: "Spyglass Rooftop",
        pinlocation: "45 W 38th St: New York NY US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF9A9579),
        pincoor: LatLng(40.8497459, -73.9677),
        pindate: "2020-08-04",
        pincaption: "Menya Sandaime 🍜",
        pinlocation: "Parker Ave: Fort Lee NJ US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF029A6F),
        pincoor: LatLng(40.64682, 74.07638),
        pindate: "2017-05-03",
        pincaption: "Staten Island Trip with Alex",
        pinlocation: "Staten Island NY US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF907300),
        pincoor: LatLng(40.7533424, -74.0010089),
        pindate: "2021-12-19",
        pincaption: "The Vessel",
        pinlocation: "Hudson Yards: New York NY US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF53719C),
        pincoor: LatLng(40.7311252, -74.064059),
        pindate: "2018-07-02",
        pincaption: "Journal Square",
        pinlocation: "Journal Square Plaza: Jersey City NJ US"));

    Future.delayed(Duration(milliseconds: 4500));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color.fromARGB(255, 178, 75, 2),
        pincoor: LatLng(40.7795261, -74.0821609),
        pindate: "2020-12-28",
        pincaption: "Work Some More",
        pinlocation: "Meadowlands Pkwy: New Jersey NJ US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xffffbff0),
        pincoor: LatLng(40.70994, 73.98846),
        pindate: "2021-10-02",
        pincaption: "Dinner with Friends",
        pinlocation: "Pier 35: New York NY US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF58008E),
        pincoor: LatLng(37.334331, -122.0080858),
        pindate: "2022-02-02",
        pincaption: "Apple Park",
        pinlocation: "Apple Park: Cupertino CA US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFFAFBF00),
        pincoor: LatLng(40.22034, -73.99972),
        pindate: "2022-02-02",
        pincaption: "Asbury Park",
        pinlocation: "Main St: Asbury Park NJ US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFFFFC4AF),
        pincoor: LatLng(40.1071883, -75.2964526),
        pindate: "2022-02-02",
        pincaption: "Interview",
        pinlocation: "Davis Dr: Plymouth Meeting PA US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xFF612610),
        pincoor: LatLng(40.7530408, -74.025004),
        pindate: "2022-02-02",
        pincaption: "Hidden Grounds Coffee",
        pinlocation: "Hudson St: Hoboken NJ US"));

    populateMapfromState();
  }

  void demoModeSeq2() {
    clearMarkers();
    pinCounter = 6;
    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xffDC582A),
        pincoor: LatLng(28.3751829, -81.5494031),
        pindate: "2022-02-02",
        pincaption: "Florida",
        pinlocation: "Bay Lake FL US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xffDC582A),
        pincoor: LatLng(28.3751829, -81.5494031),
        pindate: "2022-02-02",
        pincaption: "Florida Again",
        pinlocation: "Bay Lake FL US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xffDC582A),
        pincoor: LatLng(28.3751829, -81.5494031),
        pindate: "2022-02-02",
        pincaption: "Maybe Florida",
        pinlocation: "Bay Lake FL US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xff013220),
        pincoor: LatLng(28.3751829, -81.5494031),
        pindate: "2022-02-02",
        pincaption: "Not Florida",
        pinlocation: "Denver CO US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xffDC582A),
        pincoor: LatLng(28.3751829, -81.5494031),
        pindate: "2022-02-02",
        pincaption: "Florida Forever 🥺",
        pinlocation: "Bay Lake FL US"));

    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xff00008b),
        pincoor: LatLng(40.7129822, -74.007205),
        pindate: "2022-02-02",
        pincaption: "Urban Florida",
        pinlocation: "New York NY US"));

    populateMapfromState();
  }

  void demoModeSeq3() {
    clearMarkers();
    pinCounter = 1;
    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xffff0000),
        pincoor: LatLng(30.2642643, -97.7475016),
        pindate: "2022-03-31",
        pincaption: "Austin Trip",
        pinlocation: "Austin, TX US"));

    populateMapfromState();
  }

  void demoModeSeq4() {
    clearMarkers();
    pinCounter = 1;
    pins.add(PinData(
        pinid: 0,
        pincolor: Color(0xff35DB5C),
        pincoor: LatLng(36.1667469, -115.1487083),
        pindate: "2022-04-20",
        pincaption: "Vegas Trip",
        pinlocation: "Las Vegas, NV US"));

    populateMapfromState();
  }

  /* XXXXXXXXXXXXXXXXXXXX */

  void populateMapfromState() async {
    await Future.delayed(Duration(
        milliseconds:
            1500)); //It apparently takes 1 second or so for DB to populate State
    var pinCounterBuffer =
        pinCounter; //I need to freeze the state of the counter so that it doesn't keep iterating on append
    for (var i = 0; i < pinCounterBuffer; i++) {
      pincolor = pins[i].pincolor;
      colorToHex(pincolor);
      pickerColor = pincolor;
      BitmapDescriptor bitmapDescriptor =
          await _bitmapDescriptorFromSvg(context);
      caption = pins[i].pincaption;

      setState(() {
        _markers.add(
          Marker(
              markerId: MarkerId((i + 1).toString()),
              position: pins[i].pincoor,
              infoWindow: InfoWindow(
                title: caption,
                //  snippet: locationBuffer,
              ),
              icon: bitmapDescriptor),
        );
        journal.add(i - 1);
      });
    }
    captionBuffer = "";
  }

  void appendMarker(LatLng latLng) async {
    pinCounter++;
    BitmapDescriptor bitmapDescriptor = await _bitmapDescriptorFromSvg(context);
    reverseGeocoder(latLng);
    setState(() {
      _markers.add(
        Marker(
            markerId: MarkerId(pinCounter.toString()),
            position: latLng,
            infoWindow: InfoWindow(
              title: caption,
              //  snippet: locationBuffer,
            ),
            icon: bitmapDescriptor),
      );
    });
  }

  void reverseGeocoder(LatLng latLng) async {
    List<Placemark> placeMarks =
        await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    var pinlocation = placeMarks;

    locationBuffer = pinlocation[0].name.toString() +
        ": " +
        pinlocation[0].locality.toString() +
        " " +
        pinlocation[0].administrativeArea.toString() +
        " " +
        pinlocation[0].isoCountryCode.toString();

    DateTime currentDate = DateTime.now();
    String date = currentDate.toString().substring(0, 10);
    date.toString();

    pins.add(PinData(
        pinid: pinCounter,
        pincolor: pincolor,
        pincoor: latLng,
        pindate: date,
        pincaption: caption,
        pinlocation: locationBuffer.toString()));

    OdysseyDatabase.instance
        .addPinDB(pinCounter, caption, date, pincolor, latLng, locationBuffer);

    setState(() {
      journal.add(pinCounter - 1);
    });

    caption = "";
    captionBuffer = "";
    pinlocation = [];
    //print(pins[pinCounter - 1].pincaption.toString() + pins[pinCounter - 1].pincolor.toString() + pins[pinCounter - 1].pinlocation.toString());
    //TODO: Causing RangeError when tapping ocean, test this...
  }

  void geocoder(String address) async {
    try {
      List<Location> location = await locationFromAddress(address);
      appendMarker(LatLng(location[0].latitude, location[0].longitude));
    } on NoResultFoundException {
      simpleDialog(
          context,
          "Could not Find Address",
          "The address you entered couldn't be found, check and try again.",
          "",
          "error");
    } catch (e) {
      simpleDialog(
          context,
          "Could not Find Address",
          "The address you entered couldn't be found, check and try again.",
          "",
          "error");
    }
  }

  Future<void> appendFromLocation() async {
    bool _serviceEnabled;
    prefix.PermissionStatus _permissionGranted;
    prefix.Location location = prefix.Location();
    prefix.LocationData currentPosition;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = location.requestService() as bool;

      if (!_serviceEnabled) {
        simpleDialog(context, "No Location", "Unable to Determine Location",
            "Check your Location or Privacy Settings", "error");
        return;
      }

      _permissionGranted = await location.hasPermission();

      if (_permissionGranted == prefix.PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != prefix.PermissionStatus.granted) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
        if (_permissionGranted == prefix.PermissionStatus.deniedForever) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
      }
    }
    currentPosition = await location.getLocation();
    appendMarker(LatLng(currentPosition.latitude!.toDouble(),
        currentPosition.longitude!.toDouble()));
  }

  Future<void> cameraLocation() async {
    bool _serviceEnabled;
    prefix.PermissionStatus _permissionGranted;
    prefix.Location location = prefix.Location();
    prefix.LocationData currentPosition;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = location.requestService() as bool;

      if (!_serviceEnabled) {
        simpleDialog(context, "No Location", "Unable to Determine Location",
            "Check your Location or Privacy Settings", "error");
        return;
      }

      _permissionGranted = await location.hasPermission();

      if (_permissionGranted == prefix.PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != prefix.PermissionStatus.granted) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
        if (_permissionGranted == prefix.PermissionStatus.deniedForever) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
      }
    }
    currentPosition = await location.getLocation();

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentPosition.latitude!.toDouble(),
              currentPosition.longitude!.toDouble()),
          bearing: 0,
          zoom: 12,
        ),
      ),
    );
  }

  void clearMarkers() {
    caption = "";
    captionBuffer = "";
    pinCounter = 0;
    pins.clear();
    OdysseyDatabase.instance.clearPinsDB();

    setState(() {
      _markers = {};
      journal = [];
    });
  }

  void deleteMarker() {
    Marker lastmarker = _markers.firstWhere(
        (marker) => marker.markerId.value == (_markers.length).toString());

    setState(() {
      _markers.remove(lastmarker);
    });
    pins.removeLast();
    journal.removeLast();
    OdysseyDatabase.instance.deletePinDB(pinCounter);
    pinCounter--;
  }

  void toggleMapView() {
    switch (mapType) {
      case MapType.normal:
        setState(() {
          mapType = MapType.hybrid;
        });
        break;
      case MapType.hybrid:
        setState(() {
          mapType = MapType.normal;
        });
        break;
      case MapType.terrain:
        setState(() {
          mapType = MapType.hybrid;
        });
        break;
      case MapType.satellite:
        setState(() {
          mapType = MapType.normal;
        });
        break;
      default:
        setState(() {
          mapType = MapType.normal;
        });
    }
  }

  void toggleMapModes() {
    switch (mapType) {
      case MapType.normal:
        setState(() {
          mapType = MapType.terrain;
        });
        break;
      case MapType.satellite:
        setState(() {
          mapType = MapType.hybrid;
        });
        break;
      case MapType.terrain:
        setState(() {
          mapType = MapType.normal;
        });
        break;
      case MapType.hybrid:
        setState(() {
          mapType = MapType.satellite;
        });
        break;
      default:
        setState(() {
          mapType = MapType.normal;
        });
    }
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  void colorPicker(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              titlePadding: const EdgeInsets.all(15.0),
              contentPadding: const EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              title: Text('Select Color',
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700, color: Colors.white)),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: changeColor,
                  pickerAreaHeightPercent: 0.8,
                  labelTypes: const [],
                  displayThumbColor: true,
                  enableAlpha: false,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  onPressed: () {
                    setState(() => currentColor = pickerColor);
                    setState(() => pincolor = currentColor);
                    colorToHex(pincolor);
                    Navigator.of(context).pop();
                  },
                )
              ]);
        });
  }

  Widget journalEntry(
      final caption, final color, final subtitle, var latlng, var date) {
    latlng = latlng.toString();
    latlng = latlng.replaceAll("LatLng(", "");
    latlng = latlng.replaceAll(")", "");
    return Center(
        child: Wrap(
      direction: Axis.vertical,
      spacing: 4,
      children: [
        InkWell(
            splashColor: color,
            highlightColor: color,
            onTap: () =>
                journalDialog(context, caption, subtitle, latlng, color, date),
            child: Container(
                padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
                decoration: ShapeDecoration(
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset:
                            const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                    color: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                height: 85.0,
                width: 285.0,
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                      Text(caption,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 20)),
                      Text(subtitle,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontSize: 18))
                    ])))),
        const SizedBox(height: 2.5),
      ],
    ));
  }

  List<Widget> makeJournalEntry() {
    return List<Widget>.generate(journal.length, (int index) {
      return journalEntry(pins[index].pincaption, pins[index].pincolor,
          pins[index].pinlocation, pins[index].pincoor, pins[index].pindate);
    });
  }

  void captionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter Caption',
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                          fillColor: Colors.grey[300],
                          filled: true,
                          border: const OutlineInputBorder(),
                          hintText: "Caption"),
                      onChanged: (value) {
                        setState(() {
                          captionBuffer = value;
                        });
                      }),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  setState(() {
                    if (captionBuffer == "") {
                      captionBuffer = "";
                    }
                    if (captionBuffer == null) {
                      captionBuffer = "";
                    }
                    caption = captionBuffer;
                    captionBuffer = "";
                    Navigator.pop(context);
                  });
                },
              )
            ]);
      },
    );
  }

  void addressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter an Address',
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                          fillColor: Colors.grey[300],
                          filled: true,
                          border: const OutlineInputBorder(),
                          hintText: "Full Address"),
                      onChanged: (value) {
                        setState(() {
                          addressBuffer = value;
                        });
                      }),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  setState(() {
                    if (addressBuffer == "") {
                      addressBuffer = " ";
                    } else if (addressBuffer == null) {
                      addressBuffer = " ";
                    }
                    geocoder(addressBuffer);
                    addressBuffer = "";
                    Navigator.pop(context);
                  });
                },
              )
            ]);
      },
    );
  }

  void settings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text("Settings",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  SimpleDialogOption(
                    onPressed: () {
                      clearWarning(context);
                    },
                    child: Text('Clear All Pins',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[400])),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      toggleMapView();
                    },
                    child: Text('Toggle Map View',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      toggleMapModes();
                    },
                    child: Text('Toggle Map Details',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      helpDialog(context);
                    },
                    child: Text('Help',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      aboutDialog(context);
                    },
                    child: Text('About',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      demoModeSeq1();
                    },
                    child: Text('Demo Mode 1',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      demoModeSeq2();
                    },
                    child: Text('Demo Mode 2',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      demoModeSeq3();
                    },
                    child: Text('Demo Mode 3',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      demoModeSeq4();
                    },
                    child: Text('Demo Mode 4',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Dismiss',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

  void clearWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.orange[800],
            title: Text("Clear Pins?",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Are you sure you want to clear all pins?",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  Text("(This will also clear the Journal)",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  clearMarkers();
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

  Widget actionMenu() => PopupMenuButton<int>(
      tooltip: "Show Pin Menu",
      itemBuilder: (context) => [
            PopupMenuItem(
                value: 1,
                child: Text(
                  "Set Color",
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  colorPicker(context);
                }),
            PopupMenuItem(
              value: 2,
              child: Text(
                "Set Caption",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                captionDialog(context);
              },
            ),
            PopupMenuItem(
                value: 3,
                child: Text(
                  "Pin From Address",
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  addressDialog(context);
                }),
            PopupMenuItem(
                value: 4,
                child: Text(
                  "Pin My Location",
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  appendFromLocation();
                }),
            const PopupMenuDivider(height: 20),
            PopupMenuItem(
              value: 5,
              child: Text(
                "Delete Last Pin",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.red),
              ),
              onTap: deleteMarker,
            ),
            const PopupMenuDivider(height: 20),
            PopupMenuItem(
              value: 6,
              child: Text(
                "Settings",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                settings(context);
              },
            ),
          ],
      icon: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: ShapeDecoration(
            color: MediaQuery.of(context).platformBrightness == Brightness.light
                ? lightMode.withOpacity(0.8)
                : darkMode.withOpacity(0.8),
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
            shape: const StadiumBorder()),
        child: const Icon(Icons.push_pin, color: Colors.white),
      ));

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    populateMapfromState();
    //This is only for Pre-Release Versions, This doesn't apply for release versions.
    /*   simpleDialog(
        context,
        "Pre-Release Version",
        "Confidential and Proprietary, Please Don't Share Information or Screenshots",
        "Please Report any Bugs and Crashes, Take note of what you were doing when they occurred.",
        "error"); */
  }

  //UI of the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CustomTheme.lightTheme,
        darkTheme: CustomTheme.darkTheme,
        home: Scaffold(
          appBar: AppBar(
            leading: Builder(builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                enableFeedback: true,
                tooltip: "Open Journal",
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                //tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            }),
            title: Text("Odyssey",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                    height: 120.0, //140.0 if header cuts off on Android
                    child: DrawerHeader(
                      decoration: const BoxDecoration(),
                      child: Text(
                        'Journal',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700, fontSize: 22),
                      ),
                    )),
                Column(
                  children: makeJournalEntry(),
                )
              ],
            ),
          ),
          body: Stack(children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              compassEnabled: false,
              zoomControlsEnabled: false,
              onCameraMove: (CameraPosition cp) {
                center = cp.target;
                bearing = cp.bearing;
              },
              myLocationButtonEnabled: false,
              padding:
                  const EdgeInsets.only(bottom: 0, top: 0, right: 0, left: 0),
              mapType: mapType,
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: mapZoom,
              ),
              onTap: (LatLng latLng) {
                appendMarker(latLng);
              },
              onLongPress: (LatLng latlng) async {
                toggleMapModes();
              },
              markers: _markers,
            ),
            Positioned(
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 6,
                          children: [
                            Container(
                              decoration: ShapeDecoration(
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.8)
                                        : darkMode.withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.my_location_outlined),
                                color: Colors.white,
                                enableFeedback: true,
                                onPressed: cameraLocation,
                              ),
                            ),
                            Container(
                              decoration: ShapeDecoration(
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.8)
                                        : darkMode.withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              child: IconButton(
                                  icon: const Icon(Icons.layers_outlined),
                                  color: Colors.white,
                                  enableFeedback: true,
                                  onPressed: () async {
                                    mapController.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: center,
                                          bearing: 0,
                                          zoom: 6,
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ],
                        )))),
            Positioned(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                        alignment: Alignment.topRight,
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 1,
                          children: [
                            Container(
                              decoration: ShapeDecoration(
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.8)
                                        : darkMode.withOpacity(0.8),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(10),
                                        bottom: Radius.circular(0))),
                              ),
                              child: IconButton(
                                  icon: const Icon(Icons.add),
                                  color: Colors.white,
                                  enableFeedback: true,
                                  onPressed: () async {
                                    var currentZoomLevel =
                                        await mapController.getZoomLevel();
                                    currentZoomLevel = currentZoomLevel + 2;
                                    mapController.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: center,
                                          bearing: bearing,
                                          zoom: currentZoomLevel,
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                            Container(
                              decoration: ShapeDecoration(
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.8)
                                        : darkMode.withOpacity(0.8),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(0),
                                        bottom: Radius.circular(10))),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.remove),
                                color: Colors.white,
                                enableFeedback: true,
                                onPressed: () async {
                                  var currentZoomLevel =
                                      await mapController.getZoomLevel();
                                  currentZoomLevel = currentZoomLevel - 2;
                                  mapController.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: center,
                                        bearing: bearing,
                                        zoom: currentZoomLevel,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )))),
          ]),
          floatingActionButton: Stack(children: <Widget>[
            Align(
                alignment: Alignment.bottomRight,
                child:
                    SizedBox(height: 85.0, width: 85.0, child: actionMenu())),
          ]),
        ));
  }
}
