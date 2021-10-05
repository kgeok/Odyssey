// ignore_for_file: prefer_const_constructors, unused_element, avoid_print, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

double version = 0.7;
var pincolor = "Color.Red";
var caption = "";
var captionBuffer;
MapType mapType = MapType.normal;

Map<int, Color> color = {
  50: Color.fromRGBO(0, 105, 148, .6),
  100: Color.fromRGBO(0, 105, 148, .7),
  200: Color.fromRGBO(0, 105, 148, .8),
  300: Color.fromRGBO(0, 105, 148, .9),
  400: Color.fromRGBO(0, 105, 148, 1),
  500: Color.fromRGBO(0, 8, 74, .6),
  600: Color.fromRGBO(0, 8, 74, .7),
  700: Color.fromRGBO(0, 8, 74, .8),
  800: Color.fromRGBO(0, 8, 74, .9),
  900: Color.fromRGBO(0, 8, 74, 1),
};

MaterialColor lightMode = MaterialColor(0xff006694, color);
MaterialColor darkMode = MaterialColor(0xff00084a, color);

int markerCounter = 0;

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  final LatLng _center = const LatLng(41.850033, -87.6500523);

  void appendMarker(LatLng latLng) {
    markerCounter++;
    setState(() {
      _markers.add(
        Marker(
          // This marker id can be anything that uniquely identifies each marker.
          markerId: MarkerId(markerCounter.toString()),
          position: latLng,
          infoWindow: InfoWindow(
            title: caption,
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
    caption = "";
    captionBuffer = "";
  }

  void _clearMarkers() {
    caption = "";
    captionBuffer = "";
    pincolor = "Colors.red";
    setState(() {
      _markers = {};
    });
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

  Widget mapViewControls() {
    return Positioned(
        child: Wrap(
      direction: Axis.vertical,
      spacing: 4,
      children: [
        Container(
          decoration: ShapeDecoration(
            color: darkMode,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          child: IconButton(
            icon: Icon(Icons.map_outlined),
            color: Colors.white,
            onPressed: toggleMapView,
          ),
        ),
        Container(
          decoration: ShapeDecoration(
            color: darkMode,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          child: IconButton(
            icon: Icon(Icons.layers_outlined),
            color: Colors.white,
            onPressed: toggleMapModes,
          ),
        ),
      ],
    ));
  }

  Widget mapZoomControls() {
    return Positioned(
        child: Wrap(
      direction: Axis.vertical,
      children: [
        Container(
          decoration: ShapeDecoration(
            color: darkMode,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          child: IconButton(
            icon: Icon(Icons.add),
            color: Colors.white,
            onPressed: toggleMapView,
          ),
        ),
        Container(
          decoration: ShapeDecoration(
            color: darkMode,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          child: IconButton(
            icon: Icon(Icons.remove),
            color: Colors.white,
            onPressed: toggleMapModes,
          ),
        ),
      ],
    ));
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
                          border: OutlineInputBorder(),
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
                  Text("Version " + version.toString(),
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(''),
                  Text('With 💖 by Kevin George',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(''),
                  Text('http://kgeok.github.io/',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(''),
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
            ),
            PopupMenuDivider(height: 20),
            PopupMenuItem(
              value: 3,
              child: Text(
                "Delete Last Pin",
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
              ),
              onTap: _clearMarkers,
            ),
            PopupMenuDivider(height: 20),
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
            color: darkMode.withOpacity(0.7),
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
            shape: StadiumBorder(
              side: BorderSide(color: Colors.white, width: 0),
            )),
        child: Icon(Icons.push_pin, color: Colors.white),
      ));

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    Positioned(
      top: 300,
      left: 5,
      child: Card(
        elevation: 2,
        child: Container(
          color: Colors.blue,
          width: 40,
          height: 100,
          child: Column(
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    var currentZoomLevel = await controller.getZoomLevel();

                    currentZoomLevel = currentZoomLevel + 2;
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _center,
                          zoom: currentZoomLevel,
                        ),
                      ),
                    );
                  }),
              SizedBox(height: 2),
              IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () async {
                    var currentZoomLevel = await controller.getZoomLevel();
                    currentZoomLevel = currentZoomLevel - 2;
                    if (currentZoomLevel < 0) currentZoomLevel = 0;
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _center,
                          zoom: currentZoomLevel,
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: lightMode,
          fontFamily: 'Quicksand',
          dialogBackgroundColor: lightMode,
          canvasColor: darkMode,
          textTheme: TextTheme(
              bodyText1: TextStyle(color: Colors.white),
              bodyText2: TextStyle(color: Colors.white)),
        ),
        darkTheme: ThemeData(
          primarySwatch: darkMode,
          fontFamily: 'Quicksand',
          dialogBackgroundColor: darkMode,
          canvasColor: lightMode,
          textTheme: TextTheme(
              bodyText1: TextStyle(color: Colors.white),
              bodyText2: TextStyle(color: Colors.white)),
        ),
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
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(),
                  child: Text(
                    'Journal',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Entry',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                  subtitle: Text(
                    'Location',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                  tileColor: Colors.red,
                  onTap: () {
                    // Update the state of the app.
                    // ...
                  },
                ),
              ],
            ),
          ),
          body: GoogleMap(
            onMapCreated: _onMapCreated,
            myLocationButtonEnabled: false,
            padding: EdgeInsets.only(bottom: 0, top: 0, right: 0, left: 0),
            mapType: mapType,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 4.0,
            ),
            onTap: (LatLng latLng) {
              print(latLng.latitude.toString());
              print(latLng.longitude.toString());
              appendMarker(latLng);
            },
            markers: _markers,
          ),
          floatingActionButton: Stack(children: <Widget>[
            Align(
                alignment: Alignment.bottomRight,
                child:
                    SizedBox(height: 85.0, width: 85.0, child: actionMenu())),
            Align(
              alignment: Alignment.bottomLeft, //TODO: topLeft
              child: mapViewControls(),
            )
          ]),
        ));
  }
}
