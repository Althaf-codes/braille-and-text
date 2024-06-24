import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

import '../Utils/image_picker.dart';

//USING FIREBASE_ML_VISION

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  bool isSelected = false;
  bool isloading = false;
  bool isPlaying = false;
  File? imgPath;
  String? mltext;
  String? langcode;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = ScrollController();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[900],
        onPressed: () {},
        child: Text('Scan'),
      ),
      body: SingleChildScrollView(
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
              height: 10,
            ),
            isloading
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: EdgeInsets.only(
                          left: 8, right: 8, top: 12, bottom: 12),
                      decoration: BoxDecoration(
                          color: isloading ? Colors.grey[400] : Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        mltext ?? '',
                        maxLines: 100,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            !isSelected
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              backgroundColor: Colors.blue[900]),
                          onPressed: () {
                            pickImage(source: ImageSource.gallery)
                                .then((value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  isSelected = !isSelected;
                                  imgPath = File(value);
                                });
                              }
                            });
                          },
                          child: Text('Pick Image')),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              backgroundColor:
                                  Colors.blue[900]!.withOpacity(0.5)),
                          onPressed: () {},
                          child: Text('Pick Image')),
                    ),
                  ),
            isSelected
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              backgroundColor: Colors.blue[900]),
                          onPressed: () {
                            setState(() {
                              isSelected = !isSelected;
                              isloading = false;
                              mltext = '';
                            });
                          },
                          child: Text('Delete')),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              backgroundColor:
                                  Colors.blue[900]!.withOpacity(0.5)),
                          onPressed: () {},
                          child: Text('Delete')),
                    ),
                  ),
            isSelected
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              backgroundColor: Colors.blue[900]),
                          onPressed: () {},
                          child: Text('Process')),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              backgroundColor:
                                  Colors.blue[900]!.withOpacity(0.5)),
                          onPressed: () async {
                            // FirebaseVisionImage imageObject =
                            //     FirebaseVisionImage.fromFile(imgPath!);
                            // final recogniser = instance.textRecognizer();

                            // final VisionText visionText =
                            //     await recogniser.processImage(imageObject);
                            // setState(() {
                            //   mltext = visionText.text;
                            // });
                            // // final String? text = visionText.text;
                            // recogniser.close();
                          },
                          child: Text('Process')),
                    ),
                  ),
            // isPlaying
            //     ? Padding(
            //         padding: const EdgeInsets.all(5.0),
            //         child: Center(
            //           child: ElevatedButton(
            //               style: ElevatedButton.styleFrom(
            //                   shape: StadiumBorder(),
            //                   backgroundColor: Colors.blue[900]),
            //               onPressed: () {},
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
            //               onPressed: () {},
            //               child: Text('Play')),
            //         ),
            //       ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Center(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: StadiumBorder(),
                        backgroundColor: !isSelected
                            ? Colors.blue[900]!.withOpacity(0.5)
                            : mltext == null
                                ? Colors.blue[900]!.withOpacity(0.5)
                                : Colors.blue[900]),
                    onPressed: () async {
                      // FlutterLanguageIdentification languageIdentification =
                      //     FlutterLanguageIdentification();

                      // await languageIdentification.identifyLanguage(mltext);

                      // languageIdentification.setSuccessHandler((code) {
                      //   setState(() {
                      //     print("The language code is $code");
                      //     langcode = code;
                      //   });
                      // });

                      final languageIdentifier =
                          LanguageIdentifier(confidenceThreshold: 0.5);
                      final String response =
                          await languageIdentifier.identifyLanguage(mltext!);

                      final List<IdentifiedLanguage> possibleLanguages =
                          await languageIdentifier
                              .identifyPossibleLanguages(mltext!);

                      print("The lang response is $response");
                      print("the languages are $possibleLanguages");
                    },
                    child: Text('Indetify Language')),
              ),
            ),
            SizedBox(
              height: 30,
            )
          ],
        ),
      ),
    );
  }
}
