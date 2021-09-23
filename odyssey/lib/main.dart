// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

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

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(41.850033, -87.6500523);

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
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Add your onPressed code here!
          },
          child: const Icon(Icons.push_pin),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
