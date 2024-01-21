// ignore_for_file: prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables

import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odyssey/theme/custom_theme.dart';

var buttonaction1 = "";
var buttonaction2 = "";
var dialogColor;

var dialogHeader =
    GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.white);

var dialogBody =
    GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: Colors.white);

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
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
      break;

    default:
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
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
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
      break;

    default:
      buttonaction1 = "Cancel";
      buttonaction2 = "OK";
      dialogColor =
          MediaQuery.of(context).platformBrightness == Brightness.light
              ? lightMode.withOpacity(1)
              : darkMode.withOpacity(1);
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

void onboardDialog(BuildContext context, var header, var body1, var body2,
    var body3, var body4) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor:
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? lightMode.withOpacity(1)
                  : darkMode.withOpacity(1),
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
              child: Text("Quick Start", style: dialogBody),
              onPressed: () {
                Navigator.of(context).pop();
                helpDialog(context);
              },
            ),
            TextButton(
              child: Text("OK", style: dialogBody),
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
          backgroundColor:
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? lightMode.withOpacity(1)
                  : darkMode.withOpacity(1),
          title: Text("Quick Start", style: dialogHeader),
          content: SingleChildScrollView(
              child: ListBody(children: [
            Text('Tap anywhere on the map to set a Pin', style: dialogBody),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.menu,
                  color: Colors.white,
                )),
                TextSpan(
                    text:
                        " to open the Journal and see an overview of all your entries",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.push_pin,
                  color: Colors.white,
                )),
                TextSpan(
                    text: " to see customization and more options",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.my_location,
                  color: Colors.white,
                )),
                TextSpan(
                    text:
                        " to move the map to your current location (Requires your current location)",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.radar,
                  color: Colors.white,
                )),
                TextSpan(
                    text:
                        " to open Near By and see places near you (Requires your current location)",
                    style: dialogBody)
              ]),
            ),
            const Text(''),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: "Tap ", style: dialogBody),
                const WidgetSpan(
                    child: Icon(
                  Icons.add,
                  color: Colors.white,
                )),
                const WidgetSpan(
                    child: Icon(
                  Icons.remove,
                  color: Colors.white,
                )),
                TextSpan(
                    text: " to zoom in and out of the map", style: dialogBody)
              ]),
            ),
          ])),
          actions: [
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
