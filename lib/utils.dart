
import 'dart:developer';

import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';

class Utils {
  static Color red = const Color(0xFFED4337);

  static bool isSameDateService({required DateService dateService, required DateService dateServiceSelected}){
    if(DateUtils.isSameDay(dateService.date, dateServiceSelected.date)){
      if(dateServiceSelected.service == ServiceType.all){
        return true;
      }
      else{
        return dateService.service == dateServiceSelected.service;
      }
    }
    else{
      return false;
    }
  }

  static ServiceType getServiceFromIndex({required DateServicePickerType pickerType, required int index}){
    index = index % (pickerType == DateServicePickerType.detailed ? 5 : 4);
    if(index == 0){
      return ServiceType.after;
    }
    else if(index == 1){
      if(pickerType == DateServicePickerType.detailed){
        return ServiceType.noon;
      }
      else{
        return ServiceType.daytime;
      }
    }
    else if(index == 2){
      if(pickerType == DateServicePickerType.detailed){
        return ServiceType.afternoon;
      }
      else{
        return ServiceType.before;
      }
    }
    else if(index == 3){
      if(pickerType == DateServicePickerType.detailed){
        return ServiceType.before;
      }
      else{
        return ServiceType.night;
      }
    }
    else if(index == 4){
      return ServiceType.night;
    }
    else{
      return ServiceType.all;
    }
  }

  static String getIconService(ServiceType service){
    switch(service){
      case ServiceType.all:
        throw 'No Icon for all service';
      case ServiceType.noon:
        return 'packages/date_picker_timeline/assets/images/icon_service_noon.png';
      case ServiceType.afternoon:
        return 'packages/date_picker_timeline/assets/images/icon_service_afternoon.png';
      case ServiceType.daytime:
        return 'packages/date_picker_timeline/assets/images/icon_service_afternoon.png';
      case ServiceType.before:
        return 'packages/date_picker_timeline/assets/images/icon_service_before.png';
      case ServiceType.night:
        return 'packages/date_picker_timeline/assets/images/icon_service_night.png';
      case ServiceType.after:
        return 'packages/date_picker_timeline/assets/images/icon_service_after.png';
    }
  }
}