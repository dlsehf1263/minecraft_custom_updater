import 'package:flutter/material.dart';
import 'package:mc/ui_utils.dart';

const borderRadius = Radius.circular(15.0);

const dialogFirstPadding = Padding(padding: EdgeInsets.all(4));
const dialogVertPadding = 12.0;
const dialogHoriPadding = 16.0;
const dialogSpacing = dialogHoriPadding / 2;
const dialogSpacingAtCorner = 10.0;

const dialogTitleSize = 17.0;
const dialogMaxHeightRate = 0.65; // 최대 높이 비율 (dpWin.height에 곱해야함)

Future openDialogWithContent(
  BuildContext context,
  Widget content, {
  String? title,
  double titleSize = dialogTitleSize,
  Function()? backButtonCallback,
  bool barrierDismissible = true,
  // 다이얼로그는 width 최대가 한 80%인듯
  double width = double.infinity,
}) {
  var items = <Widget>[];

  bool hasTitle = title != null;

  if (hasTitle) {
    items.addAll([
      dialogFirstPadding,
      Text(
        title,
        style: TextStyle(fontSize: titleSize),
      ),
    ]);
  }

  items.add(
    Padding(
      padding: EdgeInsets.only(
        top: hasTitle ? dialogSpacingAtCorner : dialogVertPadding,
        bottom: dialogVertPadding,
        left: dialogHoriPadding,
        right: dialogHoriPadding,
      ),
      child: content,
    ),
  );

  var dlg = Dialog(
    // 다이얼로그 기본 모양 제거
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(borderRadius),
    ),
    elevation: 0,
    backgroundColor: Colors.transparent,
    child: wrapDialogContent(
      Column(children: items),
      width,
    ),
  );

  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dlgContext) {
      if (backButtonCallback == null) {
        return dlg;
      }

      return WillPopScope(
        onWillPop: () async {
          backButtonCallback();
          return false;
        },
        child: dlg,
      );
    },
  );
}

wrapDialogContent(Widget content, [double width = double.infinity]) {
  return Wrap(
    alignment: WrapAlignment.center,
    children: [
      Container(
        decoration: makeShadowDeocration(BorderRadius.all(borderRadius)),
        child: content,
        width: width,
      ),
    ],
  );
}

BoxDecoration makeShadowDeocration(BorderRadius rad, {blurRadius = 5.0, opacity = 0.3, color = Colors.white}) {
  return BoxDecoration(color: color, borderRadius: rad, boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(opacity),
      blurRadius: blurRadius,
    )
  ]);
}

Widget makeDialogButton(Widget content, Function() onPressed, [Color? btnColor]) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: TextButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.grey.withOpacity(0.3),
      ),
      child: Center(child: content),
      onPressed: onPressed,
    ),
  );
}

Widget makeDialogButtonWithIcon(IconData icon, String txt, Function() onTap,
    {double fontSize = 15, double height = 40}) {
  return SizedBox(
    height: height,
    child: makeDialogButton(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: Colors.black),
          SizedBox(width: 7),
          Text(
            txt,
            style: TextStyle(color: Colors.black, fontSize: fontSize),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      onTap,
    ),
  );
}

Widget makeDialogButtonOnlyText(String txt, Function() onTap, {double fontSize = 15, double height = 40}) {
  return SizedBox(
    height: height,
    child: makeDialogButton(
      Text(
        txt,
        style: TextStyle(color: Colors.black, fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
      onTap,
    ),
  );
}

const msgDialogOK = ['확인'];
const msgDialogClose = ['닫기'];

const msgDialogYesNo = ['아니오', '예'];
const msgResultYes = 1, msgResultNo = 0;

Future openButtonDialog(String title, Widget item, [List<String> txts = msgDialogOK, bool cancelable = true]) {
  var items = <Widget>[];

  for (int i = 0; i < txts.length; ++i) {
    items.add(Expanded(
      child: makeDialogButtonOnlyText(
        txts[i],
        () {
          Navigator.of(context).pop(i);
        },
      ),
    ));

    if (i != txts.length - 1) items.add(SizedBox(width: dialogSpacing));
  }

  return openDialogWithContent(
    context,
    Column(
      children: [
        item,
        SizedBox(height: dialogSpacingAtCorner),
        Row(children: items),
      ],
    ),
    title: title,
    width: MediaQuery.of(context).size.width * 0.75,
    barrierDismissible: cancelable,
    backButtonCallback: cancelable ? null : () {},
  );
}

Future openMessageDialog(String title, String mes,
        [List<String> txts = msgDialogOK, bool cancelable = false, List<Widget>? topWidgets]) =>
    openButtonDialog(
      title,
      Column(children: [
        if (topWidgets != null) ...topWidgets,
        LimitedBox(
          child: Text(mes, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
      ]),
      txts,
      cancelable,
    );
