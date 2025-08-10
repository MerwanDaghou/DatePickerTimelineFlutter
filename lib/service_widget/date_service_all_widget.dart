
/// ***
/// This class consists of the DateWidget that is used in the ListView.builder
///
/// Author: Vivek Kaushik <me@vivekkasuhik.com>
/// github: https://github.com/iamvivekkaushik/
/// ***

import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateServiceAllWidget extends StatelessWidget {
  final double? width;
  final DateTime date;
  final bool displayNotif;
  final TextStyle? monthTextStyle, dayTextStyle, dateTextStyle;
  final Color selectionColor;
  final DateSelectionCallback? onDateSelected;
  final String? locale;

  DateServiceAllWidget({
    required this.date,
    required this.monthTextStyle,
    required this.dayTextStyle,
    required this.dateTextStyle,
    required this.selectionColor,
    this.width,
    this.onDateSelected,
    this.locale,
    this.displayNotif = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))
      ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          border: Border.all(color: Colors.grey, width: 1),
          color: selectionColor,
        ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "${DateFormat("E", locale).format(date).toUpperCase()} ${date.day} ${DateFormat("MMM", locale).format(date).toUpperCase()}",
                  style: dayTextStyle,
                )
              ),
            ),
            if(displayNotif)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  height: 5,
                  width: 5,
                  margin: const EdgeInsets.only(top: 4, right: 4),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Utils.red
                  ),
                ),
              )
          ],
        ),
      ),
      onTap: () {
        onDateSelected?.call(this.date);
      },
    );
  }
}
