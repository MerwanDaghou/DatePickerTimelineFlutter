

/// ***
/// This class consists of the DateWidget that is used in the ListView.builder
///
/// Author: Vivek Kaushik <me@vivekkasuhik.com>
/// github: https://github.com/iamvivekkaushik/
/// ***

import 'dart:developer';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:date_picker_timeline/extra/color.dart';
import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceWidget extends StatelessWidget {
  final double width;
  final DateTime date;
  final ServiceType service;
  final bool displayNotif;
  final Color? selectionColor;
  final Color? iconColor;
  final Color borderColor;
  final bool selected;
  final ValueChanged<DateService> dateServiceCallback;
  final String? locale;

  ServiceWidget({
    required this.date,
    required this.service,
    required this.selectionColor,
    required this.width,
    required this.selected,
    required this.borderColor,
    this.iconColor,
    required this.dateServiceCallback,
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
        height: width,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 0.5),
          color: selectionColor,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                Utils.getIconService(service),
                width: 0.8 * width,
                height: 0.8 * width,
                color: selected ? Colors.white : iconColor,
                errorBuilder: (ctx, child, error){
                  debugPrint("error : ${error}");

                  return Icon(
                    Icons.error
                  );
                },
              )
            ),
            if(displayNotif)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  height: 5,
                  width: 5,
                  margin: EdgeInsets.only(right: 2, top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red
                  ),
                ),
              )
          ],
        ),
      ),
      onTap: () {
        debugPrint("tap on service");
        dateServiceCallback(DateService(date: date, service: service));
      },
    );
  }
}
