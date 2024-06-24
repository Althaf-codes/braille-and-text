// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:text_braile_recognition/constants/global_variables.dart';

class ImageViewScreen extends StatelessWidget {
  String imgpath;

  ImageViewScreen({
    Key? key,
    required this.imgpath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GlobalVariables.appbarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                  fit: BoxFit.contain, image: FileImage(File(imgpath)))),
        ),
      ),
    );
  }
}
