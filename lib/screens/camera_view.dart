import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:translator/translator.dart';

import '../Utils/snackbar.dart';
import '../main.dart';

class CameraViewScreen extends StatefulWidget {
  const CameraViewScreen({super.key});

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  late CameraController controller;
  bool _isScanBusy = false;
  late Timer _timer;

  bool isSelected = false;
  bool isloading = false;
  bool isPlaying = false;
  File? imgPath;
  String? mltext;
  String? txtBeforeTranslation;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;
  TextRecognitionScript? textRecognitionScript;

  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();

    controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
      _timer = Timer.periodic(Duration(seconds: 3), (currentTimer) async {
        await controller.startImageStream((CameraImage availableImage) async {
          _scanText(availableImage);
        });
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future _speak(String voiceText) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (voiceText != null) {
      if (voiceText.isNotEmpty) {
        await flutterTts.speak(mltext!);
      }
    }
  }

  Future<String> translate(String? textToBeTranslated,
      {String langToBeTranslated = 'ta'}) async {
    try {
      if (textToBeTranslated == null || textToBeTranslated == '') {
        throw NullThrownError();
      }
      final translator = GoogleTranslator();
      var translation = await translator.translate(textToBeTranslated,
          to: langToBeTranslated);
      print("The translated txt is $translation");
      setState(() {
        mltext = translation.text;
      });

      return translation.text;
    } on Exception catch (e) {
      return 'Sorry, error occurred while translation';
    }
  }

  Future<void> processImage(InputImage image) async {
    try {
      final textRecognizer = TextRecognizer(script: textRecognitionScript!);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(image);
      print('THE TEXT IS ${recognizedText}');
      setState(() {
        mltext = recognizedText.text;
        txtBeforeTranslation = recognizedText.text;
        isloading = false;
        isPlaying = true;
      });
      String translatedText = await translate(mltext);

      await _speak(translatedText.toString());

      // for (TextBlock block in recognizedText.blocks) {
      //   final Rect rect = block.boundingBox;
      //   final List<Point<int>> cornerPoints = block.cornerPoints;
      //   final String text = block.text;
      //   final List<String> languages = block.recognizedLanguages;
      //   // print('the for 1 text is ${text}');     <-----// THIS WILL REPRESENT A BLOCK(I.E PARAGARAPH, SENTENCE) WHICH MIGHT CONTAIN MULTIPLE LINES

      //   for (TextLine line in block.lines) {
      //     //   print('the 2nd for line is ${line.text}');    <------// THIS CONTAINS THE EACH LINE IN A BLOCK . IT WILL ITERATE THROUGH EVERY LINE . block.lines.lenght == "the length of each lines in the block"
      //     // Same getters as TextBlock
      //     for (TextElement element in line.elements) {
      //       // Same getters as TextBlock
      //       // print('the 3rd for element is ${element.text}');     <------// THIS CONTAINS EACH WORD FROM THE SINGLE LINE. line.elements.lenght == "lenght of word in that line"
      //     }
      //   }
      // }
    } on Exception catch (e) {
      print('The error while processing is ${e}');
      showSnackBar(context, e.toString());
    }
  }

  void _scanText(CameraImage availableImage) async {
    try {
      if (_isScanBusy) return;

      _isScanBusy = true;

      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in availableImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
          availableImage.width.toDouble(), availableImage.height.toDouble());

      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(cameras[0].sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(availableImage.format.raw) ??
              InputImageFormat.yuv420;

      final planeData = availableImage.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      final inputImage =
          InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

      print('THE INPUT IMAGE IS ${inputImage}');
      // final textDetector = GoogleMlKit.vision.textDetector();
      // final RecognisedText recognisedText =
      //     await textDetector.processImage(inputImage);
      //do something
      await processImage(inputImage);

      _isScanBusy = false;
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera Preview')),
      body: CameraPreview(
        controller,
      ),
    );
  }
}
