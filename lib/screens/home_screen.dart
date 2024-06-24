import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:text_braile_recognition/Utils/image_picker.dart';
import 'package:text_braile_recognition/Utils/snackbar.dart';
import 'package:text_braile_recognition/Utils/widgets/card.dart';
import 'package:text_braile_recognition/api/braille_text_api.dart';
import 'package:text_braile_recognition/api/tamil_translation_api.dart';
import 'package:text_braile_recognition/constants/global_variables.dart';
import 'package:text_braile_recognition/screens/textRecognizer_view.dart';
import 'package:text_braile_recognition/screens/text_to_braille.dart';
import 'package:translator/translator.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

import '../api/pdfapi.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSelected = false;
  bool isloading = false;
  bool isPlaying = false;
  File? imgPath;
  String downloadUrl = '';
  String? mltext;
  String? txtBeforeTranslation;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;

  Map<String, TextRecognitionScript> textRecognitionMap = {
    'Latin': TextRecognitionScript.latin,
    'Devanagiri': TextRecognitionScript.devanagiri,
    'Chinese': TextRecognitionScript.chinese,
    'Japanese': TextRecognitionScript.japanese
  };
  TextRecognitionScript? textRecognitionScript;
  final langToBeProcessed = ['Latin', 'Devanagiri', 'Chinese', 'Japanese'];

  final translationLang = [
    'Tamil',
    'English',
    'Hindi',
    'French',
    'Chinese',
    'Japanese'
  ];

  String? afterTranslateLang = 'Tamil';
  String? extractionLang = 'Latin';

  Map<String, String> translationLangCode = {
    'Tamil': 'ta',
    'English': 'en',
    'Hindi': 'hi',
    'French': 'fr',
    'Chinese': 'zh',
    'Japanese': 'ja'
  };
  Map<String, String> extractionLangCode = {
    'Afrikaans': 'af',
    'Albanian': 'sq',
    'Catalan': 'ca',
    'Chinese': 'zh',
    'Croatian': 'hr',
    'Czech': 'cs',
    'Danish': 'da',
    'Dutch': 'nl',
    'English': 'en',
    'Estonian': 'et',
    'Filipino': '',
    'Finnish': 'fi',
    'French': 'fr',
    'German': 'de',
    'Hindi': 'hi',
    'Hungarian': 'hu',
    'Icelandic': 'is',
    'Indonesian': 'id',
    'Italian': 'it',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Latvian': 'lv',
    'Lithuanian': 'lt',
    'Malay': 'ms',
    'Marathi': 'mr',
    'Nepali': 'ne',
    'Norwegian': 'no',
    'Polish': 'pl',
    'Portuguese': 'pt',
    'Romanian': 'ro',
    'Serbian': 'sr',
    'Slovak': 'sk',
    'Slovenian': 'sl',
    'Spanish': 'es',
    'Swedish': 'sv',
    'Turkish': 'tr',
    'Vietnamese': 'vi',
  };
  List<FileSystemEntity> _allimages = [];
  WidgetsToImageController wcontroller = WidgetsToImageController();
  PdfApi pdfApi = PdfApi();

  TamilTranslationApi tamilTranslationApi = TamilTranslationApi();
  BraileTxtApi braileTxtApi = BraileTxtApi();
  UploadTask? uploadTask;
  Future<String> uploadBrailleImg() async {
    try {
      final storagereference = FirebaseStorage.instance.ref();

      final path = 'files/${imgPath!.path.split('/').last}';
      final ref = storagereference.child(path);
      uploadTask = ref.putFile(imgPath!);
      final snapshot = await uploadTask!.whenComplete(() {});
      downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {});
      print("THE URL IS  ${downloadUrl}");
      return downloadUrl;
    } on FirebaseException catch (e) {
      print("The FIREBASE ERROR IS ${e.message}");
      return 'error';
    }
  }

  void getStatus(String ext) async {
    final status = await Permission.storage.request();
    Directory? directory = await getApplicationDocumentsDirectory();

    if (status.isDenied) {
      Permission.storage.request();
      print("Permission denied");
    }

    if (status.isGranted) {
      print("Permission Granted");
      // final directory = "${directory.path}";

      if (directory.existsSync()) {
        final items = directory.listSync();
        print(items.toString());

        if (ext == ".jpg") {
          _allimages =
              items.where((element) => element.path.endsWith(".jpg")).toList();
          print("THE _ALLIMAGES  IS $_allimages");
          print("THE _ALLIMAGES LEN  IS ${_allimages.length}");

          setState(() {});
        } else {
          print("NO DIRECTORY");
        }
      }
    }
  }

  @override
  void initState() {
    // getStatus(".jpg");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('the mltxt is $mltext');
    ScrollController scrollController = ScrollController();
    FlutterTts flutterTts = FlutterTts();

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
          print("its not coming  in translate");

          throw NullThrownError();
        }
        print("its coming in translate");
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
        final textRecognizer = TextRecognizer(
            script: textRecognitionScript ?? TextRecognitionScript.latin);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(image);

        setState(() {
          // mltext = recognizedText.text;
          txtBeforeTranslation = recognizedText.text;
          isloading = false;
          isPlaying = true;
        });
        String translatedText = await translate(txtBeforeTranslation);

        await _speak(translatedText.toString());
      } on Exception catch (e) {
        print('The error while processing is ${e}');
        showSnackBar(context, e.toString());
      }
    }

    print('txtbeforetranslation in braille is $txtBeforeTranslation');
    return Scaffold(
      backgroundColor: GlobalVariables.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Text_Braille',
          style: TextStyle(color: GlobalVariables.whiteColor),
        ),
        backgroundColor: GlobalVariables.appbarColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: isSelected
                ? Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: GlobalVariables.whiteColor),
                        // borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomRight,
                            colors: [
                              GlobalVariables.card1Color,
                              //  Color.fromARGB(255, 22, 100, 164),
                              GlobalVariables.card3Color
                            ])),
                    child: Center(
                      child: IconButton(
                          onPressed: () {
                            setState(() {
                              isSelected = !isSelected;
                              isloading = false;
                              mltext = null;
                              txtBeforeTranslation = null;
                              flutterTts.pause();
                              flutterTts.stop();
                              isPlaying = false;
                            });
                          },
                          icon: Icon(Icons.delete_outline)),
                    ))
                : Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: GlobalVariables.whiteColor),
                        // borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomRight,
                            colors: [
                              GlobalVariables.card1Color.withOpacity(0.2),
                              //  Color.fromARGB(255, 22, 100, 164),
                              GlobalVariables.card3Color.withOpacity(0.2)
                            ])),
                    child: Center(
                      child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.delete_outline,
                            color: GlobalVariables.lightwhiteColor,
                          )),
                    )),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: GlobalVariables.bottombarColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 10,
              ),
              !isSelected
                  ? Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      decoration: BoxDecoration(
                          border: Border.all(color: GlobalVariables.whiteColor),
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomRight,
                              colors: [
                                GlobalVariables.card1Color,
                                //  Color.fromARGB(255, 22, 100, 164),
                                GlobalVariables.card3Color
                              ])),
                      child: FloatingActionButton.extended(
                        heroTag: 'PickFab',
                        onPressed: () async {
                          await pickImage(source: ImageSource.gallery)
                              .then((value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                isSelected = !isSelected;
                                imgPath = File(value);
                              });
                            }
                          });
                        },
                        tooltip: 'Pick Image',
                        icon: const Icon(
                          Icons.photo_album_outlined,
                        ),
                        label: const Text(
                          "Pick",
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    )
                  : Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      decoration: BoxDecoration(
                          border: Border.all(color: GlobalVariables.whiteColor),
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomRight,
                              colors: [
                                GlobalVariables.card1Color
                                    .withOpacity(0.7), //0.6
                                //  Color.fromARGB(255, 22, 100, 164),
                                GlobalVariables.card3Color
                                    .withOpacity(0.3) //0.6
                              ])),
                      child: FloatingActionButton.extended(
                        heroTag: 'PickFab2',
                        onPressed: () {},
                        tooltip: 'Pick Image',
                        icon: const Icon(
                          Icons.photo_album_outlined,
                        ),
                        label: const Text(
                          "Pick",
                          style:
                              TextStyle(color: GlobalVariables.lightwhiteColor),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
              SizedBox(
                width: 8,
              ),
              isSelected
                  ? Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: GlobalVariables.whiteColor),
                          // borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomRight,
                              colors: [
                                GlobalVariables.card1Color,
                                //  Color.fromARGB(255, 22, 100, 164),
                                GlobalVariables.card3Color
                              ])),
                      child: FloatingActionButton(
                          heroTag: 'MainFab',
                          backgroundColor: Colors.transparent,
                          onPressed: () {
                            if (isPlaying) {
                              flutterTts.pause();
                              setState(() {
                                isPlaying = false;
                              });
                            } else {
                              flutterTts.speak(mltext!);
                              setState(() {
                                isPlaying = true;
                              });
                            }
                          },
                          child:
                              Icon(isPlaying ? Icons.pause : Icons.play_arrow)),
                    )
                  : Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: GlobalVariables.whiteColor),
                          // borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomRight,
                              colors: [
                                GlobalVariables.card1Color
                                    .withOpacity(0.7), //0.6
                                //  Color.fromARGB(255, 22, 100, 164),
                                GlobalVariables.card3Color
                                    .withOpacity(0.3) //0.6
                              ])),
                      child: FloatingActionButton(
                          heroTag: 'ScanFab',
                          backgroundColor: Colors.transparent,
                          onPressed: () {
                            // flutterTts.speak(mltext!);
                            // setState(() {
                            //   isPlaying = true;
                            // });
                          },
                          child: Icon(
                            Icons.play_arrow,
                            color: GlobalVariables.lightwhiteColor,
                          )),
                    ),
              SizedBox(
                width: 8,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.3,
                decoration: BoxDecoration(
                    border: Border.all(color: GlobalVariables.whiteColor),
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomRight,
                        colors: [
                          GlobalVariables.card1Color,
                          //  Color.fromARGB(255, 22, 100, 164),
                          GlobalVariables.card3Color
                        ])),
                child: FloatingActionButton.extended(
                  icon: Icon(Icons.photo_camera_outlined),
                  backgroundColor: Colors.transparent,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TextRecognizerView(
                                  textRecognitionScript:
                                      textRecognitionScript ??
                                          TextRecognitionScript.latin,
                                  // translationLang: afterTranslateLang!,
                                )));
                  },
                  label: Text('Scan'),
                ),
              ),
              SizedBox(
                width: 2,
              )
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          getStatus('.jpg');
        },
        child: SafeArea(
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            scrollDirection: Axis.vertical,
            controller: scrollController,
            child: Column(
              children: [
                isSelected
                    ? Center(
                        child: Image.file(
                          imgPath!,
                          height: 300,
                          width: 300,
                        ),
                      )
                    : Container(),
                SizedBox(
                  height: 30,
                ),
                isloading
                    ? Center(
                        child: CircularProgressIndicator(
                        color: Colors.blue,
                      ))
                    : txtBeforeTranslation != null
                        ? Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 12.0, top: 8),
                                  child: Text(
                                    'Before Translation :',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: GlobalVariables
                                            .dropdownheadingColor),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: EdgeInsets.only(
                                      left: 8, right: 8, top: 12, bottom: 12),
                                  decoration: BoxDecoration(
                                      color: isloading
                                          ? Colors.grey[400]
                                          : GlobalVariables.whiteColor,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    txtBeforeTranslation ?? '',
                                    maxLines: 100,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                        // shape: BoxShape.circle,
                                        border: Border.all(
                                            color: GlobalVariables.whiteColor),
                                        borderRadius: BorderRadius.circular(25),
                                        gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              GlobalVariables.card1Color,
                                              //  Color.fromARGB(255, 22, 100, 164),
                                              GlobalVariables.card3Color
                                            ])),
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            shape: StadiumBorder(),
                                            elevation: 0,
                                            backgroundColor:
                                                Colors.transparent),
                                        onPressed: () async {
                                          // if (isPlaying) {
                                          //   await flutterTts.pause();
                                          //   await flutterTts.stop();
                                          //   setState(() {
                                          //     isPlaying = false;
                                          //   });
                                          // }
                                          // if (isPlaying == false) {
                                          //   setState(() {
                                          //     isPlaying = true;
                                          //   });
                                          //   print("its playing 1st is $isPlaying");
                                          //   await flutterTts
                                          //       .speak(
                                          //           txtBeforeTranslation.toString())
                                          //       .whenComplete(() {
                                          //     setState(() {
                                          //       isPlaying = false;
                                          //     });
                                          //   });
                                          //   print("its playing 2nd is $isPlaying");
                                          // }

                                          if (isPlaying) {
                                            // flutterTts.pause();
                                            flutterTts.stop();
                                            setState(() {
                                              isPlaying = false;
                                            });
                                          } else {
                                            flutterTts
                                                .speak(txtBeforeTranslation!);
                                            setState(() {
                                              isPlaying = true;
                                            });
                                          }
                                        },
                                        child: Text(isPlaying == true
                                            ? 'Pause'
                                            : 'Play')),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
                mltext != null
                    ? Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 12.0, top: 8),
                              child: Text(
                                'After Translation :',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color:
                                        GlobalVariables.dropdownheadingColor),
                              ),
                            ),
                          ),
                          WidgetsToImage(
                            controller: wcontroller,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: 8, right: 8, top: 12, bottom: 12),
                                decoration: BoxDecoration(
                                    color: isloading
                                        ? Colors.grey[400]
                                        : GlobalVariables.whiteColor,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                  mltext ?? '',
                                  maxLines: 100,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12.0, top: 8, bottom: 8),
                              child: Text(
                                'Select language after translation :',
                                style: TextStyle(
                                    color: GlobalVariables.dropdownheadingColor,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            alignment: Alignment.center,
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.90,
                            decoration: BoxDecoration(
                                // shape: BoxShape.circle,
                                border: Border.all(
                                    color: GlobalVariables.dropdownborderColor),
                                borderRadius: BorderRadius.circular(25),
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      GlobalVariables.card1Color,
                                      //  Color.fromARGB(255, 22, 100, 164),
                                      GlobalVariables.card3Color
                                    ])),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                underline:
                                    Divider(color: GlobalVariables.whiteColor),
                                elevation: 0,
                                value: afterTranslateLang,
                                iconSize: 20,
                                icon: Icon(
                                  Icons.arrow_drop_down_circle_outlined,
                                  color: GlobalVariables.whiteColor,
                                ),
                                items:
                                    translationLang.map(buildMenuItem).toList(),
                                onChanged: (newValue) async {
                                  setState(() {
                                    isPlaying = false;
                                  });
                                  print("the is Playing is $isPlaying");
                                  await translate(txtBeforeTranslation,
                                      langToBeTranslated:
                                          translationLangCode[newValue]
                                              .toString());
                                  await flutterTts
                                      .speak(mltext.toString())
                                      .whenComplete(() {
                                    setState(() {
                                      isPlaying = false;
                                    });
                                  });
                                  setState(() {
                                    afterTranslateLang = newValue;
                                    isPlaying = true;
                                  });
                                  print("the is Playing is $isPlaying");
                                },
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                    // shape: BoxShape.circle,
                                    border: Border.all(
                                        color: GlobalVariables.whiteColor),
                                    borderRadius: BorderRadius.circular(25),
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          GlobalVariables.card1Color,
                                          //  Color.fromARGB(255, 22, 100, 164),
                                          GlobalVariables.card3Color
                                        ])),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        shape: StadiumBorder(),
                                        backgroundColor: Colors.transparent),
                                    onPressed: () async {
                                      // if (isPlaying) {
                                      //   flutterTts.pause();
                                      //   flutterTts.stop();
                                      //   setState(() {
                                      //     isPlaying = false;
                                      //   });
                                      // }
                                      // if (isPlaying == false) {
                                      //   setState(() {
                                      //     isPlaying = true;
                                      //   });

                                      //   await flutterTts
                                      //       .speak(mltext.toString())
                                      //       .whenComplete(() {
                                      //     setState(() {
                                      //       isPlaying = false;
                                      //     });
                                      //   });
                                      // }
                                      if (isPlaying) {
                                        flutterTts.pause();
                                        // flutterTts.stop();
                                        setState(() {
                                          isPlaying = false;
                                        });
                                      } else {
                                        flutterTts.speak(mltext!);
                                        setState(() {
                                          isPlaying = true;
                                        });
                                      }
                                    },
                                    child: Text(isPlaying ? 'Pause' : 'Play')),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                    // shape: BoxShape.circle,
                                    border: Border.all(
                                        color: GlobalVariables.whiteColor),
                                    borderRadius: BorderRadius.circular(25),
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          GlobalVariables.card1Color,
                                          //  Color.fromARGB(255, 22, 100, 164),
                                          GlobalVariables.card3Color
                                        ])),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        shape: StadiumBorder(),
                                        backgroundColor: Colors.transparent),
                                    onPressed: () async {
                                      final img = await wcontroller.capture();
                                      // MemoryImage(img!);
                                      final file = await pdfApi
                                          .generateCenteredText(context, img!);
                                      print("THE FILE IS ${file.path}");
                                    },
                                    child: Text('Save Image')),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(),
                Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Language To Be Processed :',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: GlobalVariables.dropdownheadingColor),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      alignment: Alignment.center,
                      height: 50,
                      width: MediaQuery.of(context).size.width * 0.90,
                      decoration: BoxDecoration(
                          // shape: BoxShape.circle,
                          border: Border.all(
                              color: GlobalVariables.dropdownborderColor),
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomRight,
                              colors: [
                                GlobalVariables.card1Color,
                                //  Color.fromARGB(255, 22, 100, 164),
                                GlobalVariables.card3Color
                              ])),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: Divider(color: GlobalVariables.whiteColor),
                          elevation: 0,
                          value: extractionLang,
                          iconSize: 20,
                          icon: Icon(
                            Icons.arrow_drop_down_circle_outlined,
                            color: GlobalVariables.whiteColor,
                          ),
                          items: langToBeProcessed.map(buildMenuItem).toList(),
                          onChanged: (newValue) async {
                            setState(() {
                              textRecognitionScript =
                                  textRecognitionMap[newValue];
                              extractionLang = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                // !isSelected
                //     ? Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor: Colors.blue[900]),
                //               onPressed: () async {
                //                 await pickImage(source: ImageSource.gallery)
                //                     .then((value) {
                //                   if (value.isNotEmpty) {
                //                     setState(() {
                //                       isSelected = !isSelected;
                //                       imgPath = File(value);
                //                     });
                //                   }
                //                 });
                //               },
                //               child: Text('Pick Image')),
                //         ),
                //       )
                //     : Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor:
                //                       Colors.blue[900]!.withOpacity(0.5)),
                //               onPressed: () {},
                //               child: Text('Pick Image')),
                //         ),
                //       ),
                // isSelected
                //     ? Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor: Colors.blue[900]),
                //               onPressed: () {
                //                 setState(() {
                //                   isSelected = !isSelected;
                //                   isloading = false;
                //                   mltext = null;
                //                   txtBeforeTranslation = null;
                //                   flutterTts.pause();
                //                   flutterTts.stop();
                //                   isPlaying = false;
                //                 });
                //               },
                //               child: Text('Delete')),
                //         ),
                //       )
                //     : Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor:
                //                       Colors.blue[900]!.withOpacity(0.5)),
                //               onPressed: () {},
                //               child: Text('Delete')),
                //         ),
                //       ),
                // isSelected
                //     ? Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor: Colors.blue[900]),
                //               onPressed: () {
                //                 isloading = true;
                //                 print('The img path is $imgPath');
                //                 processImage(InputImage.fromFile(imgPath!));
                //               },
                //               child: Text('Process')),
                //         ),
                //       )
                //     : Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor:
                //                       Colors.blue[900]!.withOpacity(0.5)),
                //               onPressed: () {},
                //               child: Text('Process')),
                //         ),
                //       ),
                // isSelected
                //     ? Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor: Colors.blue[900]),
                //               onPressed: () async {
                //                 setState(() {
                //                   isloading = true;
                //                 });

                //                 Map<String, dynamic> tamiltxt =
                //                     await tamilTranslationApi
                //                         .getTamilbyteOcr(imgPath!)
                //                         .then((value) {
                //                   if (value.isNotEmpty) {
                //                     setState(() {
                //                       isloading = false;
                //                       txtBeforeTranslation =
                //                           value['ParsedResults'][0]["ParsedText"]
                //                               .toString();
                //                     });
                //                   } else {}
                //                   print('THE LOADING VALUE IS $isloading');

                //                   return value;
                //                 }).whenComplete(() async {
                //                   setState(() {
                //                     isloading = false;
                //                     isPlaying = true;
                //                   });
                //                   print('THE LOADING VALUE IS $isloading');
                //                 });
                //                 String translatedText =
                //                     await translate(txtBeforeTranslation);

                //                 await _speak(translatedText.toString());
                //               },
                //               child: Text('Process Tamil Image')),
                //         ),
                //       )
                //     : Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor:
                //                       Colors.blue[900]!.withOpacity(0.5)),
                //               onPressed: () {},
                //               child: Text('Process Tamil Image')),
                //         ),
                //       ),
                // isSelected
                //     ? Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor: Colors.blue[900]),
                //               onPressed: () async {
                //                 setState(() {
                //                   isloading = true;
                //                 });

                //                 uploadBrailleImg().then((url) async {
                //                   if (url != 'error') {
                //                     print('The Url Val is ${url}');
                //                     final brailetxt = await braileTxtApi
                //                         .getBrailleText(url: url);
                //                     print("the received val is ${brailetxt}");

                //                     setState(() {
                //                       txtBeforeTranslation = brailetxt.toString();
                //                       isPlaying = true;
                //                       isloading = false;
                //                     });
                //                     print(
                //                         'txtbeforetranslation in braille is $txtBeforeTranslation');

                //                     String translatedText =
                //                         await translate(brailetxt.toString());

                //                     await _speak(translatedText.toString());
                //                   } else {
                //                     txtBeforeTranslation = 'Failed to translate';
                //                     setState(() {});
                //                     String translatedText =
                //                         await translate(txtBeforeTranslation);

                //                     await _speak(translatedText.toString());
                //                   }
                //                 });
                //               },
                //               child: Text('Process Braille Image')),
                //         ),
                //       )
                //     : Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor:
                //                       Colors.blue[900]!.withOpacity(0.5)),
                //               onPressed: () {},
                //               child: Text('Process Braille Image')),
                //         ),
                //       ),
                // isPlaying
                //     ? Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor: Colors.blue[900]),
                //               onPressed: () {
                //                 flutterTts.pause();
                //                 setState(() {
                //                   isPlaying = false;
                //                 });
                //               },
                //               child: Text('Pause')),
                //         ),
                //       )
                //     : Padding(
                //         padding: const EdgeInsets.all(5.0),
                //         child: Center(
                //           child: ElevatedButton(
                //               style: ElevatedButton.styleFrom(
                //                   shape: StadiumBorder(),
                //                   backgroundColor: !isSelected
                //                       ? Colors.blue[900]!.withOpacity(0.5)
                //                       : mltext == null
                //                           ? Colors.blue[900]!.withOpacity(0.5)
                //                           : Colors.blue[900]),
                //               onPressed: () {
                //                 flutterTts.speak(mltext!);
                //                 setState(() {
                //                   isPlaying = true;
                //                 });
                //               },
                //               child: Text('Play')),
                //         ),
                //       ),
                // SizedBox(
                //   height: 30,
                // ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isSelected
                          ? mycard(context, ontap: () {
                              setState(() {
                                isloading = true;
                              });
                              print('The img path is $imgPath');
                              processImage(InputImage.fromFile(imgPath!));
                            }, text: 'Process')
                          : myFakeCard(context, text: 'Process'),
                      isSelected
                          ? mycard(context, ontap: () async {
                              setState(() {
                                isloading = true;
                              });

                              Map<String, dynamic> tamiltxt =
                                  await tamilTranslationApi
                                      .getTamilbyteOcr(imgPath!)
                                      .then((value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    isloading = false;
                                    txtBeforeTranslation =
                                        value['ParsedResults'][0]["ParsedText"]
                                            .toString();
                                  });
                                } else {}
                                print('THE LOADING VALUE IS $isloading');

                                return value;
                              }).whenComplete(() async {
                                setState(() {
                                  isloading = false;
                                  isPlaying = true;
                                });
                                print('THE LOADING VALUE IS $isloading');
                              });
                              String translatedText =
                                  await translate(txtBeforeTranslation);

                              await _speak(translatedText.toString());
                            }, text: 'Process Tamil Image')
                          : myFakeCard(context, text: 'Process Tamil Image')
                    ],
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: isSelected
                            ? mycard(context, ontap: () async {
                                setState(() {
                                  isloading = true;
                                });

                                uploadBrailleImg().then((url) async {
                                  if (url != 'error') {
                                    print('The Url Val is ${url}');
                                    final brailetxt = await braileTxtApi
                                        .getBrailleText(url: url);
                                    print("the received val is ${brailetxt}");

                                    setState(() {
                                      txtBeforeTranslation =
                                          brailetxt.toString();
                                      isPlaying = true;
                                      isloading = false;
                                    });
                                    print(
                                        'txtbeforetranslation in braille is $txtBeforeTranslation');

                                    String translatedText =
                                        await translate(brailetxt.toString());

                                    await _speak(translatedText.toString());
                                  } else {
                                    txtBeforeTranslation =
                                        'Failed to translate';
                                    setState(() {});
                                    String translatedText =
                                        await translate(txtBeforeTranslation);

                                    await _speak(translatedText.toString());
                                  }
                                });
                                print(2);
                              }, text: 'Process Braille Image')
                            : myFakeCard(context,
                                text: 'Process Braille Image'),
                      ),
                    ),
                    mycard(context, ontap: () {
                      // getStatus(".jpg");
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TextToBrailleScreen(),
                          ));
                    }, text: 'Text To Braille')
                  ],
                ),
                SizedBox(
                  height: 100,
                ),
                // Text(
                //   "Saved Images :",
                //   style: TextStyle(
                //       color: Colors.black,
                //       fontWeight: FontWeight.w500,
                //       fontSize: 14),
                // ),
                // ListView.builder(
                //   controller: scrollController,
                //   shrinkWrap: true,
                //   itemCount: _allimages.length,
                //   itemBuilder: (context, index) {
                //     final data = _allimages[index].path;
                //     return GestureDetector(
                //       onTap: () {
                //         Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) =>
                //                   ImageViewScreen(imgpath: data),
                //             ));
                //       },
                //       child: Padding(
                //         padding:
                //             const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.spaceAround,
                //           children: [
                //             Text(
                //               '${index + 1}. ',
                //               style: TextStyle(
                //                   color: Colors.black,
                //                   fontWeight: FontWeight.w500),
                //             ),
                //             Image.file(
                //               File(data),
                //               height: 100,
                //               width: MediaQuery.of(context).size.width * 0.8,
                //             ),
                //           ],
                //         ),
                //       ),
                //     );
                //   },
                // ),
                SizedBox(
                  height: 200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String> buildMenuItem(String item) {
    return DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1),
          //  textAlign: TextAlign.center,
        ));
  }
  //flutter build apk --split-per-abi

  //  Container(
  //                     padding:
  //                         EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //                     alignment: Alignment.center,
  //                     height: 50,
  //                     width: MediaQuery.of(context).size.width * 0.90,
  //                     decoration: BoxDecoration(
  //                         color:GlobalVariables.whiteColor,
  //                         borderRadius: BorderRadius.circular(20),
  //                         border: Border.all(color: Colors.black, width: 4)),
  //                     child: DropdownButtonHideUnderline(
  //                       child: DropdownButton<String>(
  //                         isExpanded: true,
  //                         underline: Divider(color: Colors.black),
  //                         elevation: 0,
  //                         value: chooseAreaFirst,
  //                         iconSize: 20,
  //                         icon: Icon(
  //                           Icons.arrow_drop_down_circle_outlined,

  //                           color: Colors.black,
  //                         ),
  //                         items: chooseAreaItems.map(buildMenuItem).toList(),
  //                         onChanged: (newValue) {
  //                           setState(() {
  //                             chooseAreaFirst = newValue;
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                   ),
}
