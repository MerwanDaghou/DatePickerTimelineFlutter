/// ***
/// This class consists of the DateWidget that is used in the ListView.builder
///
/// Author: Vivek Kaushik <me@vivekkasuhik.com>
/// github: https://github.com/iamvivekkaushik/
/// ***

import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GregorianDateWidget extends StatelessWidget {
  final double? width;
  final DateTime date;
  final bool displayNotif;
  final TextStyle? monthTextStyle, dayTextStyle, dateTextStyle;
  final Color selectionColor;
  final DateSelectionCallback? onDateSelected;
  final String? locale;

  GregorianDateWidget({
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
        margin: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          color: selectionColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(DateFormat("MMM", locale).format(date).toUpperCase(), // Month
                      style: monthTextStyle),
                  Text(date.day.toString(), // Date
                      style: dateTextStyle),
                  Text(DateFormat("E", locale).format(date).toUpperCase(), // WeekDay
                      style: dayTextStyle)
                ],
              ),
              if(displayNotif)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
      onTap: () {
        onDateSelected?.call(this.date);
      },
    );
  }
}
