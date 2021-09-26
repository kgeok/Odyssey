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

  void _appendMarker(LatLng latLng) {
    markerCounter++;
    setState(() {
      _markers.add(Marker(
        // This marker id can be anything that uniquely identifies each marker.
        markerId: MarkerId(markerCounter.toString()),
        position: latLng,
        infoWindow: InfoWindow(
          title: "Test",
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
  }

  void _clearMarkers() {
    setState(() {
      _markers = {};
    });
  }

  void aboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: lightMode,
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
                child: const Text('Dismiss'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ]);
      },
    );
  }

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
        canvasColor: darkMode,
        textTheme: TextTheme(
            bodyText1: TextStyle(color: Colors.white),
            bodyText2: TextStyle(color: Colors.white)),
      ),
      darkTheme: ThemeData(
        primarySwatch: darkMode,
        fontFamily: 'Quicksand',
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
                title: const Text('Entry'),
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
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 4.0,
          ),
          onTap: (LatLng latLng) {
            print(latLng.latitude.toString());
            print(latLng.longitude.toString());
            _appendMarker(latLng);
          },
          onLongPress: (LatLng latLng) {
            _clearMarkers();
          },
          markers: _markers,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            aboutDialog(context);
          },
          child: const Icon(Icons.push_pin),
        ),
      ),
    );
  }
}
