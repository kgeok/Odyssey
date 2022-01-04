// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors, unused_import, avoid_print, prefer_conditional_assignment

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:odyssey/data_management.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:io';

void main() async {
  runApp(const MaterialApp(home: MyApp()));
  openDB();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

const double version = 0.8;
const release = "Beta";
Color pincolor = Color(0xffff0000);
var colorBuffer = "FF0000";
LatLng center = LatLng(41.850033, -87.6500523); //Center of the USA
MapType mapType = MapType.normal; //Default Map Type
double bearing = 0; //Rotation of Map
int pinCounter = 0;
var caption = ""; //Null if not init'd
var captionBuffer;
var locationBuffer;
var addressBuffer;
var dateBuffer;
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
  print(pincolor.toString());
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};

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

    addPinDB(pinCounter, caption, color, latLng, "12/31/2099", locationBuffer);

    //When you figure out the memory storage thing, append it's add function here
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
      addressError(context);
    } catch (e) {
      addressError(context);
    }
  }

  void _clearMarkers() {
    caption = "";
    captionBuffer = "";
    pinCounter = 0;
    pins.clear();
    clearDB();
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

  Color pickerColor = Color(0xffff0000);
  Color currentColor = Color(0xffff0000);
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
                  showLabel: false,
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
      return journalEntry(
          "", pincolor, ""); //Create Place holder for Journal Entry
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
                      caption = "";
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

  void aboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text("Odyssey",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Version " + version.toString() + " (" + release + ")",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  const Text(''),
                  Text('With 💖 by Kevin George',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  const Text(''),
                  Text('http://kgeok.github.io/',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  const Text(''),
                  Text('Powered by Google Maps, Material Design and Flutter.',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Help',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                  helpDialog(context);
                },
              ),
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

  void helpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text("Quick Start",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Tap the Map to set a Pin',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  const Text(''),
                  Text(
                      'Tapping the Pin Menu will show options for managing and customizing pins',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  const Text(''),
                  Text(
                      'Tap Caption before setting a Pin to set the Pin\'s Caption',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  const Text(''),
                  Text('Tap The Menu button to open the Journal',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('About',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                  aboutDialog(context);
                },
              ),
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

  void errDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.red[900],
            title: Text("An Error Occurred.",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "Please check your Device settings and make sure the app is up to date.",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
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

  void addressError(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.red[900],
            title: Text("Could not Find Address",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: Colors.white)),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "The address you entered couldn't be found, check and try again.",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
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
                aboutDialog(context); //TODO: Delete when done
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
  }

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
                    height: 120.0,
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
                zoom: 4.0,
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
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Positioned(
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
                            color: MediaQuery.of(context).platformBrightness ==
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
                            color: MediaQuery.of(context).platformBrightness ==
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
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                    alignment: Alignment.topRight,
                    child: Positioned(
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
                            color: MediaQuery.of(context).platformBrightness ==
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
                            color: MediaQuery.of(context).platformBrightness ==
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
