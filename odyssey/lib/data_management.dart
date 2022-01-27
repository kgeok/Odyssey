// ignore_for_file: avoid_print, unused_local_variable
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:odyssey/main.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

//These are the default value we use for settings

var defaultCenterLat = 41.850033;
var defaultCenterLng = -87.6500523;
var defaultMapType = 'MapType.normal';
var defaultBearing = 0;
var defaultPinColor = '0xffff0000';
var defaultMapZoom = 4;

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
        'INSERT INTO Prefs (mapcenterlat, mapcenterlng, maplayer, bearing, pincolor, zoom) VALUES(?, ?, ?, ?, ?, ?)',
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
    final db = await instance.database;

    //load preferences

    var centerBufferlat = await db.query("Prefs", columns: ["mapcenterlat"]);
    var centerBufferlng = await db.query("Prefs", columns: ["mapcenterlng"]);

    print(centerBufferlat);
    print(centerBufferlng);

    //load user data
    var counterBuffer = await db.query("Pins", columns: ["MAX(id)"]);

    var counter = int.parse(counterBuffer[0]['MAX(id)']
        .toString()); //TODO: Warning causes Execption with no pins

    if (counter == null) {
      print("Fail");
    }

    var colorBuffer = await db.query("Pins", columns: ["color"]);

    print(counter);
    pinCounter = counter;

    for (var i = 0; i <= counter - 1; i++) {
      //Parse the Caption
      captionBuffer = await db.query("Pins", columns: ["caption"]);
      caption = captionBuffer[i]["caption"].toString();
      print(caption);

      //Parse the Pin's Color
      var colorBuffer2 = colorBuffer[i]["color"].toString();
      //colorBuffer2 = colorBuffer2.split('(0x')[1].split(')')[0]; //Depreciated
      //int colorBuffer3 = int.parse(colorBuffer2, radix: 16); //Depreciated
      int colorBuffer3 = int.parse(colorBuffer2);
      pincolor = Color(colorBuffer3);
      print(pincolor);

      //Parse the Pin's Lat and Lng
      var locationBufferlat = await db.query("Pins", columns: ["lat"]);
      var locationBufferlng = await db.query("Pins", columns: ["lng"]);
      var locationBufferlat2 = locationBufferlat[i]["lat"];
      var locationBufferlng2 = locationBufferlng[i]["lng"];

      //   LatLng latLng = LatLng(locationBufferlat, locationBufferlng2);

      print(locationBufferlat2);
      print(locationBufferlng2);

      //appendMarker();

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
