import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gradient_borders/input_borders/gradient_outline_input_border.dart';
import 'package:text_braile_recognition/api/braille_text_api.dart';
import 'package:text_braile_recognition/api/pdfapi.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

import '../constants/global_variables.dart';

class TextToBrailleScreen extends StatefulWidget {
  const TextToBrailleScreen({super.key});

  @override
  State<TextToBrailleScreen> createState() => _TextToBrailleScreenState();
}

class _TextToBrailleScreenState extends State<TextToBrailleScreen> {
  BraileTxtApi braileTxtApi = BraileTxtApi();
  PdfApi pdfApi = PdfApi();
  final formGlobalKey = GlobalKey<FormState>();
  WidgetsToImageController controller = WidgetsToImageController();
  Uint8List? bytes;

  String braille = ''; //'⠓⠑⠇⠇⠕'; //⠺⠕⠗⠇⠙
  TextEditingController textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  Image? img;
  // @override
  // void dispose() {
  //   textEditingController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    TextStyle mystyle = TextStyle(color: Colors.black);

    void getCanvasImage(String str) async {
      var builder = ParagraphBuilder(
          ParagraphStyle(fontStyle: FontStyle.normal, fontSize: 22));
      builder.addText(str);
      // builder.pushStyle()
      Paragraph paragraph = builder.build();

      paragraph.layout(const ParagraphConstraints(width: 100));

      final recorder = PictureRecorder();
      var newCanvas = Canvas(recorder);
      newCanvas.drawColor(Colors.black, BlendMode.hardLight);
      newCanvas.drawParagraph(paragraph, Offset.zero);

      final picture = recorder.endRecording();
      var res = await picture.toImage(900, 120);
      ByteData? data = await res.toByteData(format: ImageByteFormat.png);

      if (data != null) {
        await pdfApi.generateCenteredText(context, Uint8List.view(data.buffer));

        img = Image.memory(Uint8List.view(data.buffer));
        print("The image is $img");
      }

      setState(() {});
    }

    void _onPressedButton() {
      getCanvasImage(braille);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Text_Braille',
          style: TextStyle(color: GlobalVariables.whiteColor),
        ),
        backgroundColor: GlobalVariables.appbarColor,
      ),
      body: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              Form(
                key: formGlobalKey,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0),
                  child: Container(
                    // height: 100,
                    decoration: BoxDecoration(
                      // color: Colors.white,
                      borderRadius: BorderRadius.circular(19),
                    ),

                    child: TextFormField(
                      // key: formGlobalKey,
                      minLines: 1,
                      cursorColor: Colors.blue[900],
                      decoration: InputDecoration(
                          labelStyle: TextStyle(
                              color: Color.fromARGB(255, 216, 0, 254)),
                          hintText: 'Enter your Text',
                          labelText: 'Text',
                          enabledBorder: GradientOutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(colors: [
                              Colors.blue,
                              Color.fromARGB(255, 216, 0, 254)
                            ]),
                            width: 2,
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Colors.red,
                                style: BorderStyle.solid,
                                width: 2),
                          ),
                          focusedBorder: GradientOutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(colors: [
                                Color.fromARGB(255, 216, 0, 254),
                                Colors.blue
                              ]),
                              width: 2),
                          focusColor: Colors.white,
                          border: GradientOutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(colors: [
                              Colors.blue,
                              Color.fromARGB(255, 216, 0, 254)
                            ]),
                            width: 2,
                          ),
                          prefixIcon: IconButton(
                            icon: Icon(
                              Icons.lock_outlined,
                              color: Color.fromARGB(255, 216, 0, 254),
                            ),
                            onPressed: () {},
                          ),
                          fillColor: Colors.white,
                          filled: true),
                      controller: textEditingController,
                      validator: (textval) {
                        if (textval != null && textval.isEmpty) {
                          return 'textval feild is necessary';
                        } else if (textval != null && textval.length <= 1) {
                          return 'It should atleast 2 characters';
                        } else if (textval != null && textval.length >= 8) {
                          return null;
                        }
                      },
                    ),
                  ),
                ),
              ),
              WidgetsToImage(
                controller: controller,
                child: Container(
                  color: Colors.white,
                  // height: 100,
                  width: 450,
                  // padding: const EdgeInsets.all(.0),
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 12, bottom: 12),
                  // decoration: BoxDecoration(
                  //     color:
                  //         braille.isEmpty ? Colors.transparent : Colors.white,
                  //     borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    braille,
                    maxLines: 100,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 27,
                      letterSpacing: 1,
                      // wordSpacing: 1,
                      // fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // img ?? Container(),
              Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: StadiumBorder(),
                              backgroundColor: Colors.blue[900]),
                          onPressed: () async {
                            if (formGlobalKey.currentState!.validate()) {
                              formGlobalKey.currentState!.save();
                              print("its here");
                              final braile = await braileTxtApi
                                  .getBrailleFromText(
                                      text:
                                          textEditingController.text.toString())
                                  .then(
                                (value) {
                                  print('THE VALUE IS $value');
                                  setState(() {
                                    braille = value;
                                  });
                                },
                              );
                            }
                          },
                          child: const Text('Text To Braille')))),
              braille.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Center(
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  shape: StadiumBorder(),
                                  backgroundColor: Colors.blue[900]),
                              onPressed: () async {
                                final img = await controller.capture();
                                // MemoryImage(img!);
                                final file = await pdfApi.generateCenteredText(
                                    context, img!);
                                print("THE FILE IS ${file.path}");
                              },
                              child: const Text('Save as Image'))))
                  : Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Center(
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: StadiumBorder(),
                                backgroundColor:
                                    Colors.blue[900]!.withOpacity(0.6),
                              ),
                              onPressed: () {},
                              child: const Text('Save as Image')))),
              // Padding(
              //     padding: const EdgeInsets.all(5.0),
              //     child: Center(
              //         child: ElevatedButton(
              //             style: ElevatedButton.styleFrom(
              //               shape: StadiumBorder(),
              //               backgroundColor: Colors.blue[900]!.withOpacity(0.6),
              //             ),
              //             onPressed: () {
              //               _onPressedButton();
              //             },
              //             child: const Text('Get canvas Image')))),
            ],
          )),
    );
  }
}
