import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../Utils/snackbar.dart';

class PdfApi {
  Future<File> generateCenteredText(
      BuildContext context, Uint8List image) async {
    // final font = GoogleFonts.openSans();
    // // var myFont = pw.Font.ttf();
    // final pdf = pw.Document();
    // // final img = MemoryImage(image) as pw.ImageProvider;
    // final img = pw.MemoryImage(image.buffer.asUint8List());
    // pdf.addPage(pw.Page(build: (pw.Context context) {
    //   return pw.Center(
    //     child: pw.Image(img),
    //   ); // Center
    // }));
    print("image added");

    return saveDocument(
        name: DateTime.now().toString(), bytes: image, context: context);
  }

  Future<File> saveDocument(
      {required String name,
      required List<int> bytes,
      required BuildContext context}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name.jpg');
    await file.writeAsBytes(bytes).then((value) {
      ImageGallerySaver.saveFile(file.path).then((value) {
        showSnackBar(context, "Image saved successfully");
      });
    });

    return file;
  }

  // static Future openFile(File file) async {
  //   final url = file.path;

  //   await OpenFile.open(url);
  // }
}
