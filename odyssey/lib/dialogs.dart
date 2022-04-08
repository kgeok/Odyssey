// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odyssey/theme/custom_theme.dart';

var buttonaction1 = "";
var buttonaction2 = "";
var dialogColor;

void journalDialog(BuildContext context, var caption, var location, var latlng,
    var color, var date) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: color,
          title: Text(caption,
              style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700, color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(location,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const Text(""),
                Text(latlng.toString(),
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const Text(""),
                Text(date.toString(),
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("",
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Dismiss",
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

void simpleDialog(
    BuildContext context, var header, var body1, var body2, var type) {
  switch (type) {
    case "warning":
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor = Colors.orange[800];
      break;

    case "error":
      buttonaction1 = "";
      buttonaction2 = "Dismiss";
      dialogColor = Colors.red[900];
      break;

    case "info":
      buttonaction1 = "";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(0.8)
              : darkMode.withOpacity(0.8);
      break;

    default:
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(0.8)
              : darkMode.withOpacity(0.8);
      break;
  }
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: dialogColor,
          title: Text(header,
              style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700, color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(body1,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                Text(body2,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonaction1,
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonaction2,
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
                Text('Tap Color before setting a Pin to set the Pin\'s Color',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const Text(''),
                Text('Long Press the Map to quickly toggle Map Details',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600, color: Colors.white)),
                const Text(''),
                Text('Tap the Menu button to open the Journal',
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
