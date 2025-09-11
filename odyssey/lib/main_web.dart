// ignore_for_file: prefer_const_constructors, prefer_typing_uninitialized_variables, avoid_print, use_build_context_synchronously, prefer_interpolation_to_compose_strings

import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/main.dart';
import 'package:odyssey/dialogs.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:odyssey/data_management.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:location/location.dart' as prefix;
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: CustomTheme.lightTheme,
    darkTheme: CustomTheme.darkTheme,
    initialRoute: '/',
    routes: {
      '/': (context) => const OdysseyMain(),
      '/settings': (context) => const SettingsPage(),
    },
  ));
}

class OdysseyMain extends StatefulWidget {
  const OdysseyMain({super.key});
  @override
  OdysseyMainState createState() => OdysseyMainState();

  //Debug
  static const OdysseyMain instance = OdysseyMain._init();
  const OdysseyMain._init();
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => SettingsPageState();
}

void colorToHex(Color color) {
  //Color for Flutter is parsed differently from HTML and CSS HEX Color codes which apparently SVG uses
  colorBuffer = color.toHexString().substring(2).toLowerCase();
}

class SettingsPageState extends State<SettingsPage> {
  //Callback Implementation to help refresh the Map State To Invoke "SetState" From Settings Page
  VoidCallback? onUpdate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve arguments when dependencies change (e.g., on initial build)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Ensure the callback is only set once
    if (args != null && args.containsKey('onUpdate') && onUpdate == null) {
      onUpdate = args['onUpdate'] as VoidCallback;
    }
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
    //OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
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

    //OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
  }

  void clearAllPinsWarning(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.orange[800],
            title: Text("Clear Pins?", style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text("Are you sure you want to clear all pins?",
                      style: dialogBody),
                  Text("(This will also clear the Journal and Waypoints)",
                      style: dialogBody),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () {
                  clearStateMarkers();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

  void clearAllWaypointsWarning(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.orange[800],
            title: Text("Clear Waypoints?", style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text("Are you sure you want to clear all waypoints?",
                      style: dialogBody),
                  Text("", style: dialogBody),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () {
                  clearStatePolylines();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

  void clearAllPhotosWarning(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.orange[800],
            title: Text("Clear Photos?", style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text("Are you sure you want to clear all photos from pins?",
                      style: dialogBody),
                  Text("", style: dialogBody),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () {
                  clearStatePhotos();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

  void manageWaypointsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(
                "Manage Wayponts",
                style: dialogHeader,
              ),
              content: SingleChildScrollView(
                child: ListBody(
                    children:
                        List<Widget>.generate(waypoints.length, (int index) {
                  return ListTile(
                    onTap: () async {
                      Navigator.pop(context);
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                title: Text(
                                  "Options",
                                  style: dialogHeader,
                                ),
                                content: SingleChildScrollView(
                                    child: ListBody(children: [
                                  SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);

                                      var waypointToPinId = pins
                                          .firstWhere((element) =>
                                              element.pincoor ==
                                              waypoints[index + 1])
                                          .pinid;
                                      deleteWaypoint(waypointToPinId);
                                      onUpdate?.call();
                                    },
                                    child: Text('Delete Waypoint',
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red)),
                                  ),
                                ])),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Dismiss', style: dialogBody),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  )
                                ]);
                          });
                    },
                    title: Text("Waypoint - Point ${index + 1}",
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    subtitle: Text(
                        pins
                            .firstWhere((element) =>
                                element.pincoor == waypoints[index + 1])
                            .pinlocation,
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                  );
                })),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Delete All', style: dialogBody),
                  onPressed: () {
                    Navigator.pop(context);
                    clearAllWaypointsWarning(context);
                  },
                ),
                TextButton(
                  child: Text('Dismiss', style: dialogBody),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ]);
        });
  }

  void clearStateMarkers() {
    cleanBuffers();
    statemarkers = {};
    statepolylines = {};
    journal = [];
    pinCounter = 0;
    waypointCounter = 0;
    pins.clear();
    waypoints.clear();
    //OdysseyDatabase.instance.updatePrefsDB(defaultMapZoom, defaultBearing, defaultMapType);
    //OdysseyDatabase.instance.clearPinsDB();
    onUpdate?.call();
  }

  void clearStatePolylines() {
    cleanBuffers();
    statepolylines = {};
    waypointCounter = 0;
    waypoints.clear();
    //OdysseyDatabase.instance.clearWaypointsDB();
    onUpdate?.call();
  }

  void clearStatePhotos() {
    cleanBuffers();
    statemarkers = {};
    statepolylines = {};
    journal = [];
    pinCounter = 0;
    waypointCounter = 0;
    pins.clear();
    waypoints.clear();
    //OdysseyDatabase.instance.clearPhotosDB();
    onUpdate?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:
            MediaQuery.of(context).platformBrightness == Brightness.light
                ? lightMode.withValues(alpha: 1)
                : darkMode.withValues(alpha: 1),
        appBar: AppBar(
          title: Text("Settings",
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          Card(
            color: Colors.blue[50],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text(sku,
                      style: GoogleFonts.quicksand(
                          color: Colors.black, fontWeight: FontWeight.w500)),
                  subtitle: Text("Version $version, ($release)",
                      style: GoogleFonts.quicksand(
                          color: Color.fromRGBO(81, 81, 81, 1),
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          Card(
              color: Colors.blue[50],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("With 💝 by Kevin George",
                        style: GoogleFonts.quicksand(
                            color: Colors.black, fontWeight: FontWeight.w500)),
                    subtitle: Text("http://kgeok.github.io/",
                        style: GoogleFonts.quicksand(
                            color: Color.fromRGBO(81, 81, 81, 1),
                            fontWeight: FontWeight.w500)),
                    onTap: () => redirectURL("https://kgeok.github.io"),
                  ),
                ],
              )),
          Card(
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                ListTile(
                  leading: Icon(Icons.group),
                  title: Text("Acknowledgements",
                      style: GoogleFonts.quicksand(
                          color: Colors.black, fontWeight: FontWeight.w500)),
                  onTap: () => showLicensePage(
                      context: context,
                      useRootNavigator: false,
                      applicationName: sku,
                      applicationVersion: version,
                      applicationLegalese: "Kevin George"),
                ),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text("Privacy Policy",
                      style: GoogleFonts.quicksand(
                          color: Colors.black, fontWeight: FontWeight.w500)),
                  onTap: () => redirectURL(
                      "https://github.com/kgeok/Odyssey/blob/main/PrivacyPolicy.pdf"),
                ),
                ListTile(
                  leading: Icon(Icons.flag),
                  title: Text("Quick Start",
                      style: GoogleFonts.quicksand(
                          color: Colors.black, fontWeight: FontWeight.w500)),
                  onTap: () => helpDialog(context),
                ),
              ])),
          Card(
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                ListTile(
                  leading: Icon(Icons.view_in_ar),
                  subtitle: Text(mapTypeToString(mapType),
                      style: GoogleFonts.quicksand(
                          color: Color.fromRGBO(81, 81, 81, 1),
                          fontWeight: FontWeight.w500)),
                  title: Text("Toggle Map View",
                      style: GoogleFonts.quicksand(
                          color: Colors.black, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    toggleMapView();
                    onUpdate?.call();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.travel_explore),
                  title: Text("Toggle Map Details",
                      style: GoogleFonts.quicksand(
                          color: Colors.black, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    toggleMapModes();
                    onUpdate?.call();
                  },
                )
              ])),
          Card(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                leading: Icon(Icons.copy),
                title: Text("Copy Journal Contents",
                    style: GoogleFonts.quicksand(
                        color: Colors.black, fontWeight: FontWeight.w500)),
                onTap: () {
                  final StringBuffer clipBoard = StringBuffer();
                  for (final pin in pins) {
                    clipBoard
                      ..writeln(pin.pincaption)
                      ..writeln(pin.pinlocation)
                      ..writeln(pin.pinnote)
                      ..writeln(pin.pindate)
                      ..writeln("(${locationToString(pin.pincoor)})")
                      ..writeln(pin.pinshape.toUpperCase())
                      ..writeln()
                      ..writeln();
                  }
                  Clipboard.setData(ClipboardData(text: clipBoard.toString()));
                  scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Copied to Clipboard.')));
                },
              ),
              ListTile(
                leading: Icon(Icons.draw_rounded),
                title: Text("Manage Waypoints",
                    style: GoogleFonts.quicksand(
                        color: Colors.black, fontWeight: FontWeight.w500)),
                onTap: () {
                  if (waypoints.isNotEmpty) {
                    manageWaypointsDialog(context);
                  } else {
                    simpleDialog(
                        context,
                        "No Waypoints",
                        "Add a Waypoint first to manage Waypoints.",
                        "You can add a Waypoint by opening a Journal Entry and going to \"Options\"",
                        "info");
                  }
                  //clearAllWaypointsWarning(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.no_photography),
                title: Text("Clear All Pin Photos",
                    style: GoogleFonts.quicksand(
                        color: Colors.red, fontWeight: FontWeight.w500)),
                onTap: () {
                  clearAllPhotosWarning(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.location_off),
                subtitle: pins.length == 1
                    ? Text("Clear ${pins.length} Pin",
                        style: GoogleFonts.quicksand(
                            color: Color.fromRGBO(81, 81, 81, 1),
                            fontWeight: FontWeight.w500))
                    : Text("Clear All ${pins.length} Pins",
                        style: GoogleFonts.quicksand(
                            color: Color.fromRGBO(81, 81, 81, 1),
                            fontWeight: FontWeight.w500)),
                title: Text("Clear All Pins",
                    style: GoogleFonts.quicksand(
                        color: Colors.red, fontWeight: FontWeight.w500)),
                onTap: () {
                  clearAllPinsWarning(context);
                },
              ),
            ],
          )),
          SizedBox(height: 50)
        ])));
  }
}

class OdysseyMainState extends State<OdysseyMain> {
  Future populateMapfromState({bool startup = false}) async {
    //await OdysseyDatabase.instance.initStatefromDB();

    setState(() {
      statemarkers.clear();
      statepolylines.clear();
      journal.clear();
      waypoints.clear();
    });

    var pinCounterBuffer =
        pinCounter; //I need to freeze the state of the counter so that it doesn't keep iterating on append
    for (int i = 0; i < pinCounterBuffer; i++) {
      pincolor = pins[i].pincolor;
      colorToHex(pincolor);
      pickerColor = pincolor;
      shape = pins[i].pinshape;
      BitmapDescriptor bitmapDescriptor =
          await bitmapDescriptorFromSvg(context, shape);
      caption = pins[i].pincaption;
      note = pins[i].pinnote;
      if (pins[i].pinlocation == "Location N/A") {
        //Correction for if we didn't fine a location before due to connection issues, etc.
        pins[i].pinlocation = await reverseGeocoder(pins[i].pincoor);
        //OdysseyDatabase.instance.updatePinsDB(i + 1, pins[i].pinlocation, "location");
      }

      setState(() {
        statemarkers.add(
          Marker(
              markerId: MarkerId((i + 1).toString()),
              position: pins[i].pincoor,
              draggable: true,
              onDragEnd: (newPos) async {
                //OdysseyDatabase.instance.updatePinsDB(i + 1, newPos, "latlng");
                //OdysseyDatabase.instance.updatePinsDB( i + 1, await reverseGeocoder(newPos), "location");
                reenumerateState();
                cleanBuffers();
              },
              infoWindow: InfoWindow(
                title: pins[i].pinlocation,
                snippet: caption,
              ),
              icon: bitmapDescriptor),
        );
        if (pins[i].pinwaypoint != null) {
          //Let's do a compare, we want all the keys from highest to lowest
          waypoints[pins[i].pinwaypoint] = pins[i].pincoor;
        }
        journal.add(i - 1);
      });
      center = pins[i]
          .pincoor; //For whatever reason this was the only way that Center sticks after every cycle
      print("Restored Pin: ${i + 1}");
    }
    if (waypoints.isNotEmpty) {
      statepolylines.add(Polyline(
          polylineId: PolylineId(waypointCounter.toString()),
          points: (waypoints.values.toList()),
          width: 5,
          color: Color(int.parse(
              routeColors[Random().nextInt(routeColors.length - 1)]
                  .toString()))));
      cleanBuffers();
    }

    if (startup) {
      //We only want to move the camera when the app is started up otherwise it causes too much movement
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
  }

  Future appendMarker(LatLng latLng) async {
    pinCounter++;
    BitmapDescriptor bitmapDescriptor =
        await bitmapDescriptorFromSvg(context, shape);
    //Adding Entry here...
    locationBuffer = await reverseGeocoder(latLng);

    pins.add(PinData(
        pinid: pinCounter,
        pincolor: pincolor,
        pincoor: latLng,
        pindate: date,
        pinnote: note,
        pincaption: caption,
        pinshape: shape,
        pinlocation: locationBuffer));

    //OdysseyDatabase.instance.addPinDB(pinCounter, caption, date, pincolor, shape, latLng, locationBuffer, note, null, null);

    setState(() {
      journal.add(pinCounter - 1);
      statemarkers.add(
        Marker(
            markerId: MarkerId(pinCounter.toString()),
            position: latLng,
            draggable: true,
            onDragEnd: (newPos) async {
              //We need to find this Pin's ID because it's not sticky, kind of a dumb way of doing it but
              var pinCounterBuffer = statemarkers
                  .firstWhere((marker) => marker.position == latLng);
              //OdysseyDatabase.instance.updatePinsDB(int.parse(pinCounterBuffer.markerId.value), newPos, "latlng");
              //OdysseyDatabase.instance.updatePinsDB(int.parse(pinCounterBuffer.markerId.value), await reverseGeocoder(newPos), "location");
              reenumerateState();
              cleanBuffers();
            },
            infoWindow: InfoWindow(
              title: locationBuffer,
              snippet: caption,
            ),
            icon: bitmapDescriptor),
      );
    });

    mapZoom = await mapController.getZoomLevel();
    //await OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
    cleanBuffers();
  }

  Future appendPolyline(LatLng latLng, int id) async {
    setState(() {
      if (waypoints.values.contains(latLng)) {
        waypoints.removeWhere((key, value) => value == latLng);
      }
      statepolylines.clear();
      waypointCounter++;
      waypoints[waypointCounter] = latLng;

      statepolylines.add(Polyline(
          polylineId: PolylineId(waypointCounter.toString()),
          points: (waypoints.values.toList()),
          width: 5,
          color: Color(int.parse(
              routeColors[Random().nextInt(routeColors.length - 1)]
                  .toString()))));

      OdysseyDatabase.instance.updatePinsDB(id, waypointCounter, "waypoint");
      scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Waypoint Set.'),
      ));
    });
  }

  Future reverseGeocoder(LatLng latLng) async {
    try {
      List<Placemark> placeMarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placeMarks.isNotEmpty) {
        final Placemark placeMark = placeMarks[0];
        if (placeMark.locality != null &&
            placeMark.administrativeArea != null &&
            placeMark.isoCountryCode != null) {
          if (placeMark.street != null && placeMark.street!.isNotEmpty) {
            return "${placeMark.street}: ${placeMark.locality} ${placeMark.administrativeArea} ${placeMark.isoCountryCode}";
          } else if (placeMark.thoroughfare != null &&
              placeMark.thoroughfare!.isNotEmpty) {
            return "${placeMark.thoroughfare}: ${placeMark.locality} ${placeMark.administrativeArea} ${placeMark.isoCountryCode}";
          } else {
            return "${placeMark.locality} ${placeMark.administrativeArea} ${placeMark.isoCountryCode}";
          }
        }
        return placeMark.name ?? "Location N/A";
      }
      return "Location N/A";
    } catch (e) {
      print("Unable to get Location: $e");
      return "Location N/A";
    }
  }

  Future geocoder(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        appendMarker(LatLng(locations[0].latitude, locations[0].longitude));
      } else {
        simpleDialog(
            context,
            "Address Invalid",
            "The address you entered couldn't be found, check and try again.",
            "",
            "error");
      }
    } on NoResultFoundException {
      simpleDialog(
          context,
          "Address Invalid",
          "The address you entered couldn't be found, check and try again.",
          "",
          "error");
    } catch (e) {
      simpleDialog(
          context,
          "Address Invalid",
          "The address you entered couldn't be found, check and try again.",
          "",
          "error");
    }
  }

  Future autofillJournalEntry(String type, LatLng latLng, int id) async {
    switch (type) {
      case "caption":
        try {
          List<Placemark> placeMarks =
              await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
          if (placeMarks.isNotEmpty) {
            return placeMarks[0].name ?? pins[id - 1].pindate;
          }
          return pins[id - 1].pindate; // Fallback to date if no name
        } catch (e) {
          print("Unable to get Location for autofill caption: $e");
          return pins[id - 1].pindate;
        }
      case "note":
        return "Pin $id, Created on ${pins[id - 1].pindate}";
      default:
        return "";
    }
  }

  Widget photoDisplay(Uint8List? bytes) {
    //Only Display The Photo If There's Data
    if (bytes == null || bytes.isEmpty) {
      return SizedBox.shrink();
    } else {
      return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
          child: Container(
              height: 200,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: MemoryImage(bytes), fit: BoxFit.contain))));
    }
  }

  Widget journalEntry(
      final String caption,
      final Color color,
      final String subtitle,
      final LatLng latlng,
      final String date,
      final String note,
      final String shape,
      var photo,
      int id) {
    final bool isLight = color.computeLuminance() > 0.5;
    final Color contentColor = isLight ? Colors.black : Colors.white;
    var target = latlng;
    return Center(
        child: Wrap(
      direction: Axis.vertical,
      spacing: 4,
      children: [
        InkWell(
            splashColor: color,
            highlightColor: color,
            onTap: () {
              // No OnTap For Welcome Entry
              if (id != -1) {
                journalDialog(context, caption, subtitle, latlng, color, date,
                    note, shape, photo, id);
                mapController.animateCamera(
                    CameraUpdate.newCameraPosition(CameraPosition(
                  target: target,
                  bearing: bearing,
                  zoom: mapZoom,
                )));
              }
            },
            child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 0.9,
                child: Container(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
                    decoration: ShapeDecoration(
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            spreadRadius: 5,
                            blurRadius: 10,
                            offset: const Offset(
                                0, 3), // changes position of shadow
                          ),
                        ],
                        color: color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    height: 85.0,
                    width: 292.5,
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
                                  color: contentColor,
                                  fontSize: 20)),
                          Text(subtitle,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w500,
                                  color: contentColor,
                                  fontSize: 18))
                        ]))))),
        const SizedBox(height: 2.5),
      ],
    ));
  }

  //Journal Dialog is long because each of these set of widgets are generated at once for each pin in real-time
  void journalDialog(
      BuildContext context,
      String caption,
      String location,
      LatLng latlng,
      Color color,
      String date,
      String note,
      String shape,
      var photo,
      int id) {
    final bool isLight = color.computeLuminance() > 0.5;
    final Color contentColor = isLight ? Colors.black : Colors.white;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PointerInterceptor(
            child: PointerInterceptor(
                child: AlertDialog(
                    backgroundColor: color,
                    title: Text(caption,
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700, color: contentColor)),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: [
                          photoDisplay(photo),
                          const SizedBox(height: 10),
                          Text(location,
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: contentColor)),
                          const SizedBox(height: 10),
                          Text(locationToString(latlng),
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: contentColor)),
                          const SizedBox(height: 10),
                          Text(date.toString(),
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: contentColor)),
                          const SizedBox(height: 10),
                          Text(note.toString(),
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: contentColor)),
                        ],
                      ),
                    ),
                    actions: <Widget>[
              TextButton(
                child: Text("Full Map",
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: contentColor)),
                onPressed: () {
                  Navigator.of(context).pop();
                  showMapOptionsDialog(context, latlng);
                },
              ),
              TextButton(
                child: Text("Options",
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: contentColor)),
                onPressed: () {
                  showJournalOptionsBottomSheet(context, caption, location,
                      latlng, color, date, note, shape, photo, id);
                },
              ),
              TextButton(
                child: Text("Dismiss",
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: contentColor)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ])));
      },
    );
  }

  void nearbyDialog(BuildContext context, String caption, String location,
      LatLng latlng, String rating, String price, var photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PointerInterceptor(
            child: AlertDialog(
                title: Text(caption, style: dialogHeader),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      photoDisplay(photo),
                      const SizedBox(height: 10),
                      Text(location, style: dialogBody),
                      const SizedBox(height: 10),
                      Text(locationToString(latlng), style: dialogBody),
                      const SizedBox(height: 10),
                      Text("Rating: ${rating.toString()}/5", style: dialogBody),
                      const SizedBox(height: 10),
                      Text("Pricing: $price", style: dialogBody),
                    ],
                  ),
                ),
                actions: <Widget>[
              TextButton(
                child: Text("Full Map", style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                  showMapOptionsDialog(context, latlng);
                },
              ),
              TextButton(
                child: Text("Dismiss", style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ]));
      },
    );
  }

  void showMapOptionsDialog(BuildContext context, LatLng latlng) {
    if (Platform.isIOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Open", style: dialogHeader),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        launchUrl(
                            Uri.parse("https://maps.apple.com/?q=$latlng"),
                            mode: LaunchMode.externalApplication);
                      },
                      child: Text('Apple Maps (App)', style: dialogBody),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        launchUrl(
                            Uri.parse(
                                "comgooglemaps://?center=${latlng.latitude},${latlng.longitude}"),
                            mode: LaunchMode.externalApplication);
                      },
                      child: Text('Google Maps (App)', style: dialogBody),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        redirectURL(
                            "http://maps.google.com/maps?q=${latlng.latitude},${latlng.longitude}");
                      },
                      child: Text('Google Maps (Web)', style: dialogBody),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        },
      );
    } else if (Platform.isAndroid) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Open", style: dialogBody),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        redirectURL(
                            "geo:${latlng.latitude},${latlng.longitude}");
                      },
                      child: Text('Google Maps (App)', style: dialogBody),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        redirectURL(
                            "http://maps.google.com/maps?q=${latlng.latitude},${latlng.longitude}");
                      },
                      child: Text('Google Maps (Web)', style: dialogBody),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Open", style: dialogBody),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        redirectURL(
                            "http://maps.google.com/maps?q=${latlng.latitude},${latlng.longitude}");
                      },
                      child: Text('Google Maps (Web)', style: dialogBody),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        },
      );
    }
  }

  void showShareOptionsBottomSheet(
      BuildContext context,
      final String caption,
      final String location,
      final LatLng latlng,
      final Color color,
      final String shape,
      final String note) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        constraints: BoxConstraints(maxWidth: 500),
        builder: (BuildContext context) {
          final bool isLight = color.computeLuminance() > 0.5;
          final Color contentColor = isLight ? Colors.black : Colors.white;
          return Container(
              constraints: BoxConstraints(maxWidth: 500),
              color: Colors.white, // Consider using theme color
              child: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                ListTile(
                  title: Text("Copy Entry",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(
                        text: "${caption + " " + location}, $date $note"));
                    scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('Copied to Clipboard.')));
                  },
                ),
                ListTile(
                  title: Text("Copy Address",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: location));
                    scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('Copied to Clipboard.')));
                  },
                ),
                ListTile(
                  title: Text("Show QR Code",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            backgroundColor: color,
                            title: Text('QR Code',
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700,
                                    color: contentColor)),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: [
                                  Text(
                                    "Open Odyssey on another device and scan QR Code",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: contentColor),
                                  ),
                                  const SizedBox(height: 10),
                                  generateQRcode(
                                      caption, note, latlng, color, shape)
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Dismiss',
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        color: contentColor)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ]);
                      },
                    );
                  },
                ),
                ListTile(
                  title: Text("",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {},
                ),
              ])));
        });
  }

  SimpleDialogOption editShapeOption(BuildContext context, String text,
      String selectedShape, int id, Color color) {
    final bool isLight = color.computeLuminance() > 0.5;
    final Color contentColor = isLight ? Colors.black : Colors.white;
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context);
        //OdysseyDatabase.instance.updatePinsDB(id, selectedShape, "shape");
        reenumerateState();
      },
      child: Text(text,
          style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w700, color: contentColor)),
    );
  }

  void showEditShapeDialog(BuildContext context, int id, Color color) {
    final bool isLight = color.computeLuminance() > 0.5;
    final Color contentColor = isLight ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: color,
            title: Text("Pin Shape",
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: contentColor)),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  editShapeOption(context, 'Circle', 'circle', id, color),
                  editShapeOption(context, 'Square', 'square', id, color),
                  editShapeOption(context, 'Diamond', 'diamond', id, color),
                  editShapeOption(context, 'Star', 'star', id, color),
                  editShapeOption(context, 'Heart', 'heart', id, color),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Dismiss',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700, color: contentColor)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

  void showJournalOptionsBottomSheet(
      BuildContext context,
      String caption,
      String location,
      LatLng latlng,
      Color color,
      String date,
      String note,
      String shape,
      var photo,
      int id) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      constraints: BoxConstraints(maxWidth: 500),
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(maxWidth: 500),
          color: Colors.white, // Consider using theme color
          child: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  title: Text("Share",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    showShareOptionsBottomSheet(
                        context, caption, location, latlng, color, shape, note);
                  },
                ),
                ListTile(
                  title:
                      waypoints.isNotEmpty && waypoints.values.contains(latlng)
                          ? Text("Replace Waypoint",
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black))
                          : Text("Add Waypoint",
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    appendPolyline(latlng, id);
                  },
                ),
                ListTile(
                  title: photo != null
                      ? Text("Replace Photo",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600, color: Colors.black))
                      : Text("Add Photo",
                          style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    photoOnboarding(context, id);
                  },
                ),
                ListTile(
                  title: Text("Edit Caption/Note",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    showEditCaptionNoteDialog(
                        context, caption, note, latlng, id, color);
                  },
                ),
                ListTile(
                  title: Text("Edit Color",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    showEditColorDialog(context, id, color);
                  },
                ),
                ListTile(
                  title: Text("Edit Shape",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    showEditShapeDialog(context, id, color);
                  },
                ),
                ListTile(
                  title: Text("Delete Entry",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.red[800])),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    showDeleteEntryWarning(context, id);
                  },
                ),
                ListTile(
                  title: Text("",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.black)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showDeleteEntryWarning(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.orange[800],
            title: Text("Delete Entry?", style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text("Are you sure you want to delete this entry?",
                      style: dialogBody),
                  Text("(This will also delete corresponding Pin)",
                      style: dialogBody),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () async {
                  Navigator.pop(context);
                  pins.removeAt(id - 1);
                  //await OdysseyDatabase.instance.initDBfromState();
                  //OdysseyDatabase.instance.deletePinDB(id);
                  reenumerateState(); // Re-render map/journal
                },
              )
            ]);
      },
    );
  }

  void showEditCaptionNoteDialog(BuildContext context, String currentCaption,
      String currentNote, LatLng latlng, int id, Color color) {
    final TextEditingController captionTextController =
        TextEditingController(text: currentCaption);
    final TextEditingController noteTextController =
        TextEditingController(text: currentNote);

    final bool isLight = color.computeLuminance() > 0.5;
    final Color contentColor = isLight ? Colors.black : Colors.white;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: color,
            title: Text('Edit Caption/Note',
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700, color: contentColor)),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Text(
                        "Caption",
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: contentColor),
                      )),
                  TextField(
                    controller: captionTextController,
                    autofocus: true,
                    decoration: InputDecoration(
                        fillColor: Colors.grey[300],
                        filled: true,
                        border: const OutlineInputBorder(),
                        hintText: currentCaption),
                  ),
                  SizedBox(height: 10),
                  Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Text(
                        "Note",
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600, color: contentColor),
                      )),
                  SizedBox(
                      height: 100,
                      child: TextField(
                        controller: noteTextController,
                        autofocus: true,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                            fillColor: Colors.grey[300],
                            filled: true,
                            border: const OutlineInputBorder(),
                            hintText: currentNote),
                      )),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Autofill',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700, color: contentColor)),
                onPressed: () async {
                  final String newCaption =
                      await autofillJournalEntry("caption", latlng, id);
                  final String newNote =
                      await autofillJournalEntry("note", latlng, id);
                  captionTextController.text = newCaption;
                  noteTextController.text = newNote;
                  // Update state and DB immediately for autofill
                  caption = newCaption;
                  note = newNote;
                  //await OdysseyDatabase.instance.updatePinsDB(id, caption, "caption");
                  //await OdysseyDatabase.instance.updatePinsDB(id, note, "note");
                  Navigator.pop(context);
                  reenumerateState();
                },
              ),
              TextButton(
                child: Text('Cancel',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700, color: contentColor)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700, color: contentColor)),
                onPressed: () {
                  caption = captionTextController.text;
                  note = noteTextController.text;
                  //OdysseyDatabase.instance.updatePinsDB(id, caption, "caption");
                  //OdysseyDatabase.instance.updatePinsDB(id, note, "note");
                  Navigator.pop(context);
                  reenumerateState();
                },
              )
            ]);
      },
    );
  }

  void showEditColorDialog(BuildContext context, int id, Color initialColor) {
    Color tempPickerColor = initialColor; // Use a temporary variable for picker

    showDialog(
        context: context,
        builder: (BuildContext context) {
          final bool isLightMode =
              MediaQuery.of(context).platformBrightness == Brightness.light;
          final Color dialogBgColor = isLightMode
              ? lightMode.withValues(alpha: 1)
              : darkMode.withValues(alpha: 1);

          return AlertDialog(
              backgroundColor: dialogBgColor,
              title: Text('Select Color', style: dialogHeader),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: tempPickerColor,
                  onColorChanged: (value) {
                    tempPickerColor = value; // Update temporary color
                  },
                  pickerAreaHeightPercent: 0.75,
                  pickerAreaBorderRadius: BorderRadius.all(Radius.circular(5)),
                  labelTypes: const [],
                  displayThumbColor: true,
                  enableAlpha: false,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK', style: dialogBody),
                  onPressed: () {
                    pincolor = tempPickerColor; // Update global pincolor
                    colorToHex(pincolor); // Update global colorBuffer
                    //OdysseyDatabase.instance.updatePinsDB(id, pincolor, "color");
                    Navigator.pop(context); // Pop color picker dialog
                    reenumerateState(); // Re-render map/journal
                  },
                )
              ]);
        });
  }

  List<Widget> makeJournalEntry(BuildContext context, String filters) {
    if (pins.isNotEmpty) {
      switch (filters) {
        case "Today":
          setState(() {
            pins.removeWhere((item) => (item.pindate) != date);
            journal.removeRange(pins.length, journal.length);
          });
          return List<Widget>.generate(journal.length, (int index) {
            return journalEntry(
                pins[index].pincaption,
                pins[index].pincolor,
                pins[index].pinlocation,
                pins[index].pincoor,
                pins[index].pindate,
                pins[index].pinnote,
                pins[index].pinshape,
                pins[index].pinphoto,
                (index + 1));
          });
        default:
          return List<Widget>.generate(journal.length, (int index) {
            return journalEntry(
                pins[index].pincaption,
                pins[index].pincolor,
                pins[index].pinlocation,
                pins[index].pincoor,
                pins[index].pindate,
                pins[index].pinnote,
                pins[index].pinshape,
                pins[index].pinphoto,
                (index + 1));
          });
      }
    } else {
      final bool isLightMode =
          MediaQuery.of(context).platformBrightness == Brightness.light;
      final Color dialogBgColor = isLightMode
          ? lightMode.withValues(alpha: 1)
          : darkMode.withValues(alpha: 1);
      return List<Widget>.generate(1, (int index) {
        return journalEntry(
            "Get Started",
            dialogBgColor,
            "Add A Pin To Use Journal",
            LatLng(defaultCenterLat, defaultCenterLng),
            "",
            "",
            defaultPinShape,
            null,
            -1);
      });
    }
  }

  void reenumerateState() async {
    cleanBuffers();
    pinCounter = 0;
    pins.clear();
    waypoints.clear();
    setState(() {
      statemarkers = {};
      statepolylines = {};
      journal = [];
    });
    //await OdysseyDatabase.instance.initStatefromDB();
    populateMapfromState(startup: false);
    cleanBuffers();
  }

  Future appendFromCurrentLocation() async {
    try {
      currentLocation = await getCurrentLocation(context, accuracy: "high");
      appendMarker(currentLocation);
    } catch (e) {
      simpleDialog(context, "No Location", "Unable to Determine Location",
          "Check your Connection or Settings.", "error");
    }
  }

  Future getCurrentLocation(BuildContext context,
      {required String accuracy}) async {
    if (!await checkConnection(context)) {
      return null;
    }

    final prefix.Location location = prefix.Location();
    prefix.PermissionStatus permissionGranted;

    // Check and request service
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == prefix.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != prefix.PermissionStatus.granted) {
        return null;
      }
    }

    if (permissionGranted == prefix.PermissionStatus.deniedForever) {
      return null;
    }

    scaffoldMessengerKey.currentState
        ?.showSnackBar(const SnackBar(content: Text('Getting Location...')));

    try {
      switch (accuracy) {
        case "high":
          location.changeSettings(accuracy: prefix.LocationAccuracy.high);
          break;
        case "low":
          location.changeSettings(accuracy: prefix.LocationAccuracy.low);
          break;
        default:
          location.changeSettings(accuracy: prefix.LocationAccuracy.balanced);
      }
      final prefix.LocationData currentPosition =
          await location.getLocation().timeout(const Duration(seconds: 5));

      currentLocation = LatLng(
        currentPosition.latitude!,
        currentPosition.longitude!,
      );
      return currentLocation;
    } catch (e) {
      return null;
    }
  }

  void cameraToLocation() async {
    //We Want To Make Sure That You Can Actually See The Circle...
    Color strokeColor = Color(0x88000000);
    Color fillColor = Color(0x22000000);
    switch (mapType) {
      case MapType.normal:
        strokeColor;
        fillColor;
        break;
      case MapType.hybrid:
        strokeColor = Color(0xDDFFFFFF);
        fillColor = Color(0x66FFFFFF);
        break;
      case MapType.terrain:
        strokeColor;
        fillColor;
        break;
      case MapType.satellite:
        strokeColor = Color(0xDDFFFFFF);
        fillColor = Color(0x66FFFFFF);
        break;
      default:
        strokeColor;
        fillColor;
        break;
    }
    try {
      currentLocation = await getCurrentLocation(context, accuracy: "high");
      setState(() {
        statecircles.add(Circle(
            circleId: CircleId("1"),
            center: currentLocation,
            radius: 2000,
            strokeWidth: 4,
            strokeColor: strokeColor,
            fillColor: fillColor));
      });
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            bearing: 0,
            zoom: 12,
          ),
        ),
      );
      await Future.delayed(Duration(seconds: 3));
      setState(() {
        deleteCircle(1);
      });
    } catch (e) {
      simpleDialog(context, "No Location", "Unable to Determine Location",
          "Check your Connection or Settings.", "error");
    }
  }

  Widget generateQRcode(final String caption, final String note,
      final LatLng latlng, final Color color, final String shape) {
    return Container(
      alignment: Alignment.center,
      width: 200.0,
      height: 200.0,
      child: QrImageView(
        //Update with possible URI Scheme later
        data:
            'odyssey://&latlng=${locationToString(latlng)}&caption=$caption&note=$note&color=${colorToString(color)}&shape=$shape',
        backgroundColor: Colors.white,
        version: QrVersions.auto,
        gapless: false,
        eyeStyle:
            const QrEyeStyle(color: Colors.black, eyeShape: QrEyeShape.square),
        dataModuleStyle: QrDataModuleStyle(
            color: Colors.black, dataModuleShape: QrDataModuleShape.square),
      ),
    );
  }

  void scanQRcode(BuildContext context) async {
    final bool isLight = pincolor.computeLuminance() > 0.5;
    final Color contentColor = isLight ? Colors.black : Colors.white;
    double cardwidth() {
      if (MediaQuery.of(context).size.width < 500) {
        return MediaQuery.of(context).size.width / 1.5;
      } else {
        return 300;
      }
    }

    showModalBottomSheet(
        context: context,
        enableDrag: true,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (BuildContext context) {
          return Column(
              mainAxisSize: MainAxisSize.min,
              // crossAxisAlignment: CrossAxisAlignment.center,
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                  child: Text("Scan QR Code",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.black)),
                ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Text(
                        "Open Odyssey on another device, open a Journal Entry and show QR Code",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black))),
                SizedBox(
                    height: cardwidth(),
                    width: cardwidth(),
                    child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32.0),
                          topRight: Radius.circular(32.0),
                          bottomRight: Radius.circular(32.0),
                          bottomLeft: Radius.circular(32.0),
                        ),
                        child: AspectRatio(
                            aspectRatio: 1,
                            child: MobileScanner(
                                controller: MobileScannerController(
                                  detectionSpeed: DetectionSpeed.noDuplicates,
                                ),
                                fit: BoxFit.fill,
                                onDetect: (capture) async {
                                  final List barcodes = capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if ((barcode.rawValue)
                                        .toString()
                                        .startsWith("odyssey://")) {
                                      var capturedValue =
                                          (barcode.rawValue.toString())
                                              .split(RegExp(r'[&=]'));
                                      var location = await reverseGeocoder(
                                          stringToLocation(capturedValue[
                                              capturedValue.indexWhere(
                                                      (element) =>
                                                          element == "latlng") +
                                                  1]));
                                      pincolor = Color(int.parse(capturedValue[
                                              (capturedValue.indexWhere(
                                                      (element) =>
                                                          element == "color")) +
                                                  1]
                                          .toString()));
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                              backgroundColor: pincolor,
                                              title: Text(
                                                  'Add this Journal Entry?',
                                                  style: GoogleFonts.quicksand(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: contentColor)),
                                              content: SingleChildScrollView(
                                                child: ListBody(
                                                  children: [
                                                    SingleChildScrollView(
                                                      child: ListBody(
                                                        children: [
                                                          Text(
                                                              capturedValue[capturedValue.indexWhere((element) =>
                                                                          element ==
                                                                          "caption") +
                                                                      1]
                                                                  .toString(),
                                                              style: GoogleFonts.quicksand(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      contentColor)),
                                                          const Text(""),
                                                          Text(location,
                                                              style: GoogleFonts.quicksand(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      contentColor)),
                                                          const Text(""),
                                                          Text(
                                                              capturedValue[capturedValue.indexWhere((element) =>
                                                                          element ==
                                                                          "latlng") +
                                                                      1]
                                                                  .toString(),
                                                              style: GoogleFonts.quicksand(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      contentColor)),
                                                          const Text(""),
                                                          Text(
                                                              capturedValue[capturedValue.indexWhere((element) =>
                                                                          element ==
                                                                          "note") +
                                                                      1]
                                                                  .toString(),
                                                              style: GoogleFonts.quicksand(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      contentColor)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text('Cancel',
                                                      style:
                                                          GoogleFonts.quicksand(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  contentColor)),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    scanQRcode(context);
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text('OK',
                                                      style:
                                                          GoogleFonts.quicksand(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  contentColor)),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    caption = capturedValue[
                                                            capturedValue.indexWhere(
                                                                    (element) =>
                                                                        element ==
                                                                        "caption") +
                                                                1]
                                                        .toString();
                                                    note = capturedValue[
                                                            capturedValue.indexWhere(
                                                                    (element) =>
                                                                        element ==
                                                                        "note") +
                                                                1]
                                                        .toString();
                                                    shape = capturedValue[
                                                            capturedValue.indexWhere(
                                                                    (element) =>
                                                                        element ==
                                                                        "shape") +
                                                                1]
                                                        .toString();
                                                    colorToHex(Color(int.parse(
                                                        capturedValue[(capturedValue
                                                                .indexWhere(
                                                                    (element) =>
                                                                        element ==
                                                                        "color")) +
                                                            1])));
                                                    appendMarker(stringToLocation(
                                                        capturedValue[capturedValue
                                                                .indexWhere(
                                                                    (element) =>
                                                                        element ==
                                                                        "latlng") +
                                                            1]));
                                                    scaffoldMessengerKey
                                                        .currentState
                                                        ?.showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Added Journal Entry')));
                                                  },
                                                )
                                              ]);
                                        },
                                      );
                                    }
                                  }
                                })))),
                SizedBox(height: 25)
              ]);
        });
  }

  void deleteLastMarker() {
    Marker lastmarker = statemarkers.firstWhere(
        (marker) => marker.markerId.value == (statemarkers.length).toString());
    pins.removeLast();
    journal.removeLast();
    //OdysseyDatabase.instance.deletePinDB(pinCounter);
    pinCounter--;
    setState(() {
      statemarkers.removeWhere((value) => value == lastmarker);
      if (waypoints.values.contains(lastmarker.position)) {
        waypoints.removeWhere((key, value) => value == lastmarker.position);
        statepolylines.clear();
        statepolylines.add(Polyline(
            polylineId: PolylineId(waypointCounter.toString()),
            points: (waypoints.values.toList()),
            width: 5,
            color: Color(int.parse(
                routeColors[Random().nextInt(routeColors.length - 1)]
                    .toString()))));
      }
    });
  }

  void colorPicker(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Select Color', style: dialogHeader),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (value) {
                    setState(() {
                      pickerColor = value;
                    });
                  },
                  pickerAreaHeightPercent: 0.75,
                  pickerAreaBorderRadius: BorderRadius.all(Radius.circular(5)),
                  labelTypes: const [],
                  displayThumbColor: true,
                  enableAlpha: false,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Shape', style: dialogBody),
                  onPressed: () {
                    setState(() {
                      currentColor = pickerColor;
                      pincolor = currentColor;
                    });
                    colorToHex(pincolor);
                    Navigator.of(context).pop();
                    shapeDialog(context);
                  },
                ),
                TextButton(
                  child: Text('Cancel', style: dialogBody),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK', style: dialogBody),
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

  void captionNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter Caption/Note', style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Text(
                        "Caption",
                        style: dialogBody,
                      )),
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
                  SizedBox(height: 10),
                  Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Text(
                        "Note",
                        style: dialogBody,
                      )),
                  SizedBox(
                      height: 100,
                      child: TextField(
                          autofocus: true,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                              fillColor: Colors.grey[300],
                              filled: true,
                              border: const OutlineInputBorder(),
                              hintText: "Note"),
                          onChanged: (value) {
                            setState(() {
                              noteBuffer = value;
                            });
                          })),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () {
                  setState(() {
                    if (captionBuffer.isEmpty) {
                      captionBuffer = "";
                    }
                    if (noteBuffer.isEmpty) {
                      noteBuffer = "";
                    }
                    caption = captionBuffer;
                    note = noteBuffer;
                    captionBuffer = "";
                    noteBuffer = "";
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
            title: Text('Enter an Address', style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
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
                child: Text('Coordinates', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                  coorDialog(context);
                },
              ),
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () {
                  setState(() {
                    if (addressBuffer.isEmpty) {
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

  void coorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter Coordinates', style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  TextField(
                      autofocus: true,
                      keyboardType: TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                          fillColor: Colors.grey[300],
                          filled: true,
                          border: const OutlineInputBorder(),
                          hintText: "Latitude, Longitude"),
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
                child: Text('Address', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                  addressDialog(context);
                },
              ),
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () async {
                  if (await reverseGeocoder(stringToLocation(addressBuffer)) ==
                      "Location N/A") {
                    simpleDialog(
                        context,
                        "Coordinates Invalid",
                        "The coordinates you entered couldn't be used, check and try again.",
                        "",
                        "error");
                  } else {
                    setState(() {
                      if (addressBuffer.isEmpty) {
                        addressBuffer = " ";
                      }
                      appendMarker(stringToLocation(addressBuffer));
                      addressBuffer = "";
                      Navigator.pop(context);
                    });
                  }
                },
              )
            ]);
      },
    );
  }

  void mapMade(GoogleMapController controller) async {
    checkConnection(context);
    mapController = controller;
    await populateMapfromState(startup: true);
    if (onboarding == 1) {
      onboardDialog(context);
      print("Onboarding...");
    } else {
      print("No Onboarding...");
    }
    //This is only for Pre-Release Versions, This doesn't apply for release versions.
    if (release == "Pre-Release") {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: const Text('Pre-Release Version'),
          duration: const Duration(milliseconds: 3000),
          backgroundColor: Colors.red[800],
          action: SnackBarAction(
              label: 'More Info',
              textColor: Colors.white,
              onPressed: () {
                simpleDialog(
                    context,
                    "Pre-Release Version",
                    "Confidential and Proprietary, Please Don't Share Information or Screenshots",
                    "Please Report any Bugs and Crashes, Take note of what you were doing when they occurred.",
                    "error");
              })));
    }
  }

  Future presentNearBy() async {
    try {
      if (await getCurrentLocation(context, accuracy: "high") != null) {
        final placeskey = places.GoogleMapsPlaces(apiKey: apikey);
        places.PlacesSearchResponse response;

        final categories = [
          "Accounting",
          "Airport",
          "Amusement Park",
          "Aquarium",
          "Art Gallery",
          "ATM",
          "Bakery",
          "Bank",
          "Bar",
          "Beauty Salon",
          "Bicycle Store",
          "Book Store",
          "Bowling Alley",
          "Bus Station",
          "Cafe",
          "Campground",
          "Car Dealer",
          "Car Rental",
          "Car Repair",
          "Car Wash",
          "Casino",
          "Cemetery",
          "Church",
          "City Hall",
          "Clothing Store",
          "Convenience Store",
          "Courthouse",
          "Dentist",
          "Department Store",
          "Doctor",
          "Drugstore",
          "Electrician",
          "Electronics Store",
          "Embassy",
          "Fire Station",
          "Florist",
          "Funeral Home",
          "Furniture Store",
          "Gas Station",
          "Gym",
          "Hair Care",
          "Hardware Store",
          "Hindu Temple",
          "Home Goods Store",
          "Hospital",
          "Insurance Agency",
          "Jewelry Store",
          "Laundry",
          "Lawyer",
          "Library",
          "Light Rail Station",
          "Liquor Store",
          "Local Government Office",
          "Locksmith",
          "Lodging",
          "Meal Delivery",
          "Meal Takeaway",
          "Mosque",
          "Movie Rental",
          "Movie Theater",
          "Moving Company",
          "Museum",
          "Night Club",
          "Painter",
          "Park",
          "Parking",
          "Pet Store",
          "Pharmacy",
          "Physiotherapist",
          "Plumber",
          "Police",
          "Post Office",
          "Primary School",
          "Real Estate Agency",
          "Restaurant",
          "Roofing Contractor",
          "RV Park",
          "School",
          "Secondary School",
          "Shoe Store",
          "Shopping Mall",
          "Spa",
          "Stadium",
          "Storage",
          "Store",
          "Subway Station",
          "Supermarket",
          "Synagogue",
          "Taxi Stand",
          "Tourist Attraction",
          "Train Station",
          "Transit Station",
          "Travel Agency",
          "University",
          "Veterinary Care",
          "Zoo",
        ];

        showModalBottomSheet(
            context: context,
            constraints: const BoxConstraints(maxWidth: 750),
            builder: (BuildContext context) {
              return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return Center(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 15, child: Text("")),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 50),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(5.0),
                        shrinkWrap: true,
                        children: List<Widget>.generate(categories.length,
                            (int index) {
                          return Wrap(children: [
                            const SizedBox(width: 3.5, child: Text("")),
                            ChoiceChip(
                                label: Text(categories[index],
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                backgroundColor: Colors.grey[500],
                                labelStyle: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                                selectedColor:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withValues(alpha: 1)
                                        : darkMode.withValues(alpha: 1),
                                selected: catselection == index,
                                onSelected: (bool selected) async {
                                  setState(() {
                                    catselection = selected ? index : null;
                                    nearbyresults.clear();
                                  });

                                  response =
                                      await placeskey.searchNearbyWithRadius(
                                          places.Location(
                                              lat: currentLocation.latitude,
                                              lng: currentLocation.longitude),
                                          5000,
                                          type: ((categories[index])
                                                  .toLowerCase())
                                              .replaceAll(" ", "_"));
                                  setState(() {
                                    if (response.results.isNotEmpty) {
                                      for (int i = 0;
                                          i < response.results.length;
                                          i++) {
                                        nearbyresults.add(NearByData(
                                            name: response.results[i].name,
                                            category: categories[index],
                                            rating:
                                                response.results[i].rating ?? 0,
                                            coor: LatLng(
                                                response.results[i].geometry?.location.lat ??
                                                    0,
                                                response.results[i].geometry
                                                        ?.location.lng ??
                                                    0),
                                            distance: latLngDifferenceToKmMiles(
                                                inputOne: LatLng(
                                                    currentLocation.latitude,
                                                    currentLocation.longitude),
                                                inputTwo: LatLng(
                                                    response.results[i].geometry
                                                            ?.location.lat ??
                                                        0,
                                                    response.results[i].geometry
                                                            ?.location.lng ??
                                                        0)),
                                            id: i,
                                            price: priceToString(response.results[i].priceLevel),
                                            photoRef: response.results[i].photos.isNotEmpty ? response.results[i].photos.first.toJson()["photo_reference"] : "",
                                            state: true));
                                      }
                                    }
                                  });
                                })
                          ]);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                        child: ListView(
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.all(2.0),
                      shrinkWrap: true,
                      children: catselection != null
                          ? nearbyresults.isNotEmpty
                              ? List<Widget>.generate(nearbyresults.length,
                                  (int index) {
                                  return ListTile(
                                    title: Text(nearbyresults[index].name,
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700)),
                                    subtitle: Text(
                                        "Rating: ${nearbyresults[index].rating.toString()}/5, Distance: ${(nearbyresults[index].distance)[0]} km Away, ${(nearbyresults[index].distance)[1]} Miles Away",
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700)),
                                    onTap: () async {
                                      if (nearbyresults[index].state) {
                                        mapController.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: nearbyresults[index].coor,
                                              zoom: 14,
                                            ),
                                          ),
                                        );
                                        Uint8List? bytes;
                                        if (nearbyresults[index].photoRef !=
                                            "") {
                                          bytes =
                                              await googlePlacePhotoReftoBytes(
                                                  nearbyresults[index]
                                                      .photoRef);
                                        }
                                        nearbyDialog(
                                            context,
                                            nearbyresults[index].name,
                                            await reverseGeocoder(
                                                nearbyresults[index].coor),
                                            nearbyresults[index].coor,
                                            nearbyresults[index]
                                                .rating
                                                .toString(),
                                            nearbyresults[index].price,
                                            bytes);
                                      } else {
                                        null;
                                      }
                                    },
                                    trailing: nearbyresults[index].state
                                        ? IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              caption =
                                                  nearbyresults[index].name;
                                              note =
                                                  "Rating: ${nearbyresults[index].rating}/5, Price: ${nearbyresults[index].price}";
                                              appendMarker(
                                                  nearbyresults[index].coor);
                                              setState(() =>
                                                  nearbyresults[index].state =
                                                      false);
                                              nearbyresults[index].state =
                                                  false;
                                              scaffoldMessengerKey.currentState
                                                  ?.showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Added Journal Entry.')));
                                            })
                                        : IconButton(
                                            icon: const Icon(Icons.check),
                                            onPressed: () {},
                                          ),
                                  );
                                })
                              : List<Widget>.generate(1, (int index) {
                                  return ListTile(
                                      title: Text("No Results",
                                          style: GoogleFonts.quicksand(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF3B3B3B))),
                                      subtitle: Text(
                                          "Try Another Category Or Another Location",
                                          style: GoogleFonts.quicksand(
                                              fontWeight: FontWeight.w700)));
                                })
                          : List<Widget>.generate(1, (int index) {
                              return ListTile(
                                  title: Text("Pick A Category",
                                      style: GoogleFonts.quicksand(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF3B3B3B))),
                                  subtitle: Text(
                                      "Using Near By, You Can See Places Of Interest Near You",
                                      style: GoogleFonts.quicksand(
                                          fontWeight: FontWeight.w700)));
                            }),
                    ))
                  ],
                ));
              });
            });
      } else {
        simpleDialog(context, "No Location", "Unable to Determine Location",
            "Check your Connection or Settings.", "error");
      }
    } catch (e) {
      simpleDialog(context, "No Location", "Unable to Determine Location",
          "Check your Connection or Settings.", "error");
    }
  }

  Future photoOnboarding(BuildContext context, int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor:
                MediaQuery.of(context).platformBrightness == Brightness.light
                    ? lightMode.withValues(alpha: 1)
                    : darkMode.withValues(alpha: 1),
            title: Text('Choose Provider', style: dialogHeader),
            content: SingleChildScrollView(
                child: ListBody(children: <Widget>[
              SimpleDialogOption(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final selectedPhotoToData;
                    final XFile? selectedPhoto =
                        await photo.pickImage(source: ImageSource.gallery);
                    if (selectedPhoto != null) {
                      selectedPhotoToData = await selectedPhoto.readAsBytes();
                      //OdysseyDatabase.instance.updatePinsDB(id, selectedPhotoToData, "photo");
                      reenumerateState();
                    }
                  } catch (e) {
                    simpleDialog(context, "Unable to Retrieve Photos",
                        "Check your Settings and try again.", "", "error");
                  }
                },
                child: Text('System Photos', style: dialogBody),
              ),
              SimpleDialogOption(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final selectedPhotoToData;
                    final XFile? selectedPhoto =
                        await photo.pickImage(source: ImageSource.camera);
                    if (selectedPhoto != null) {
                      selectedPhotoToData = await selectedPhoto.readAsBytes();
                      //OdysseyDatabase.instance.updatePinsDB(id, selectedPhotoToData, "photo");
                      reenumerateState();
                    }
                  } catch (e) {
                    simpleDialog(context, "Unable to Retrieve Photos",
                        "Check your Settings and try again.", "", "error");
                  }
                },
                child: Text('System Camera', style: dialogBody),
              ),
            ])),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ]);
      },
    );
  }

  //UI of Main Page
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget actionMenu() => PointerInterceptor(
        child: PopupMenuButton<int>(
            tooltip: "Show Pin Menu",
            itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 1,
                      child: Text(
                        "Set Color/Shape",
                        style:
                            GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        colorPicker(context);
                      }),
                  PopupMenuItem(
                    value: 2,
                    child: Text(
                      "Set Caption/Note",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      captionNoteDialog(context);
                    },
                  ),
                  const PopupMenuDivider(height: 20),
                  PopupMenuItem(
                      value: 3,
                      child: Text(
                        "Pin From Address",
                        style:
                            GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        addressDialog(context);
                      }),
                  PopupMenuItem(
                      value: 4,
                      child: Text(
                        "Pin My Location",
                        style:
                            GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        appendFromCurrentLocation();
                      }),
                  PopupMenuItem(
                      value: 5,
                      child: Text(
                        "Scan QR Code",
                        style:
                            GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        scanQRcode(context);
                      }),
                  const PopupMenuDivider(height: 20),
                  PopupMenuItem(
                    value: 6,
                    onTap: deleteLastMarker,
                    child: Text(
                      "Delete Last Pin",
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700, color: Colors.red),
                    ),
                  ),
                  const PopupMenuDivider(height: 20),
                  PopupMenuItem(
                    value: 7,
                    child: Text(
                      "Settings",
                      style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                          "/settings",
                          arguments: {'onUpdate': reenumerateState});
                      Navigator.of(context).reassemble();
                    },
                  ),
                ],
            icon: PointerInterceptor(
                child: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: ShapeDecoration(
                  color: MediaQuery.of(context).platformBrightness ==
                          Brightness.light
                      ? lightMode.withValues(alpha: 1)
                      : darkMode.withValues(alpha: 1),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)))),
              child: const Icon(Icons.push_pin, color: Colors.white),
            ))));

    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            leading: Builder(builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                tooltip: "Open Journal",
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            }),
            title: Text(sku,
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
          ),
          drawer: PointerInterceptor(
              child: Drawer(
            child: ListView(
              padding:
                  EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
              children: [
                SizedBox(
                    //140.0 if header cuts off on Android
                    child: ListTile(
                  title: Text(
                    "Journal",
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white),
                  ),
                  trailing: SizedBox(
                      width: 100,
                      child: Row(children: [
                        SizedBox(width: 52),
                        IconButton(
                          icon: Icon(Icons.more_horiz),
                          color: Colors.white,
                          onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                constraints: BoxConstraints(maxWidth: 500),
                                builder: (BuildContext context) {
                                  return PointerInterceptor(
                                      child: Container(
                                          constraints:
                                              BoxConstraints(maxWidth: 500),
                                          color: Colors.white,
                                          child: SingleChildScrollView(
                                              child:
                                                  ListBody(children: <Widget>[
                                            ListTile(
                                              title: Text("Refresh Data",
                                                  style: GoogleFonts.quicksand(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black)),
                                              onTap: () {
                                                reenumerateState();
                                                Navigator.pop(context);
                                              },
                                            ),
                                            ListTile(
                                              title: filter == "Today"
                                                  ? Text(
                                                      "Show All Entries",
                                                      style:
                                                          GoogleFonts.quicksand(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.black),
                                                    )
                                                  : Text(
                                                      "Show Only Today's Entries",
                                                      style:
                                                          GoogleFonts.quicksand(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.black),
                                                    ),
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                setState(() {
                                                  if (filter == "") {
                                                    filter = "Today";
                                                  } else {
                                                    filter = "";
                                                    reenumerateState();
                                                  }
                                                });
                                              },
                                            ),
                                            ListTile(
                                              title: Text("",
                                                  style: GoogleFonts.quicksand(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black)),
                                              onTap: () {},
                                            ),
                                          ]))));
                                });
                          },
                        )
                      ])),
                )),
                Column(
                  children: makeJournalEntry(context, filter),
                )
              ],
            ),
          )),
          body: Stack(children: <Widget>[
            IgnorePointer(
                ignoring: true,
                child: GoogleMap(
                  mapToolbarEnabled: false,
                  polylines: statepolylines,
                  onMapCreated: mapMade,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  onCameraMove: (CameraPosition cp) {
                    center = cp.target;
                    bearing = cp.bearing;
                  },
                  myLocationButtonEnabled: false,
                  padding: const EdgeInsets.only(
                      bottom: 0, top: 0, right: 0, left: 0),
                  mapType: mapType,
                  initialCameraPosition: CameraPosition(
                    target: center,
                    zoom: mapZoom,
                  ),
                  circles: statecircles,
                  onTap: (LatLng latLng) {
                    appendMarker(latLng);
                  },
                  onLongPress: (LatLng latlng) async {
                    LatLng lastPin() {
                      if (statemarkers.isEmpty == true) {
                        return latlng;
                      } else {
                        return statemarkers.last.position;
                      }
                    }

                    mapController.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: lastPin(),
                          zoom: await mapController.getZoomLevel(),
                        ),
                      ),
                    );
                  },
                  markers: statemarkers,
                )),
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
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      spreadRadius: 2.5,
                                      blurRadius: 10,
                                      offset: const Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.light
                                      ? lightMode.withValues(alpha: 1)
                                      : darkMode.withValues(alpha: 1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                child: PointerInterceptor(
                                  child: IconButton(
                                    icon:
                                        const Icon(Icons.my_location_outlined),
                                    color: Colors.white,
                                    onPressed: cameraToLocation,
                                  ),
                                )),
                            Container(
                                decoration: ShapeDecoration(
                                  shadows: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      spreadRadius: 2.5,
                                      blurRadius: 10,
                                      offset: const Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.light
                                      ? lightMode.withValues(alpha: 1)
                                      : darkMode.withValues(alpha: 1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                child: PointerInterceptor(
                                  child: IconButton(
                                      icon: const Icon(Icons.radar),
                                      color: Colors.white,
                                      onPressed: () async {
                                        presentNearBy();
                                      }),
                                )),
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
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      spreadRadius: 2.5,
                                      blurRadius: 10,
                                      offset: const Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.light
                                      ? lightMode.withValues(alpha: 1)
                                      : darkMode.withValues(alpha: 1),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(10),
                                          bottom: Radius.circular(0))),
                                ),
                                child: PointerInterceptor(
                                  child: IconButton(
                                      icon: const Icon(Icons.add),
                                      color: Colors.white,
                                      onPressed: () async {
                                        double currentZoomLevel =
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
                                        //OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
                                      }),
                                )),
                            Container(
                                decoration: ShapeDecoration(
                                  shadows: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      spreadRadius: 2.5,
                                      blurRadius: 10,
                                      offset: const Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                  color: MediaQuery.of(context)
                                              .platformBrightness ==
                                          Brightness.light
                                      ? lightMode.withValues(alpha: 1)
                                      : darkMode.withValues(alpha: 1),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(0),
                                          bottom: Radius.circular(10))),
                                ),
                                child: PointerInterceptor(
                                  child: IconButton(
                                    icon: const Icon(Icons.remove),
                                    color: Colors.white,
                                    onPressed: () async {
                                      double currentZoomLevel =
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
                                      mapZoom =
                                          await mapController.getZoomLevel();
                                      //OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
                                    },
                                  ),
                                )),
                          ],
                        )))),
          ]),
          floatingActionButton: Stack(children: <Widget>[
            Align(
                alignment: Alignment.bottomRight,
                child: PointerInterceptor(
                    child: SizedBox(
                        height: 85.0, width: 85.0, child: actionMenu()))),
          ]),
        ));
  }
}
