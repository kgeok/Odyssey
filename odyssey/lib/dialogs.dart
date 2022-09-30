// ignore_for_file: prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings

import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:flutter/services.dart';

var buttonaction1 = "";
var buttonaction2 = "";
var dialogColor;

var dialogHeader =
    GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.white);

var dialogBody =
    GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.white);

void journalDialog(BuildContext context, var caption, var location, var latlng,
    var color, var date, var note) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: color,
          title: Text(caption,
              style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(location,
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)),
                const Text(""),
                Text(latlng.toString(),
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)),
                const Text(""),
                Text(date.toString(),
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)),
                const Text(""),
                Text(note.toString(),
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Full Map",
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)),
              onPressed: () {
                redirectURL("https://www.google.com/maps/search/?api=1&query=" +
                    latlng.replaceAll(", ", "%2C"));
              },
            ),
            TextButton(
              child: Text("Copy",
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: caption + " " + location + ", " + date + " " + note));
              },
            ),
            TextButton(
              child: Text("Dismiss",
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w600,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)),
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
          title: Text(header, style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(body1, style: dialogBody),
                Text(body2, style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonaction1, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonaction2, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}

void complexDialog(BuildContext context, var header, var body1, var body2,
    var body3, var body4, var type) {
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
          title: Text(header, style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(body1, style: dialogBody),
                Text("", style: dialogBody),
                Text(body2, style: dialogBody),
                Text("", style: dialogBody),
                Text(body3, style: dialogBody),
                Text("", style: dialogBody),
                Text(body4, style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonaction1, style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(buttonaction2, style: dialogBody),
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
          title: Text("Odyssey", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Version $version ($release)", style: dialogBody),
                const Text(''),
                Text('With 💖 by Kevin George', style: dialogBody),
                const Text(''),
                Text('http://kgeok.github.io/', style: dialogBody),
                const Text(''),
                Text('Powered by Google Maps, Material Design and Flutter.',
                    style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: Text('Acknowledgements', style: dialogBody),
                onPressed: () {
                  showLicensePage(
                      context: context,
                      useRootNavigator: false,
                      applicationName: "Odyssey",
                      applicationVersion: version,
                      applicationLegalese: "Kevin George");
                }),
            TextButton(
                child: Text('Dismiss', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ]);
    },
  );
}

void helpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          title: Text("Quick Start", style: dialogHeader),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tap the Map to set a Pin', style: dialogBody),
                const Text(''),
                Text(
                    'Tapping the Pin Menu will show options for managing and customizing pins',
                    style: dialogBody),
                const Text(''),
                Text(
                    'Tap Caption before setting a Pin to set the Pin\'s Caption',
                    style: dialogBody),
                const Text(''),
                Text('Tap Color before setting a Pin to set the Pin\'s Color',
                    style: dialogBody),
                const Text(''),
                Text('Long Press the Map to quickly toggle Map Details',
                    style: dialogBody),
                const Text(''),
                Text('Tap the Menu button to open the Journal',
                    style: dialogBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Dismiss', style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    },
  );
}
