import 'dart:convert';

import 'package:http/http.dart' as http;

class BraileTxtApi {
  Map<String, String> headers = {'Content-Type': 'application/json'};
  Future<String> getBrailleText({required String url}) async {
    try {
      http.Response res = await http.post(
        //Uri.parse('http://192.168.199.145:5000/getbraille'),
        // http://192.168.112.145:5000/getbraille
        Uri.parse('http://192.168.43.233:5000/getbraille'),
        headers: headers,
        body: jsonEncode({'imageUrl': url}),
      );
      print("Response is  ${res.body}");

      final brailetext = res.body;
      // print("Brailetext is  $brailetext");
      return brailetext;
    } catch (e) {
      print('The error is ${e}');
      return 'Failed to translate';
    }
  }

  Future<String> getBrailleFromText({required String text}) async {
    try {
      print("it touched req");
      http.Response res = await http.post(
          Uri.parse('http://192.168.43.233:5000/getTextToBraille'),
          headers: headers,
          body: jsonEncode({'text': text}));
      print("its after req");
      print("Response is  ${res.body.toString()}");
      return res.body.toString();
    } catch (e) {
      print('The error is ${e}');
      return 'Failed to translate';
    }
  }
}
