import 'package:flutter/material.dart';

import '../../constants/global_variables.dart';

Widget mycard(BuildContext context,
    {required VoidCallback ontap, required String text}) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      height: 200,
      width: MediaQuery.of(context).size.width * 0.46,
      decoration: BoxDecoration(
          border: Border.all(color: GlobalVariables.blackColor),
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GlobalVariables.card1Color,
                GlobalVariables.card2Color
              ])),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
              color: GlobalVariables.whiteColor, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

Widget myFakeCard(BuildContext context, {required String text}) {
  return Container(
    height: 200,
    width: MediaQuery.of(context).size.width * 0.46,
    decoration: BoxDecoration(
        border: Border.all(color: GlobalVariables.blackColor),
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GlobalVariables.card1Color.withOpacity(0.65), //0.4
              GlobalVariables.card2Color.withOpacity(0.65)
            ])),
    child: Center(
      child: Text(
        text,
        style: TextStyle(
            color: GlobalVariables.lightwhiteColor,
            fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
