import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class TamilTranslationApi {
  Future<String> getTamilFileOcr(File filepath) async {
    try {
      var request = http.MultipartRequest(
          "POST", Uri.parse("https://api.ocr.space/parse/image"));
      request.fields.addAll({
        'language': 'tam',
        'isOverlayRequired': 'false',
        'OCREngine': '3',
        // 'scale': '3',
      });
      // request.fields["language"] = 'tam';
      // request.fields["isOverlayRequired"] = 'false';

      // request.fields["OCREngine"] = '3';

      // request.fields["scale"] = 'true';

      var pic = await http.MultipartFile.fromPath("file", filepath.path);
      request.headers.addAll({'apikey': 'e9fdb7c04a88957'});
      request.files.add(pic);

      var response = await request.send();

      // var res = jsonDecode(response.stream.toBytes());
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      print('THE RESPONSE IS $response');
      print('/////////////');
      print('The RESPONSE DATA IS $responseData');
      print('/////////////');
      print('THE DATA IS $responseString');
      return responseString;
    } on Exception catch (e) {
      print('The error is ${e} ');
      return 'No data';
    }
  }

  Future<Map<String, dynamic>> getTamilbyteOcr(File file) async {
    try {
      List<int> imageBytes = file.readAsBytesSync();

      String base64Image = base64Encode(imageBytes);

      print("THE BYTES ARE $base64Image");
      String? mimetype = lookupMimeType(file.path);
      print('THE MIMETYPE IS $mimetype');
      String baseImage = 'data:$mimetype;base64,$base64Image';
      print("the baseImage is $baseImage");
      http.Response res = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        body: {
          'language': 'tam',
          'isOverlayRequired': 'false',
          'OCREngine': '3',
          'base64image': baseImage,
        },
        headers: <String, String>{
          'apikey': 'e9fdb7c04a88957',
        },
      );
      var user = jsonDecode(res.body);
      print(
        'THE DATA IS ${user}',
      );
      return user;
    } on Exception catch (e) {
      print('The ERROR IS $e');
      return {'': ''};
    }
  }
}
