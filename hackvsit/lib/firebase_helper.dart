import 'dart:convert';
import 'type.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;


class FirebaseHelper {
  static const _url = "url for firebase realtime database";

  static Future<bool> addCordinates(LatLng position, var type) async {
    var match = (type == Type.trash)? 0 : 1;
    var response = await http.post(_url,
        body: json.encode(
            {"type": "${match}" ,
              "latitude":"${position.latitude}",
              "longitude":"${position.longitude}"
            }));
    if (response.statusCode == 200) {
      return true;
    }
  }

  static Future<Set<Marker>> getAllCoordinates() async{

    final Set<Marker> _marked = {};
    BitmapDescriptor _icon;
    final response = await http.get(_url);
    final allCoordinates = json.decode(response.body) as Map<String, dynamic>;

    allCoordinates.forEach((type, points){
      print("type:"+allCoordinates[type]['type']);
      print("latitude:"+points['latitude']);

      if(allCoordinates[type]['type'] == "0") {
        print("Trash");
        _icon = BitmapDescriptor.defaultMarker;
      }else{
        print("Bins");
        _icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      }

      _marked.add(Marker(
          markerId: MarkerId("LatLng("+points['latitude']+points["longitude"]+")"),
          position: LatLng(double.parse(points['latitude']),double.parse(points['longitude'])),
          icon: _icon));

    });

    return _marked;
  }
}