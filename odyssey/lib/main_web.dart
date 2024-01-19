import 'dart:math';
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
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: OdysseyMain()));
}

class OdysseyMain extends StatefulWidget {
  const OdysseyMain({super.key});
  @override
  OdysseyMainState createState() => OdysseyMainState();

  //Debug
  static const OdysseyMain instance = OdysseyMain._init();
  const OdysseyMain._init();
}

GlobalKey<OdysseyMainState> key = GlobalKey();

class OdysseyMainState extends State<OdysseyMain> {
  @override
return null;

}