import 'dart:io';
import 'dart:convert';
import 'type.dart';
import 'package:http/http.dart' as http;


class PredictionHelper {
  static const url = "https://centralindia.api.cognitive.microsoft.com/customvision/v3.0/Prediction/c9c03072-ff6b-491f-8966-b20244c08e1e/classify/iterations/Iteration3-hackvsit/image";

  static Future<bool> uploadImgAndPredict(File imgPath, var type) async {
    var response = await http.post(url,
        headers: {
          'Prediction-Key': 'keyhere',
          'Content-Type': 'application/octet-stream'
        },
        body: imgPath.readAsBytesSync());

    var match = (type == Type.trash)? "trash" : "bin";

    if (response.statusCode == 200) {
      var _res = json.decode(response.body);
      for (var x in _res['predictions']) {
        if (x['probability'] >= 0.7 &&
            x['tagName'].toString().contains(match)) {
          return true;
        }
      }
    }
    return false;
  }
}