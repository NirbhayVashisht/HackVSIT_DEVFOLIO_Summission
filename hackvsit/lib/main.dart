import 'dart:async';
import 'dart:io';

import 'type.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'prediction_helper.dart';
import 'firebase_helper.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LatLng _position;
  Set<Circle> _circles;
  var _type;
  BitmapDescriptor _icon;
  var layoutSet = false;

  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(25.392198, 77.500771);

  Set<Marker> _markers = {};
  Set<Marker> _marked = {};
  LatLng _lastMapPosition = _center;
  MapType _currentMapType = MapType.normal;

  void _onMapTypeButtonPressed() async {
    if (layoutSet == false) {
      layoutSet = true;
      // _markers.clear();
      if (_marked.isEmpty) {
        _marked = await FirebaseHelper.getAllCoordinates();
      }
      setState(() {
        _markers = _marked;
      });
    } else {
      layoutSet = false;
      setState(() {
        _markers.clear();
      });
    }
  }

  void _onAddMarkerButtonPressed(var type) async {
    _type = type;

    if (_type == Type.trash) {
      _icon = BitmapDescriptor.defaultMarker;
    } else if (_type == Type.bins) {
      _icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    setState(() {
      // print(_lastMapPosition.toString());
      _markers.add(Marker(
        markerId: MarkerId(_position.toString()),
        position: _position,
        icon: _icon,
      ));
    });

    File img = await _takePicture();
    bool status;
    if(img != null) {
      status = await PredictionHelper.uploadImgAndPredict(img, _type);
    }
    if (status == true) {
      print("Worked!");
      FirebaseHelper.addCordinates(_position, _type);
    } else {
      setState(() {
        _markers.clear();
      });
    }
  }

  void _onCameraMove(CameraPosition position) async {
    _lastMapPosition = _position; //position.target;
    setState(() {
      _circles = Set.from([
        Circle(
          circleId: CircleId('1'),
          center: LatLng(_position.latitude, _position.longitude),
          radius: 5,
          fillColor: Colors.blueAccent,
          strokeColor: Colors.white,
        )
      ]);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('NeoWaste Locator'),
          backgroundColor: Colors.green[700],
        ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 1.0,
              ),
              mapType: _currentMapType,
              markers: _markers,
              onCameraMove: _onCameraMove,
              circles: _circles,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: _onMapTypeButtonPressed,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.map, size: 36.0),
                    ),
                    SizedBox(height: 16.0),
                    // FloatingActionButton(
                    //   onPressed: _onAddMarkerButtonPressed,
                    //   materialTapTargetSize: MaterialTapTargetSize.padded,
                    //   backgroundColor: Colors.green,
                    //   child: const Icon(Icons.add_location, size: 36.0),
                    // ),
                    SizedBox(height: 16.0),
                    FloatingActionButton(
                      onPressed: _getCurrentLocation,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.my_location, size: 36.0),
                    )
                  ],
                ),
              ),
            ),
            SlidingUpPanel(
              // borderRadius: new BorderRadius.circular(30.0),
              maxHeight: 270,
              backdropEnabled: true,
              panel: Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        RaisedButton(
                          color: Colors.green,
                          padding: EdgeInsets.only(
                            left: 18,
                            right: 18,
                            top: 10,
                            bottom: 10,
                          ),
                          autofocus: true,
                          child: Align(
                            // widthFactor: 1.28,
                            alignment: Alignment.center,
                            child: Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 45,
                                ),
                                Icon(
                                  Icons.my_location,
                                  size: 40.0,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "Pin a Bin",
                                  style: TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                FloatingActionButton(
                                  backgroundColor: Colors.lightGreen,
                                  onPressed: () => _onAddMarkerButtonPressed(Type.bins),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  child: const Icon(
                                    Icons.add_location,
                                    size: 36.0,
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                ),
                              ],
                            ),
                          ),
                          onPressed: _getCurrentLocation,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        RaisedButton(
                          color: Colors.green,
                          padding: EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: 10,
                            bottom: 10,
                          ),
                          autofocus: true,
                          child: Align(
                            // widthFactor: 1.28,
                            alignment: Alignment.center,
                            child: Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 20,
                                ),
                                Icon(
                                  Icons.my_location,
                                  size: 40.0,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "Report Garbage",
                                  style: TextStyle(
                                    fontSize: 27,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                FloatingActionButton(
                                  backgroundColor: Colors.lightGreen,
                                  onPressed: () => _onAddMarkerButtonPressed(Type.trash),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  child: const Icon(
                                    Icons.add_location,
                                    size: 36.0,
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                              ],
                            ),
                          ),
                          onPressed: _getCurrentLocation,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File> _takePicture() async {
    File imgPath = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
    );
    return imgPath;
  }

  Future<void> _getCurrentLocation() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.location);
    if (permission == PermissionStatus.denied) {
      await PermissionHandler()
          .requestPermissions([PermissionGroup.locationAlways]);
    }

    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _position = LatLng(position.latitude, position.longitude);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        bearing: 192.8334901395799,
        target: LatLng(_position.latitude, _position.longitude),
        tilt: 59.440717697143555,
        zoom: 19.151926040649414)));
  }
}
