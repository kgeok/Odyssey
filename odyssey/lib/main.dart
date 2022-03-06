// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors, unused_import, avoid_print, prefer_conditional_assignment

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:odyssey/dialogs.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:odyssey/data_management.dart';
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
const double version = 1.0;
const release = "Beta";
Color pincolor = Color(int.parse(defaultPinColor));
var colorBuffer = "FF0000";
Color pickerColor = Color(0xffff0000);
Color currentColor = Color(0xffff0000);
LatLng center = LatLng(defaultCenterLat, defaultCenterLng); //Center of the USA
MapType mapType = defaultMapType; //Default Map Type
double bearing = defaultBearing; //Rotation of Map
double mapZoom = defaultMapZoom; //Zoom of Map
int pinCounter = 0;
var caption = ""; //Null if not init'd
var captionBuffer;
var locationBuffer;
var addressBuffer;
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
              markerId: MarkerId(i.toString()),
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

    pins.add(PinData(
        pinid: pinCounter,
        pincolor: pincolor,
        pincoor: latLng,
        pincaption: caption,
        pinlocation: locationBuffer.toString()));

    setState(() {
      journal.add(pinCounter - 1);
    });

    OdysseyDatabase.instance
        .addPinDB(pinCounter, caption, pincolor, latLng, locationBuffer);

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

  void _clearMarkers() {
    caption = "";
    captionBuffer = "";
    pinCounter = 0;
    pins.clear();
    OdysseyDatabase.instance.clearPinsDB();
    pincolor = Color(0xffff0000);
    setState(() {
      _markers = {};
      journal = [];
    });
  }

  void deleteMarker() {
    pins.remove(pinCounter);
    pins[pinCounter - 1] = "";
    Marker marker = _markers
        .firstWhere((marker) => marker.markerId.value == pinCounter.toString());
    setState(() {
      _markers.remove(marker);
    });
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

  Widget journalEntry(var caption, var color, var subtitle) {
    return Center(
        child: Positioned(
            child: Wrap(
      direction: Axis.vertical,
      spacing: 4,
      children: [
        Container(
            decoration: ShapeDecoration(
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
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
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 20)),
                  Text(subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 18))
                ]))),
        const SizedBox(height: 2.5),
      ],
    )));
  }

  List<Widget> makeJournalEntry() {
    return List<Widget>.generate(journal.length, (int index) {
      return journalEntry("Entry Not Available", pincolor,
          "Journal Coming Soon"); //TODO:Create Place holder for Journal Entry
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
                  _clearMarkers();
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

  Widget actionMenu() => PopupMenuButton<int>(
      itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Text(
                "Caption",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                captionDialog(context);
              },
            ),
            PopupMenuItem(
                value: 2,
                child: Text(
                  "Color",
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  colorPicker(context);
                }),
            PopupMenuItem(
                value: 2,
                child: Text(
                  "Pin From Address",
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  addressDialog(context);
                }),
            const PopupMenuDivider(height: 20),
            PopupMenuItem(
              value: 3,
              child: Text(
                "Delete Last Pin",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
              ),
              onTap: deleteMarker,
            ),
            const PopupMenuDivider(height: 20),
            PopupMenuItem(
              value: 3,
              child: Text(
                "Help and About",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                aboutDialog(context);
              },
            ),
            PopupMenuItem(
              value: 3,
              child: Text(
                "Clear All Pins",
                style: GoogleFonts.quicksand(
                    color: Colors.red, fontWeight: FontWeight.w700),
              ),
              onTap: () {
                clearWarning(context);
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
    simpleDialog(
        context,
        "Pre-Release Version",
        "Confidential and Proprietary, Please Don't Share Information or Screenshots",
        "Please Report any Bugs and Crashes, Take note of what you were doing when they occurred.",
        "error");
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
                    height: 140.0,
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
                var currentZoomLevel = await mapController.getZoomLevel();
                currentZoomLevel = 4;
                mapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: center,
                      bearing: 0,
                      zoom: currentZoomLevel,
                    ),
                  ),
                );
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
                                icon: const Icon(Icons.map_outlined),
                                color: Colors.white,
                                onPressed: toggleMapView,
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
                                onPressed: toggleMapModes,
                              ),
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
                                  }),
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
