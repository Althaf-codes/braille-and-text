import 'package:image_picker/image_picker.dart';

Future<String> pickImage({required ImageSource source}) async {
  final picker = ImagePicker();
  String path = '';

  try {
    final getImage = await picker.pickImage(source: source);

    if (getImage != null) {
      path = getImage.path;
    } else {
      path = '';
    }
  } catch (e) {
    print("the error is ${e}");
  }

  return path;
}
