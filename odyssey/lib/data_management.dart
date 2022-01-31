// ignore_for_file: avoid_print, unused_local_variable
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

//These are the default value we use for settings
//These will also be the values to fall back on in case DB can't be loaded
//They will also be loaded into DB on init

var defaultCenterLat = 41.850033;
var defaultCenterLng = -87.6500523;
var defaultMapType = MapType.normal;
double defaultBearing = 0;
var defaultPinColor = '0xffff0000';
double defaultMapZoom = 4.0;

class OdysseyDatabase {
  static final OdysseyDatabase instance = OdysseyDatabase._init();

  static Database? _database;

  OdysseyDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('OdysseyDB.db');
    return _database!;
  }

  Future<Database> _initDB(String fpath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fpath);
    print(path);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    db.execute(
        'CREATE TABLE Pins (id INTEGER, caption TEXT, color TEXT, lat FLOAT, lng FLOAT, date TEXT, location TEXT)');
    db.execute(
        'CREATE TABLE Prefs (mapcenterlat FLOAT, mapcenterlng FLOAT, maplayer TEXT, bearing INT(255), pincolor TEXT, mapzoom INT(255))');
    db.rawInsert(
        'INSERT INTO Prefs (mapcenterlat, mapcenterlng, maplayer, bearing, pincolor, mapzoom) VALUES(?, ?, ?, ?, ?, ?)',
        [
          defaultCenterLat,
          defaultCenterLng,
          defaultMapType,
          '$defaultBearing',
          defaultPinColor,
          '$defaultMapZoom'
        ]);

    print("DB Made!");
  }

  Future addPinDB(id, caption, color, latLng, location) async {
    final db = await instance.database;

    caption = caption.toString();
    var colorBuffer = color.toString();
    colorBuffer = colorBuffer.replaceAll("Color(", "");
    colorBuffer = colorBuffer.replaceAll(")", "");
    DateTime currentDate = DateTime.now();
    String date = currentDate.toString().substring(0, 10);
    date.toString();

    //split latlng and make it a two parter float

    var latLngBuffer = latLng.toString();
    latLngBuffer = latLngBuffer.replaceAll("LatLng(", "");
    latLngBuffer = latLngBuffer.replaceAll(")", "");
    var latLngBuffer2 = latLngBuffer.split(", ");
    var lat = double.parse(latLngBuffer2[0].trim());
    var lng = double.parse(latLngBuffer2[1].trim());

    location.toString();

    db.rawInsert(
        'INSERT INTO Pins (id, caption, color, lat, lng, date, location) VALUES(?, ?, ?, ?, ?, ?, ?)',
        ['$id', '$caption', colorBuffer, '$lat', '$lng', date, '$location']);
  }

  Future closeDB() async {
    final db = await instance.database;
    db.close();
  }

  Future initStatefromDB() async {
    //Let's using this function to fill up the map and Journal when booting the app
    //Is using all these variables the way that I am the smartest way to do it?
    //Probably not but I'll figure something out later maybe type type casting is the right way to go
    final db = await instance.database;

    //Load Prefs Data
    var centerBufferlat = await db.query("Prefs", columns: ["mapcenterlat"]);
    var centerBufferlng = await db.query("Prefs", columns: ["mapcenterlng"]);
/*     center = LatLng(double.parse(centerBufferlat[0]["mapcenterlat"].toString()),
        double.parse(centerBufferlng[0]["mapcenterlng"].toString())); */ //Null error on Android

    var bearingBuffer = await db.query("Prefs", columns: ["bearing"]);
    bearing = double.parse(bearingBuffer[0]['bearing'].toString());

    var mapTypeBuffer = await db.query("Prefs", columns: ["maplayer"]);
    //mapType = mapTypeBuffer[0]['maplayer'].toString() as MapType; //Tried casting this one didn't work...

    var mapZoomBuffer = await db.query("Prefs", columns: ["mapzoom"]);
    mapZoom = double.parse(mapZoomBuffer[0]['mapzoom'].toString());

    //Load User Data
    var counterBuffer = await db.query("Pins", columns: ["MAX(id)"]);
    var counter = int.tryParse(counterBuffer[0]['MAX(id)'].toString());
    var colorBuffer = await db.query("Pins", columns: ["color"]);

    counter ??= 0;
    print(counter);

    pinCounter = counter;
    //This part is the star of the show, we are parsing everything from the Pins DB
    //Then by counter we are attempting, one by one to place everything on the map
    for (var i = 0; i <= counter - 1; i++) {
      print("Pin: " + (i + 1).toString());

      //Parse the Pin's Color
      var colorBuffer2 = colorBuffer[i]["color"].toString();
      //colorBuffer2 = colorBuffer2.split('(0x')[1].split(')')[0]; //Depreciated
      //int colorBuffer3 = int.parse(colorBuffer2, radix: 16); //Depreciated
      pincolor = Color(int.parse(colorBuffer2));
      print(pincolor);

      //Parse the Caption
      captionBuffer = await db.query("Pins", columns: ["caption"]);
      caption = captionBuffer[i]["caption"].toString();
      print(caption);

      //Parse the Pin's Lat and Lng
      var locationBufferlat = await db.query("Pins", columns: ["lat"]);
      var locationBufferlng = await db.query("Pins", columns: ["lng"]);
      LatLng latLng = LatLng(
          double.parse(locationBufferlat[i]["lat"].toString()),
          double.parse(locationBufferlng[i]["lng"].toString()));

      print(latLng);

      // const MyApp().appendMarker(latLng);
      //MyApp.instance.appendMarker(latLng);

    }
  }

  Future resetDB() async {
    final db = await instance.database;
    db.delete("Pins");
    db.delete("Prefs");
    db.rawInsert(
        'INSERT INTO Prefs (mapcenter, maplayer, bearing, pincolor, zoom) VALUES(?, ?, ?, ?, ?, ?)',
        [
          defaultCenterLat,
          defaultCenterLng,
          defaultMapType,
          '$defaultBearing',
          defaultPinColor,
          '$defaultMapZoom'
        ]);
  }

  Future deletePinDB(id) async {
    final db = await instance.database;
    db.query("Pins");
    db.execute("DELETE FROM Pins WHERE id = $id");
  }

  Future clearPinsDB() async {
    final db = await instance.database;
    db.delete("Pins");
  }
}
