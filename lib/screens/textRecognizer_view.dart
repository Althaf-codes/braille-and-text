// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:translator/translator.dart';

import '../Utils/painters/text_recognizer_painter.dart';
import 'camera_view_screen.dart';

class TextRecognizerView extends StatefulWidget {
  TextRecognitionScript textRecognitionScript;

  TextRecognizerView({
    Key? key,
    required this.textRecognitionScript,
  }) : super(key: key);

  @override
  State<TextRecognizerView> createState() => _TextRecognizerViewState();
}

class _TextRecognizerViewState extends State<TextRecognizerView> {
  late final TextRecognizer _textRecognizer =
      TextRecognizer(script: widget.textRecognitionScript);
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  late bool _isScanned;
  final translationLang = [
    'Tamil',
    'English',
    'Hindi',
    'French',
    'Chinese',
    'Japanese'
  ];
  Map<String, String> translationLangCode = {
    'Tamil': 'ta',
    'English': 'en',
    'Hindi': 'hi',
    'French': 'fr',
    'Chinese': 'zh',
    'Japanese': 'ja'
  };

  String? afterTranslateLang = 'Tamil';
  @override
  void initState() {
    _isScanned = false;

    super.initState();
  }

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    flutterTts.stop();
    flutterTts.cancelHandler;
    super.dispose();
  }

  ScrollController scrollController = ScrollController();
  FlutterTts flutterTts = FlutterTts();
  // String? mltext;
  String? txtBeforeTranslation;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;
  @override
  Widget build(BuildContext context) {
    // print('THE ISSCANNED IN STARTING IS ${_isScanned}');
    return CameraView(
      title: 'Text Detector',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
    );
  }

  DropdownMenuItem<String> buildMenuItem(String item) {
    return DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ));
  }

  Future _speak(String voiceText) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (voiceText != null) {
      if (voiceText.isNotEmpty) {
        print('ITS COMING INSIDE SPEAK');
        await flutterTts.speak(voiceText).whenComplete(() {
          setState(() {
            _isScanned = false;
            print('the isScanned is ${_isScanned} ');
          });
        });
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
      // setState(() {
      //   mltext = translation.text;
      // });

      return translation.text;
    } on Exception catch (e) {
      return 'Sorry, error occurred while translation';
    }
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final recognizedText = await _textRecognizer.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      // await translate(recognizedText.toString(),
      //         langToBeTranslated: translationLangCode[afterTranslateLang]!)
      //     .then((translatedVal) async {

      // });
      if (_isScanned == false) {
        await _speak(recognizedText.text.toString()).then((value) {
          setState(() {
            _isScanned = true;
          });
        });
      }

      final painter = TextRecognizerPainter(
          recognizedText,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      _text = 'Recognized text:\n\n${recognizedText.text}';
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
