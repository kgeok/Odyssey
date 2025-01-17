// ignore_for_file: avoid_print, use_build_context_synchronously, prefer_typing_uninitialized_variables, prefer_interpolation_to_compose_strings, prefer_const_constructors
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/dialogs.dart';
import 'package:odyssey/theme/custom_theme.dart';
import 'package:odyssey/data_management.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:location/location.dart' as prefix;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_webservice/places.dart' as places;

void main() async {
  runApp(const MaterialApp(home: OdysseyMain()));
}

class OdysseyMain extends StatefulWidget {
  const OdysseyMain({Key? key}) : super(key: key);
  @override
  OdysseyMainState createState() => OdysseyMainState();

  //Debug
  static const OdysseyMain instance = OdysseyMain._init();
  const OdysseyMain._init();
}

GlobalKey<OdysseyMainState> key = GlobalKey();
//Variables that we will be using, will try to minimize in the future
const version = "1.4.2";
const release = "Release";
const apikey = "AIzaSyD8TrymPJaJVDXvXja2O6woa7B_-R-fi9w"; //Google Maps API Key
Color pincolor = Color(int.parse(defaultPinColor));
var colorBuffer =
    "FF0000"; //Default Pin Color when Map settings are not initialized
Color pickerColor = Color(
    0xffff0000); //Value is not constant because it is changed with the picker
Color currentColor = Color(
    0xffff0000); //Value is not constant because it is changed with the picker
LatLng center =
    LatLng(defaultCenterLat, defaultCenterLng); //Default center of Map
LatLng currentLocation = center; //Using center as a buffer
MapType mapType = defaultMapType; //Default Map Type
var pinshape = defaultPinShape; //Default Pin shape
double bearing = defaultBearing; //Rotation of Map
double mapZoom = defaultMapZoom; //Zoom of Map
String shape =
    defaultShape; //This variable is used to the BitMapDescriptor exclusively
int pinCounter = 0;
var caption = ""; //Null if not initilized
var captionBuffer; //Temp Buffer for the Caption before it goes into PinData
var note = "";
var noteBuffer; //Temp Buffer for the Note before it goes into PinData
var locationBuffer; //Temp Buffer for the results for reverseGeocoder before it goes into PinData
var addressBuffer; //Temp Buffer for Pin From Address before it goes into geocoder
var currentTheme; //Light or Dark theme
int? catselection;
String svgString =
    ""; //We're just leaving this blank to init it, shapeHandler will return the real value
int onboarding = 0;
var pins =
    []; //Pins is a seperate list from statemarkers, independent from whats used by GMapsController
List<int> journal = [];
var nearbyresults = [];
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class PinData {
  var pinid;
  late var pincaption;
  late var pindate;
  late Color pincolor;
  late LatLng pincoor;
  late var pinlocation;
  late var pinnote;
  late var pinshape;
  late var pinphoto;

  PinData(
      {this.pinid,
      this.pincaption,
      this.pindate,
      this.pinnote,
      this.pinphoto,
      this.pinshape,
      required this.pincolor,
      required this.pincoor,
      required this.pinlocation});
}

class NearByData {
  var id;
  late var name;
  late var rating;
  late LatLng coor;
  late var location;
  late var category;
  late var note;
  late bool state;

  NearByData(
      {required this.name,
      required this.coor,
      required this.location,
      this.note,
      this.category,
      this.id,
      this.rating,
      required this.state});
}

String shapeHandler(shape) {
  pinshape = shape;
  switch (shape) {
    case "circle":
      return svgString = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" stroke-miterlimit="10" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" version="1.1" viewBox="0 0 76 180" width="100%" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<defs/>
<g>
<path d="M32 22L43.97 22L44 149L51 149L37.9156 173.735L25 149L32 149L32 22Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
<path d="M8 35.6558C8 19.0873 21.4315 5.65582 38 5.65582C54.5685 5.65582 68 19.0873 68 35.6558C68 52.2244 54.5685 65.6558 38 65.6558C21.4315 65.6558 8 52.2244 8 35.6558Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
</g>
</svg>
''';

    case "square":
      return svgString = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" stroke-miterlimit="10" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" version="1.1" viewBox="0 0 76 180" width="100%" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:vectornator="http://vectornator.io" xmlns:xlink="http://www.w3.org/1999/xlink">
<defs/>
<g>
<path d="M32 22L43.97 22L44 149L51 149L37.9156 173.735L25 149L32 149L32 22Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
<path d="M8 6L68 6L68 66L8 66L8 6Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
</g>
</svg>

''';
    case "diamond":
      return svgString = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" stroke-miterlimit="10" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" version="1.1" viewBox="0 0 76 180" width="100%" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<defs/>
<g>
<path d="M32 22L43.97 22L44 149L51 149L37.9156 173.735L25 149L32 149L32 22Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
<path d="M38 6L68 36L38 66L8 36L38 6Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
</g>
</svg>

''';

    case "star":
      return svgString = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" stroke-miterlimit="10" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" version="1.1" viewBox="0 0 76 180" width="100%" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<defs/>
<g>
<path d="M32 22L43.97 22L44 149L51 149L37.9156 173.735L25 149L32 149L32 22Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
<path d="M38 3L47.2705 22.7508L68 25.918L53 41.2918L56.541 63L38 52.7508L19.459 63L23 41.2918L8 25.918L28.7295 22.7508L38 3Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
</g>
</svg>
''';

    case "heart":
      return svgString = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" stroke-miterlimit="10" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" version="1.1" viewBox="0 0 76 180" width="100%" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<defs/>
<g>
<path d="M32 22L43.97 22L44 149L51 149L37.9156 173.735L25 149L32 149L32 22Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
<path d="M23.8309 7.0076C22.9785 6.98114 22.2559 7.02616 21.6403 7.10552C21.0246 7.1849 20.4213 7.30577 19.8294 7.46455C19.2374 7.6233 18.5938 7.82628 17.9308 8.11733C17.2678 8.40838 16.7214 8.70134 16.2952 8.96594C15.8689 9.23053 15.4251 9.54206 14.9516 9.91247C14.478 10.2829 13.9939 10.7091 13.5204 11.1854C13.0468 11.6617 12.6085 12.1576 12.206 12.6868C11.8035 13.216 11.3999 13.8716 10.95 14.6125C10.5002 15.3533 10.1243 16.0275 9.84012 16.6361C9.55598 17.2447 9.28275 17.9251 9.02229 18.6924C8.76183 19.4597 8.53439 20.4392 8.32129 21.6299C8.10819 22.8205 8 24.048 8 25.3181C8 26.5881 8.12477 27.9938 8.40892 29.5285C8.69305 31.0631 9.02315 32.3665 9.402 33.4778C9.78085 34.5891 10.4244 36.046 11.3005 37.8188C12.1766 39.5916 13.0019 41.0732 13.7832 42.2903C14.5646 43.5075 15.498 44.8435 16.5872 46.2723C17.6764 47.7011 18.8776 49.1642 20.1799 50.6459C21.4822 52.1277 22.9163 53.6605 24.5027 55.248C26.0891 56.8356 28.1044 58.6861 30.5196 60.8293C32.9348 62.9725 34.7045 64.5115 35.8647 65.464C37.0249 66.4166 37.6851 66.9451 37.8509 66.9981C38.0166 67.051 39.3662 66.0203 41.8524 63.93C44.3386 61.8397 46.7172 59.6962 49.0377 57.5001C51.3581 55.304 53.4982 53.097 55.4635 50.8744C57.4288 48.6518 58.8463 46.9857 59.6987 45.848C60.5511 44.7102 61.3195 43.6098 62.0061 42.5515C62.6928 41.4931 63.3419 40.4051 63.9339 39.3202C64.5258 38.2354 65.0155 37.262 65.3943 36.4153C65.7732 35.5686 66.1033 34.7612 66.3874 33.9674C66.6715 33.1736 66.9392 32.3212 67.176 31.4216C67.4128 30.5219 67.5889 29.5998 67.731 28.6472C67.873 27.6947 67.9702 26.7726 67.9938 25.8729C68.0175 24.9733 67.9717 24.0573 67.877 23.1313C67.7823 22.2052 67.6686 21.4163 67.5265 20.7813C67.3844 20.1462 67.1736 19.4597 66.9131 18.6924C66.6527 17.925 66.3794 17.2447 66.0953 16.6361C65.8112 16.0275 65.4353 15.3533 64.9854 14.6125C64.5355 13.8716 64.0917 13.2036 63.6418 12.6215C63.1919 12.0394 62.7536 11.5435 62.3274 11.1201C61.9012 10.6968 61.4006 10.2317 60.8086 9.78191C60.2166 9.33211 59.6647 8.96325 59.1437 8.67219C58.6228 8.38114 58.0361 8.12699 57.4204 7.88885C56.8048 7.65072 56.1335 7.46012 55.3759 7.30135C54.6182 7.14259 53.8095 7.03405 52.9808 7.0076C52.152 6.98114 51.3157 7.03851 50.4397 7.1708C49.5636 7.30309 48.7494 7.48751 48.0154 7.72566C47.2813 7.96379 46.5185 8.27529 45.7371 8.67219C44.9557 9.06908 44.29 9.48294 43.7217 9.87983C43.1535 10.2767 42.5557 10.7603 41.94 11.3159C41.3244 11.8716 40.4992 12.7302 39.4573 13.8944C38.9364 14.4765 38.4302 15.0422 37.9093 15.6243C37.3055 14.9364 36.7022 14.256 36.0984 13.568C34.8908 12.1922 33.7979 11.1429 32.8271 10.4021C31.8562 9.66119 30.9797 9.06908 30.1983 8.67219C29.4169 8.2753 28.6541 7.96379 27.9201 7.72566C27.186 7.48752 26.5314 7.30927 25.9631 7.20343C25.3948 7.0976 24.6833 7.03406 23.8309 7.0076Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
</g>
</svg>
''';

    default:
      return svgString = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg height="100%" stroke-miterlimit="10" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;" version="1.1" viewBox="0 0 76 180" width="100%" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<defs/>
<g>
<path d="M32 22L43.97 22L44 149L51 149L37.9156 173.735L25 149L32 149L32 22Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
<path d="M8 35.6558C8 19.0873 21.4315 5.65582 38 5.65582C54.5685 5.65582 68 19.0873 68 35.6558C68 52.2244 54.5685 65.6558 38 65.6558C21.4315 65.6558 8 52.2244 8 35.6558Z" fill="#$colorBuffer" fill-rule="evenodd" opacity="1" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"/>
</g>
</svg>''';
  }
}

Future bitmapDescriptorFromSvg(BuildContext context, String shape) async {
  double width = 75;
  double height = 175;
  PictureInfo pictureInfo =
      await vg.loadPicture(SvgStringLoader(shapeHandler(shape)), null);
  ui.Image image =
      await pictureInfo.picture.toImage(width.toInt(), height.toInt());
  ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
      width: width / 2.5, height: height / 2.5);
}

Future<void> redirectURL(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw "Error launching link";
  }
}

void colorToHex(Color color) {
  //Color for Flutter is parsed differently from HTML and CSS HEX Color codes which apparently SVG uses
  colorBuffer = color.value.toRadixString(16).substring(2);
}

class OdysseyMainState extends State<OdysseyMain> {
  late GoogleMapController mapController;
  Set<Marker> statemarkers = {};

  void populateMapfromState() async {
    await OdysseyDatabase.instance.initStatefromDB();
    var pinCounterBuffer =
        pinCounter; //I need to freeze the state of the counter so that it doesn't keep iterating on append
    for (var i = 0; i < pinCounterBuffer; i++) {
      pincolor = pins[i].pincolor;
      colorToHex(pincolor);
      pickerColor = pincolor;
      shape = pins[i].pinshape;
      BitmapDescriptor bitmapDescriptor =
          await bitmapDescriptorFromSvg(context, shape);
      caption = pins[i].pincaption;
      note = pins[i].pinnote;

      setState(() {
        statemarkers.add(
          Marker(
              markerId: MarkerId((i + 1).toString()),
              position: pins[i].pincoor,
              infoWindow: InfoWindow(
                title: caption,
                //  snippet: locationBuffer,
              ),
              icon: bitmapDescriptor),
        );
        journal.add(i - 1);
      });
      center = pins[i]
          .pincoor; //For whatever reason this was the only way that Center sticks after every cycle
      print("Restored Pin: ${i + 1}");
    }
    captionBuffer = "";
    caption = "";

    //print("Center: $center, Bearing: $bearing, Zoom: $mapZoom");

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

  void appendMarker(LatLng latLng) async {
    pinCounter++;
    BitmapDescriptor bitmapDescriptor =
        await bitmapDescriptorFromSvg(context, shape);
    reverseGeocoder(latLng);
    setState(() {
      statemarkers.add(
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
    var pinlocation;
    try {
      List<Placemark> placeMarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      pinlocation = placeMarks;

      locationBuffer =
          "${pinlocation[0].name}: ${pinlocation[0].locality} ${pinlocation[0].administrativeArea} ${pinlocation[0].isoCountryCode}";
    } catch (e) {
      //In case, for whatever reason theres no Internet or the platform can't get a location
      pinlocation = "Location N/A";
      locationBuffer = pinlocation;
    }

    //Adding Entry here...
    DateTime currentDate = DateTime.now();
    String date = currentDate.toString().substring(0, 10);
    date.toString();

    pins.add(PinData(
        pinid: pinCounter,
        pincolor: pincolor,
        pincoor: latLng,
        pindate: date,
        pinnote: note,
        pincaption: caption,
        pinshape: shape,
        pinlocation: locationBuffer.toString()));

    OdysseyDatabase.instance.addPinDB(pinCounter, caption, date, pincolor,
        shape, latLng, locationBuffer, note);

    setState(() {
      journal.add(pinCounter - 1);
    });

    mapZoom = await mapController.getZoomLevel();
    OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);

    caption = "";
    captionBuffer = "";
    note = "";
    noteBuffer = "";
    pinlocation = [];
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

  Widget journalEntry(final caption, final color, final subtitle, var latlng,
      var date, var note, var shape, var id) {
    var target = latlng;
    latlng = latlng.toString();
    latlng = latlng.replaceAll("LatLng(", "");
    latlng = latlng.replaceAll(")", "");
    return Center(
        child: Wrap(
      direction: Axis.vertical,
      spacing: 4,
      children: [
        InkWell(
            splashColor: color,
            highlightColor: color,
            onTap: () {
              journalDialog(context, caption, subtitle, latlng, color, date,
                  note, shape, id);
              mapController
                  .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                target: target,
                bearing: bearing,
                zoom: mapZoom + 2,
              )));
            },
            child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 0.9,
                child: Container(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
                    decoration: ShapeDecoration(
                        shadows: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 5,
                            blurRadius: 7,
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
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 20)),
                          Text(subtitle,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w500,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 18))
                        ]))))),
        const SizedBox(height: 2.5),
      ],
    ));
  }

  //Journal Dialog is long because each of these set of widgets are generated at once for each pin in real-time
  void journalDialog(BuildContext context, var caption, var location,
      var latlng, var color, var date, var note, var shape, var id) {
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
                  if (Platform.isIOS) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            backgroundColor: color,
                            title: Text("Open",
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700,
                                    color: color.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: [
                                  SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      launchUrl(
                                          Uri.parse(
                                              "https://maps.apple.com/?q=$latlng"),
                                          mode: LaunchMode.externalApplication);
                                    },
                                    child: Text('Apple Maps (App)',
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                color.computeLuminance() > 0.5
                                                    ? Colors.black
                                                    : Colors.white)),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      launchUrl(
                                          Uri.parse(
                                              "comgooglemaps://?center=$latlng"),
                                          mode: LaunchMode.externalApplication);
                                    },
                                    child: Text('Google Maps (App)',
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                color.computeLuminance() > 0.5
                                                    ? Colors.black
                                                    : Colors.white)),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      redirectURL(
                                          "https://www.google.com/maps/search/?api=1&query=" +
                                              latlng.replaceAll(", ", "%2C"));
                                    },
                                    child: Text('Google Maps (Web)',
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                color.computeLuminance() > 0.5
                                                    ? Colors.black
                                                    : Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Dismiss',
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
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
                  } else if (Platform.isAndroid) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            backgroundColor: color,
                            title: Text("Open",
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700,
                                    color: color.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: [
                                  SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      redirectURL("geo:$latlng");
                                    },
                                    child: Text('Google Maps (App)',
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                color.computeLuminance() > 0.5
                                                    ? Colors.black
                                                    : Colors.white)),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      redirectURL(
                                          "https://www.google.com/maps/search/?api=1&query=" +
                                              latlng.replaceAll(", ", "%2C"));
                                    },
                                    child: Text('Google Maps (Web)',
                                        style: GoogleFonts.quicksand(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                color.computeLuminance() > 0.5
                                                    ? Colors.black
                                                    : Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Dismiss',
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
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
                },
              ),
              TextButton(
                child: Text("Options",
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    constraints: BoxConstraints(maxWidth: 500),
                    builder: (BuildContext context) {
                      return Container(
                        constraints: BoxConstraints(maxWidth: 500),
                        color: Colors.white,
                        child: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              ListTile(
                                title: Text("Copy Entry",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Clipboard.setData(ClipboardData(
                                      text: caption +
                                          " " +
                                          location +
                                          ", " +
                                          date +
                                          " " +
                                          note));
                                  scaffoldMessengerKey.currentState
                                      ?.showSnackBar(SnackBar(
                                    content: const Text('Copied to Clipboard'),
                                  ));
                                },
                              ),
                              ListTile(
                                title: Text("Copy Address",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Clipboard.setData(
                                      ClipboardData(text: location));
                                  scaffoldMessengerKey.currentState
                                      ?.showSnackBar(SnackBar(
                                    content: const Text('Copied to Clipboard'),
                                  ));
                                },
                              ),
                              ListTile(
                                title: Text("Edit Caption",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                          backgroundColor: color,
                                          title: Text('Enter New Caption',
                                              style: GoogleFonts.quicksand(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      color.computeLuminance() >
                                                              0.5
                                                          ? Colors.black
                                                          : Colors.white)),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                TextField(
                                                    autofocus: true,
                                                    decoration: InputDecoration(
                                                        fillColor:
                                                            Colors.grey[300],
                                                        filled: true,
                                                        border:
                                                            const OutlineInputBorder(),
                                                        hintText: caption),
                                                    onChanged: (value) {
                                                      captionBuffer = value;
                                                    }),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('Cancel',
                                                  style: GoogleFonts.quicksand(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          color.computeLuminance() >
                                                                  0.5
                                                              ? Colors.black
                                                              : Colors.white)),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: Text('OK',
                                                  style: GoogleFonts.quicksand(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          color.computeLuminance() >
                                                                  0.5
                                                              ? Colors.black
                                                              : Colors.white)),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                if (captionBuffer == "") {
                                                  captionBuffer = "";
                                                }
                                                captionBuffer ??= "";
                                                caption = captionBuffer;
                                                captionBuffer = "";
                                                Navigator.pop(context);
                                                OdysseyDatabase.instance
                                                    .updatePinsDB(id, caption,
                                                        note, color, shape);
                                                reenumerateState();
                                              },
                                            )
                                          ]);
                                    },
                                  );
                                },
                              ),
                              ListTile(
                                title: Text("Edit Note",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                          backgroundColor: color,
                                          title: Text('Enter New Note',
                                              style: GoogleFonts.quicksand(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      color.computeLuminance() >
                                                              0.5
                                                          ? Colors.black
                                                          : Colors.white)),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                TextField(
                                                    autofocus: true,
                                                    decoration: InputDecoration(
                                                        fillColor:
                                                            Colors.grey[300],
                                                        filled: true,
                                                        border:
                                                            const OutlineInputBorder(),
                                                        hintText: note),
                                                    onChanged: (value) {
                                                      noteBuffer = value;
                                                    }),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('Cancel',
                                                  style: GoogleFonts.quicksand(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          color.computeLuminance() >
                                                                  0.5
                                                              ? Colors.black
                                                              : Colors.white)),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: Text('OK',
                                                  style: GoogleFonts.quicksand(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          color.computeLuminance() >
                                                                  0.5
                                                              ? Colors.black
                                                              : Colors.white)),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                if (noteBuffer == "") {
                                                  noteBuffer = "";
                                                }
                                                noteBuffer ??= "";
                                                note = noteBuffer;
                                                noteBuffer = "";
                                                Navigator.pop(context);
                                                OdysseyDatabase.instance
                                                    .updatePinsDB(id, caption,
                                                        note, color, shape);
                                                reenumerateState();
                                              },
                                            )
                                          ]);
                                    },
                                  );
                                },
                              ),
                              ListTile(
                                title: Text("Edit Color",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                            backgroundColor: MediaQuery.of(
                                                            context)
                                                        .platformBrightness ==
                                                    Brightness.light
                                                ? lightMode.withOpacity(1)
                                                : darkMode.withOpacity(1),
                                            titlePadding:
                                                const EdgeInsets.all(15.0),
                                            contentPadding:
                                                const EdgeInsets.all(0.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            title: Text('Select Color',
                                                style: dialogHeader),
                                            content: SingleChildScrollView(
                                              child: ColorPicker(
                                                pickerColor: pickerColor,
                                                onColorChanged: (value) {
                                                  setState(() {
                                                    pickerColor = value;
                                                  });
                                                },
                                                pickerAreaHeightPercent: 0.8,
                                                labelTypes: const [],
                                                displayThumbColor: true,
                                                enableAlpha: false,
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('Cancel',
                                                    style: dialogBody),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text('OK',
                                                    style: dialogBody),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  setState(() => currentColor =
                                                      pickerColor);
                                                  setState(() =>
                                                      pincolor = currentColor);
                                                  colorToHex(pincolor);
                                                  print(pincolor);
                                                  OdysseyDatabase.instance
                                                      .updatePinsDB(
                                                          id,
                                                          caption,
                                                          note,
                                                          pincolor,
                                                          shape);
                                                  reenumerateState();
                                                  Navigator.of(context).pop();
                                                },
                                              )
                                            ]);
                                      });
                                },
                              ),
                              ListTile(
                                  title: Text("Edit Shape",
                                      style: GoogleFonts.quicksand(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                            backgroundColor: color,
                                            title: Text("Pin Shape",
                                                style: GoogleFonts.quicksand(
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        color.computeLuminance() >
                                                                0.5
                                                            ? Colors.black
                                                            : Colors.white)),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: [
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      OdysseyDatabase.instance
                                                          .updatePinsDB(
                                                              id,
                                                              caption,
                                                              note,
                                                              color,
                                                              "circle");
                                                      reenumerateState();
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Circle',
                                                        style: GoogleFonts.quicksand(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                color.computeLuminance() >
                                                                        0.5
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white)),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context);

                                                      OdysseyDatabase.instance
                                                          .updatePinsDB(
                                                              id,
                                                              caption,
                                                              note,
                                                              color,
                                                              "square");
                                                      reenumerateState();

                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Square',
                                                        style: GoogleFonts.quicksand(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                color.computeLuminance() >
                                                                        0.5
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white)),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      OdysseyDatabase.instance
                                                          .updatePinsDB(
                                                              id,
                                                              caption,
                                                              note,
                                                              color,
                                                              "diamond");
                                                      reenumerateState();

                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Diamond',
                                                        style: GoogleFonts.quicksand(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                color.computeLuminance() >
                                                                        0.5
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white)),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      OdysseyDatabase.instance
                                                          .updatePinsDB(
                                                              id,
                                                              caption,
                                                              note,
                                                              color,
                                                              "star");
                                                      reenumerateState();

                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Star',
                                                        style: GoogleFonts.quicksand(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                color.computeLuminance() >
                                                                        0.5
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white)),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      OdysseyDatabase.instance
                                                          .updatePinsDB(
                                                              id,
                                                              caption,
                                                              note,
                                                              color,
                                                              "heart");
                                                      reenumerateState();

                                                      Navigator.pop(context);
                                                    },
                                                    child: Text('Heart',
                                                        style: GoogleFonts.quicksand(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                color.computeLuminance() >
                                                                        0.5
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('Dismiss',
                                                    style: GoogleFonts.quicksand(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            color.computeLuminance() >
                                                                    0.5
                                                                ? Colors.black
                                                                : Colors
                                                                    .white)),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              )
                                            ]);
                                      },
                                    );
                                  }),
                              ListTile(
                                title: Text("Delete Entry",
                                    style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[800])),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                          backgroundColor: Colors.orange[800],
                                          title: Text("Delete Entry?",
                                              style: dialogHeader),
                                          content: SingleChildScrollView(
                                            child: ListBody(
                                              children: <Widget>[
                                                Text(
                                                    "Are you sure you want to delete this entry?",
                                                    style: dialogBody),
                                                Text(
                                                    "(This will also delete corresponding Pin)",
                                                    style: dialogBody),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('Cancel',
                                                  style: dialogBody),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child:
                                                  Text('OK', style: dialogBody),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                pins.removeAt(id - 1);
                                                OdysseyDatabase.instance
                                                    .initDBfromState();
                                                reenumerateState();
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
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
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

  List<Widget> makeJournalEntry() {
    return List<Widget>.generate(journal.length, (int index) {
      return journalEntry(
          pins[index].pincaption,
          pins[index].pincolor,
          pins[index].pinlocation,
          pins[index].pincoor,
          pins[index].pindate,
          pins[index].pinnote,
          pins[index].pinshape,
          (index + 1));
    });
  }

  void reenumerateState() {
    caption = "";
    captionBuffer = "";
    noteBuffer = "";
    note = "";
    pinCounter = 0;
    pins.clear();
    setState(() {
      statemarkers = {};
      journal = [];
    });
    //OdysseyDatabase.instance.initStatefromDB();
    populateMapfromState();
  }

  Future<void> appendFromLocation() async {
    bool serviceEnabled;
    prefix.PermissionStatus permissionGranted;
    prefix.Location location = prefix.Location();
    prefix.LocationData currentPosition;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = location.requestService() as bool;

      if (!serviceEnabled) {
        simpleDialog(context, "No Location", "Unable to Determine Location",
            "Check your Location or Privacy Settings", "error");
        return;
      }

      permissionGranted = await location.hasPermission();

      if (permissionGranted == prefix.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != prefix.PermissionStatus.granted) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
        if (permissionGranted == prefix.PermissionStatus.deniedForever) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
      }
    }
    currentPosition = await location.getLocation();
    appendMarker(LatLng(currentPosition.latitude!.toDouble(),
        currentPosition.longitude!.toDouble()));
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    prefix.PermissionStatus permissionGranted;
    prefix.Location location = prefix.Location();
    prefix.LocationData currentPosition;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = location.requestService() as bool;

      if (!serviceEnabled) {
        simpleDialog(context, "No Location", "Unable to Determine Location",
            "Check your Location or Privacy Settings", "error");
        return;
      }

      permissionGranted = await location.hasPermission();

      if (permissionGranted == prefix.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != prefix.PermissionStatus.granted) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
        if (permissionGranted == prefix.PermissionStatus.deniedForever) {
          simpleDialog(context, "No Location", "Unable to Determine Location",
              "Check your Location or Privacy Settings", "error");
          return;
        }
      }
    }

    scaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: const Text('Getting Location...')));

    currentPosition = await location.getLocation();

    currentLocation = LatLng(currentPosition.latitude!.toDouble(),
        currentPosition.longitude!.toDouble());
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void cameraToLocation() async {
    await getCurrentLocation();
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLocation,
          bearing: 0,
          zoom: 12,
        ),
      ),
    );
  }

  void clearStateMarkers() {
    caption = "";
    captionBuffer = "";
    noteBuffer = "";
    note = "";
    pinCounter = 0;
    pins.clear();
    OdysseyDatabase.instance
        .updatePrefsDB(defaultMapZoom, defaultBearing, defaultMapType);
    OdysseyDatabase.instance.clearPinsDB();

    setState(() {
      statemarkers = {};
      journal = [];
    });
  }

  void deleteLastMarker() {
    Marker lastmarker = statemarkers.firstWhere(
        (marker) => marker.markerId.value == (statemarkers.length).toString());
    setState(() {
      statemarkers.remove(lastmarker);
    });
    pins.removeLast();
    journal.removeLast();
    OdysseyDatabase.instance.deletePinDB(pinCounter);
    pinCounter--;
  }

  void toggleMapView() {
    switch (mapType) {
      case MapType.normal:
        setState(() {
          mapType = MapType.hybrid;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      case MapType.hybrid:
        setState(() {
          mapType = MapType.normal;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      case MapType.terrain:
        setState(() {
          mapType = MapType.hybrid;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      case MapType.satellite:
        setState(() {
          mapType = MapType.normal;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      default:
        setState(() {
          mapType = MapType.normal;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
    }
  }

  void toggleMapModes() {
    switch (mapType) {
      case MapType.normal:
        setState(() {
          mapType = MapType.terrain;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      case MapType.satellite:
        setState(() {
          mapType = MapType.hybrid;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      case MapType.terrain:
        setState(() {
          mapType = MapType.normal;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      case MapType.hybrid:
        setState(() {
          mapType = MapType.satellite;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
        break;
      default:
        setState(() {
          mapType = MapType.normal;
          OdysseyDatabase.instance.updatePrefsDB(mapZoom, bearing, mapType);
        });
    }
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
              title: Text('Select Color', style: dialogHeader),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (value) {
                    setState(() {
                      pickerColor = value;
                    });
                  },
                  pickerAreaHeightPercent: 0.8,
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

  void captionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter Caption', style: dialogHeader),
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
                child: Text('Note', style: dialogBody),
                onPressed: () {
                  setState(() {
                    if (captionBuffer == "") {
                      captionBuffer = "";
                    }
                    captionBuffer ??= "";
                    caption = captionBuffer;
                    captionBuffer = "";
                    Navigator.pop(context);
                    noteDialog(context);
                  });
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
                    if (captionBuffer == "") {
                      captionBuffer = "";
                    }
                    captionBuffer ??= "";
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

  void shapeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text("Pin Shape", style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  SimpleDialogOption(
                    onPressed: () {
                      shape = "circle";
                      Navigator.pop(context);
                    },
                    child: Text('Circle', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      shape = "square";
                      Navigator.pop(context);
                    },
                    child: Text('Square', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      shape = "diamond";
                      Navigator.pop(context);
                    },
                    child: Text('Diamond', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      shape = "star";
                      Navigator.pop(context);
                    },
                    child: Text('Star', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      shape = "heart";
                      Navigator.pop(context);
                    },
                    child: Text('Heart', style: dialogBody),
                  ),
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

  void noteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Enter Note', style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                      autofocus: true,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                          fillColor: Colors.grey[300],
                          filled: true,
                          border: const OutlineInputBorder(),
                          hintText: "Note"),
                      onChanged: (value) {
                        setState(() {
                          noteBuffer = value;
                        });
                      }),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Caption', style: dialogBody),
                onPressed: () {
                  setState(() {
                    if (noteBuffer == "") {
                      noteBuffer = "";
                    }
                    noteBuffer ??= "";
                    note = noteBuffer;
                    noteBuffer = "";
                    Navigator.pop(context);
                    captionDialog(context);
                  });
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
                    if (noteBuffer == "") {
                      captionBuffer = "";
                    }
                    if (noteBuffer == null) {
                      captionBuffer = "";
                    }
                    note = noteBuffer;
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
                child: Text('Cancel', style: dialogBody),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: dialogBody),
                onPressed: () {
                  setState(() {
                    if (addressBuffer == "") {
                      addressBuffer = " ";
                    } else {
                      addressBuffer ??= " ";
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

  void settings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text("Settings", style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  SimpleDialogOption(
                    onPressed: () {
                      clearWarning(context);
                    },
                    child: Text('Clear All Pins',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[400])),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      toggleMapView();
                    },
                    child: Text('Toggle Map View', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      toggleMapModes();
                    },
                    child: Text('Toggle Map Details', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      var clipBoard = "";
                      for (var i = 0; i <= (pins.length - 1); i++) {
                        clipBoard = "$clipBoard${pins[i].pincaption}\n";
                        clipBoard = "$clipBoard${pins[i].pinlocation}\n";
                        clipBoard = "$clipBoard${pins[i].pinnote}\n";
                        clipBoard = "$clipBoard${pins[i].pindate}\n";
                        clipBoard = "$clipBoard${pins[i].pincoor}\n";
                        clipBoard =
                            "$clipBoard${((pins[i].pinshape).toString()).toUpperCase()}\n";
                        clipBoard = "$clipBoard\n";
                        clipBoard = "$clipBoard\n";
                      }
                      //print(clipBoard);
                      Clipboard.setData(ClipboardData(text: clipBoard));
                      scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(content: const Text('Copied to Clipboard')));
                    },
                    child: Text('Copy Journal Contents', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      reenumerateState();
                    },
                    child: Text('Refresh Data', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      helpDialog(context);
                    },
                    child: Text('Quick Start', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      aboutDialog(context);
                    },
                    child: Text('About', style: dialogBody),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop();
                      redirectURL(
                          "https://github.com/kgeok/Odyssey/blob/main/PrivacyPolicy.pdf");
                    },
                    child: Text('Privacy Policy', style: dialogBody),
                  ),
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

  void importExport(String type) {
    switch (type) {
      case "import":
        break;

      case "export":
        break;
    }
  }

  void clearWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            backgroundColor: Colors.orange[800],
            title: Text("Clear Pins?", style: dialogHeader),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Are you sure you want to clear all pins?",
                      style: dialogBody),
                  Text("(This will also clear the Journal)", style: dialogBody),
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
                },
              )
            ]);
      },
    );
  }

  void checkConnection() async {
    try {
      final mapsconnection = await InternetAddress.lookup('maps.google.com');
      if (mapsconnection.isNotEmpty &&
          mapsconnection[0].rawAddress.isNotEmpty) {
        print('Connected to Google Maps');
      }
    } on SocketException catch (_) {
      print('Not Connected to Google Maps');
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          duration: Duration(milliseconds: 2000),
          content: const Text('No Internet Connection'),
          action: SnackBarAction(
              label: 'More Info',
              onPressed: () {
                simpleDialog(
                    context,
                    "No Internet Connection",
                    "Please check your device settings",
                    "Some functionality may not be available at this time.",
                    "error");
              })));
    }
  }

  Future startOnboarding() async {
    await Future.delayed(const Duration(
        milliseconds:
            1500)); //It apparently takes 1 second or so for DB to populate State

    if (onboarding == 1) {
      onboardDialog(
          context,
          "Welcome to Odyssey",
          "Give a new emotional meaning to your places.",
          "Keep track of the destinations you traveled with customizable pins on a beautiful map. With the Journal, you can get a glance of your overall pins and keep notes of where you went and where you want to go.",
          "Tap anywhere on the map to set a Pin.",
          "Open the Pin Menu to Customize the next set of Pins.");

      print("Onboarding...");
    } else {
      print("No Onboarding...");
    }
  }

  void mapMade(GoogleMapController controller) {
    mapController = controller;
    populateMapfromState();
    checkConnection();
    startOnboarding();
    //This is only for Pre-Release Versions, This doesn't apply for release versions.
    if (release == "Pre-Release") {
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
          content: const Text('Pre-Release Version'),
          duration: Duration(milliseconds: 3000),
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
    await getCurrentLocation();
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
        constraints: BoxConstraints(maxWidth: 750),
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Center(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 80),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.all(8.0),
                    shrinkWrap: true,
                    children:
                        List<Widget>.generate(categories.length, (int index) {
                      return Padding(
                          padding: EdgeInsets.all(1.5),
                          child: ChoiceChip(
                              label: Text(categories[index],
                                  style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700)),
                              padding: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              backgroundColor: Colors.grey[500],
                              labelStyle:
                                  TextStyle(fontSize: 16, color: Colors.white),
                              selectedColor:
                                  MediaQuery.of(context).platformBrightness ==
                                          Brightness.light
                                      ? lightMode.withOpacity(0.9)
                                      : darkMode.withOpacity(0.9),
                              selected: catselection == index,
                              onSelected: (bool selected) async {
                                setState(() {
                                  catselection = selected ? index : null;
                                  nearbyresults.clear();
                                });
                                print(categories[index]);
                                response =
                                    await placeskey.searchNearbyWithRadius(
                                        places.Location(
                                            lat: currentLocation.latitude,
                                            lng: currentLocation.longitude),
                                        10000,
                                        type:
                                            ((categories[index]).toLowerCase())
                                                .replaceAll(" ", "_"));
                                setState(() {
                                  if (response.results.isNotEmpty) {
                                    for (var i = 0;
                                        i < response.results.length;
                                        i++) {
                                      nearbyresults.add(NearByData(
                                          name: response.results[i].name,
                                          location: response.results[i]
                                                  .formattedAddress ??
                                              "N/A",
                                          rating: response.results[i].rating ??
                                              "N/A",
                                          coor: LatLng(
                                              response.results[i].geometry
                                                      ?.location.lat ??
                                                  0,
                                              response.results[i].geometry
                                                      ?.location.lng ??
                                                  0),
                                          id: i,
                                          state: true));
                                    }
                                  } else {
                                    nearbyresults.add(NearByData(
                                        name: "No Results",
                                        location: "",
                                        rating: "0",
                                        coor: center,
                                        id: 0,
                                        state: false));
                                  }
                                });
                              }));
                    }).toList(),
                  ),
                ),
                SizedBox(height: 1),
                Expanded(
                    child: ListView(
                        scrollDirection: Axis.vertical,
                        padding: EdgeInsets.all(2.0),
                        shrinkWrap: true,
                        children: List<Widget>.generate(nearbyresults.length,
                            (int index) {
                          return ListTile(
                            title: Text(nearbyresults[index].name,
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                "Rating: " +
                                    ((nearbyresults[index].rating.toString() +
                                        " out of 5")),
                                style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.w700)),
                            onTap: () {
                              mapController.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: nearbyresults[index].coor,
                                    zoom: 14,
                                  ),
                                ),
                              );
                            },
                            trailing: nearbyresults[index].state
                                ? IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      caption = nearbyresults[index].name;
                                      note = "Rating: " +
                                          ((nearbyresults[index]
                                                  .rating
                                                  .toString() +
                                              " out of 5"));
                                      appendMarker(nearbyresults[index].coor);
                                      setState(() =>
                                          nearbyresults[index].state = false);
                                      nearbyresults[index].state = false;
                                      scaffoldMessengerKey.currentState
                                          ?.showSnackBar(SnackBar(
                                              content: const Text(
                                                  'Added Journal Entry')));
                                    })
                                : IconButton(
                                    icon: Icon(Icons.check),
                                    onPressed: () {},
                                  ),
                          );
                        })))
              ],
            ));
          });
        });
  }

  //UI of the app
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget actionMenu() => PopupMenuButton<int>(
        tooltip: "Show Pin Menu",
        itemBuilder: (context) => [
              PopupMenuItem(
                  value: 1,
                  child: Text(
                    "Set Color/Shape",
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
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
                  captionDialog(context);
                },
              ),
              PopupMenuItem(
                  value: 3,
                  child: Text(
                    "Pin From Address",
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    addressDialog(context);
                  }),
              PopupMenuItem(
                  value: 4,
                  child: Text(
                    "Pin My Location",
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    appendFromLocation();
                  }),
              const PopupMenuDivider(height: 20),
              PopupMenuItem(
                value: 5,
                onTap: deleteLastMarker,
                child: Text(
                  "Delete Last Pin",
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700, color: Colors.red),
                ),
              ),
              const PopupMenuDivider(height: 20),
              PopupMenuItem(
                value: 6,
                child: Text(
                  "Settings",
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  settings(context);
                },
              ),
            ],
        icon: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: ShapeDecoration(
              color:
                  MediaQuery.of(context).platformBrightness == Brightness.light
                      ? lightMode.withOpacity(0.9)
                      : darkMode.withOpacity(0.9),
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
              shape: CircleBorder()),
          child: const Icon(Icons.push_pin, color: Colors.white),
        ));

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CustomTheme.lightTheme,
        darkTheme: CustomTheme.darkTheme,
        home: ScaffoldMessenger(
            key: scaffoldMessengerKey,
            child: Scaffold(
              appBar: AppBar(
                leading: Builder(builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    enableFeedback: true,
                    tooltip: "Open Journal",
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
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
                        height: 120.0, //140.0 if header cuts off on Android
                        child: DrawerHeader(
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
                  mapToolbarEnabled: false,
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
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.9)
                                        : darkMode.withOpacity(0.9),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                  child: IconButton(
                                    icon:
                                        const Icon(Icons.my_location_outlined),
                                    color: Colors.white,
                                    enableFeedback: true,
                                    onPressed: cameraToLocation,
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
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.9)
                                        : darkMode.withOpacity(0.9),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                  child: IconButton(
                                      icon: const Icon(Icons.radar),
                                      color: Colors.white,
                                      enableFeedback: true,
                                      onPressed: () async {
                                        presentNearBy();
                                      }),
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
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.9)
                                        : darkMode.withOpacity(0.9),
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(10),
                                            bottom: Radius.circular(0))),
                                  ),
                                  child: IconButton(
                                      icon: const Icon(Icons.add),
                                      color: Colors.white,
                                      enableFeedback: true,
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
                                        mapZoom =
                                            await mapController.getZoomLevel();
                                        OdysseyDatabase.instance.updatePrefsDB(
                                            mapZoom, bearing, mapType);
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
                                    color: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.light
                                        ? lightMode.withOpacity(0.9)
                                        : darkMode.withOpacity(0.9),
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(0),
                                            bottom: Radius.circular(10))),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.remove),
                                    color: Colors.white,
                                    enableFeedback: true,
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
                                      mapZoom =
                                          await mapController.getZoomLevel();
                                      OdysseyDatabase.instance.updatePrefsDB(
                                          mapZoom, bearing, mapType);
                                    },
                                  ),
                                ),
                              ],
                            )))),
              ]),
              floatingActionButton: Stack(children: <Widget>[
                Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                        height: 85.0, width: 85.0, child: actionMenu())),
              ]),
            )));
  }
}
