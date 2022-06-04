// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors, unused_import, avoid_print, prefer_conditional_assignment, unrelated_type_equality_checks, use_build_context_synchronously
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:odyssey/dialogs.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:odyssey/data_management.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:location/location.dart' as prefix;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
const version = "1.1";
const release = "Pre-Release";
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
int onboarding =
    0; //would be bool but we need to parse db which only has tinyint
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
  late var pinnote;
  late var pinshape;
  late var pinphoto;

  PinData(
      {this.pinid,
      this.pincaption,
      this.pindate,
      this.pinnote,
      this.pinphoto,
      this.pinshape,
      required this.pincolor,
      required this.pincoor,
      required this.pinlocation});
}

Future<BitmapDescriptor> bitmapDescriptorFromSvg(BuildContext context) async {
  String svgString =
      '''<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="100%" version="1.1" viewBox="0 0 76 180.001">
<defs/>
<g stroke="black" stroke-width="2.5">
<path d="M38+4.5C21.4906+4.5+8.09375+17.9077+8.09375+34.4375C8.09375+49.34+19.0104+61.5861+33.25+63.875L32.875+63.875L32.875+147.656L26.4375+147.656L38+175.219L49.5625+147.656L43.125+147.656L43.125+63.875L42.75+63.875C56.9896+61.5861+67.9062+49.34+67.9062+34.4375C67.9062+17.9077+54.5094+4.5+38+4.5Z" opacity="1" fill="#$colorBuffer"/>
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
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

class MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};

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
          await bitmapDescriptorFromSvg(context);
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
      center = pins[i]
          .pincoor; //For whatever reason this was the only way that Center sticks after every cycle
      print("Restored Pin: ${i + 1}");
    }
    captionBuffer = "";
    caption = "";

    print("Center: $center");
    print("Bearing: $bearing");
    print("Zoom: $mapZoom");
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: center,
          bearing: bearing,
          zoom: mapZoom,
        ),
      ),
    );
  }

  void appendMarker(LatLng latLng) async {
    pinCounter++;
    BitmapDescriptor bitmapDescriptor = await bitmapDescriptorFromSvg(context);
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

    locationBuffer =
        "${pinlocation[0].name}: ${pinlocation[0].locality} ${pinlocation[0].administrativeArea} ${pinlocation[0].isoCountryCode}";

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

    mapZoom = await mapController.getZoomLevel();
    OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, latLng);

    caption = "";
    captionBuffer = "";
    pinlocation = [];
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
    bool serviceEnabled;
    prefix.PermissionStatus permissionGranted;
    prefix.Location location = prefix.Location();
    prefix.LocationData currentPosition;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = location.requestService() as bool;

      if (!serviceEnabled) {
        simpleDialog(context, "No Location", "Unable to Determine Location",
            "Check your Location or Privacy Settings", "error");
        return;
      }

      permissionGranted = await location.hasPermission();

      if (permissionGranted == prefix.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != prefix.PermissionStatus.granted) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
        if (permissionGranted == prefix.PermissionStatus.deniedForever) {
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
    bool serviceEnabled;
    prefix.PermissionStatus permissionGranted;
    prefix.Location location = prefix.Location();
    prefix.LocationData currentPosition;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = location.requestService() as bool;

      if (!serviceEnabled) {
        simpleDialog(context, "No Location", "Unable to Determine Location",
            "Check your Location or Privacy Settings", "error");
        return;
      }

      permissionGranted = await location.hasPermission();

      if (permissionGranted == prefix.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != prefix.PermissionStatus.granted) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
        if (permissionGranted == prefix.PermissionStatus.deniedForever) {
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
    OdysseyDatabase.instance.updatePrefsDB(defaultMapZoom, defaultBearing,
        LatLng(defaultCenterLat, defaultCenterLng));
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
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 20)),
                      Text(subtitle,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          maxLines: 1,
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w500,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
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
                      acknowledgeDialog(context);
                    },
                    child: Text('Acknowledgements',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      privacyDialog(context);
                    },
                    child: Text('Privacy Policy',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
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
              onTap: deleteMarker,
              child: Text(
                "Delete Last Pin",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.red),
              ),
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
    simpleDialog(
        context,
        "Pre-Release Version",
        "Confidential and Proprietary, Please Don't Share Information or Screenshots",
        "Please Report any Bugs and Crashes, Take note of what you were doing when they occurred.",
        "error");
  }

  Future startOnboarding() async {
    if (onboarding == 1) {
      complexDialog(
          context,
          "Welcome to Odyssey",
          "Give a new emotional meaning to your places.",
          "Keep track of the destinations you traveled with customizable pins on a beautiful map. With the Journal, you can get a glance of your overall pins and keep notes of where you went and where you want to go.",
          "Tap anywhere on the map to set a Pin.",
          "Open the Pin Menu to Customize those Pins.",
          "info");

      print("Onboarding...");
    } else {
      print("No Onboarding...");
    }
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
              mapToolbarEnabled: false,
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
                                    mapZoom =
                                        await mapController.getZoomLevel();
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
                                  mapZoom = await mapController.getZoomLevel();
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
