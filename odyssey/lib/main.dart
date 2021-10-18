// ignore_for_file: prefer_typing_uninitialized_variables, prefer_const_constructors, unused_import, avoid_print

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:geocoding/geocoding.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

const double version = 0.7;
const release = "Beta";
Color pincolor = Color(0xffff0000);
int pinCounter = 0;
var caption = ""; //Null if not init'd
var captionBuffer;
var locationBuffer;
var currentTheme;
var pins = [];

class PinData {
  var pinid;
  late var pincaption;
  late Color pincolor;
  late LatLng pincoor;
  late var pinlocation;

  PinData(
      {this.pinid,
      this.pincaption,
      required this.pincolor,
      required this.pincoor,
      required this.pinlocation});
}

MapType mapType = MapType.normal;

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  final LatLng _center = const LatLng(41.850033, -87.6500523);

  void appendMarker(LatLng latLng) {
    pinCounter++;
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
          icon: BitmapDescriptor.defaultMarkerWithHue(0.0),
        ),
      );
    });
  }

  void appendJournal() async {
    setState(() {
      journal.add(pinCounter);
    });
  }

  List<int> journal = [];
  List<Widget> makeJournalEntry() {
    return List<Widget>.generate(journal.length, (int index) {
      return journalEntry(pins[pinCounter - 1].pincaption,
          pins[pinCounter - 1].pincolor, pins[pinCounter - 1].pinlocation);
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
    caption = "";
    captionBuffer = "";
    pinlocation = [];

    //appendJournal(); //TODO: delete if Exceptions occur
  }

  void _clearMarkers() {
    caption = "";
    captionBuffer = "";
    pins.clear();
    pincolor = Color(0xffff0000);
    setState(() {
      _markers = {};
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
                color: pincolor,
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
                "About",
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
              onTap: _clearMarkers,
            ),
          ],
      icon: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: ShapeDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? darkMode.withOpacity(0.8)
                : lightMode.withOpacity(0.8),
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
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
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
              myLocationButtonEnabled: false,
              padding:
                  const EdgeInsets.only(bottom: 0, top: 0, right: 0, left: 0),
              mapType: mapType,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 4.0,
              ),
              onTap: (LatLng latLng) {
                appendMarker(latLng);
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
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? darkMode.withOpacity(0.8)
                                    : lightMode.withOpacity(0.8),
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
                                Theme.of(context).brightness == Brightness.light
                                    ? darkMode.withOpacity(0.8)
                                    : lightMode.withOpacity(0.8),
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
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? darkMode.withOpacity(0.8)
                                    : lightMode.withOpacity(0.8),
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
                                      target: _center,
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
                                Theme.of(context).brightness == Brightness.light
                                    ? darkMode.withOpacity(0.8)
                                    : lightMode.withOpacity(0.8),
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
                                      target: _center,
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
