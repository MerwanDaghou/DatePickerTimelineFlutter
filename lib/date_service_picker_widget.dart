import 'package:date_picker_timeline/service_widget/date_service_all_widget.dart';
import 'package:date_picker_timeline/gregorian_date/gregorian_date_widget.dart';
import 'package:date_picker_timeline/extra/color.dart';
import 'package:date_picker_timeline/extra/style.dart';
import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/persian_date/persian_date.dart';
import 'package:date_picker_timeline/persian_date/persian_date_widget.dart';
import 'package:date_picker_timeline/service_widget/service_picker_widget.dart';
import 'package:date_picker_timeline/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'date_type.dart';

enum DateServicePickerType {
  detailed,
  grouped
}

class DateServicePicker extends StatefulWidget {
  /// Start Date in case user wants to show past dates
  /// If not provided calendar will start from the initialSelectedDate
  final DateTime startDate;

  final DateServicePickerType pickerType;

  /// Width of the selector
  final double width;

  /// Height of the selector
  final double height;

  /// DateServicePicker Controller
  final DateServicePickerController? controller;

  /// Text color for the selected Date
  final Color selectedTextColor;

  /// Background color for the selector
  final Color selectionColor;

  /// Text Color for the deactivated dates
  final Color deactivatedColor;

  /// TextStyle for Month Value
  final TextStyle monthTextStyle;

  /// TextStyle for day Value
  final TextStyle dayTextStyle;

  /// TextStyle for the date Value
  final TextStyle dateTextStyle;

  /// Current Selected Date
  final DateService? /*?*/ initialSelectedDateService;

  /// Callback function for when a different date is selected
  final ValueChanged<DateService>? onDateServiceChange;

  /// Max limit up to which the dates are shown.
  /// Days are counted from the startDate
  final int daysCount;

  /// Directionality
  final TextDirection? directionality;

  /// Locale for the calendar default: en_us
  final String locale;

  /// List of datetime where display notification
  final List<DateService>? datesOnNotification;

  DateServicePicker(
      this.startDate, {
        Key? key,
        required this.pickerType,
        this.width = 140,
        this.height = 120,
        this.controller,
        this.monthTextStyle = defaultMonthTextStyle,
        this.dayTextStyle = defaultDayTextStyle,
        this.dateTextStyle = defaultDateTextStyle,
        this.selectedTextColor = Colors.white,
        this.selectionColor = AppColors.defaultSelectionColor,
        this.deactivatedColor = AppColors.defaultDeactivatedColor,
        this.initialSelectedDateService,
        this.daysCount = 500,
        this.onDateServiceChange,
        this.locale = "en_US",
        this.datesOnNotification,
        this.directionality,
      });

  @override
  State<StatefulWidget> createState() => new _DateServicePickerState();
}

class _DateServicePickerState extends State<DateServicePicker> {
  DateService? _currentDateService;

  late final int numService;

  late final TextStyle selectedDateStyle;
  late final TextStyle selectedMonthStyle;
  late final TextStyle selectedDayStyle;

  late final TextStyle deactivatedDateStyle;
  late final TextStyle deactivatedMonthStyle;
  late final TextStyle deactivatedDayStyle;

  @override
  void initState() {
    super.initState();

    // Init number of service
    numService = widget.pickerType == DateServicePickerType.detailed ? 5 : 4;

    // Init the calendar locale
    initializeDateFormatting(widget.locale, null);

    // Set initial Values
    _currentDateService = widget.initialSelectedDateService;

    widget.controller?.setDateServicePickerState(this);

    this.selectedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.selectedTextColor);
    this.selectedMonthStyle =
        widget.monthTextStyle.copyWith(color: widget.selectedTextColor);
    this.selectedDayStyle =
        widget.dayTextStyle.copyWith(color: widget.selectedTextColor);

  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: widget.width / (numService * 2)),
        itemCount: widget.daysCount,
        itemBuilder: (context, index) {
          DateTime date;
          DateTime _date = widget.startDate.add(Duration(days: index));
          date = DateTime(_date.year, _date.month, _date.day);

          bool isSelected = _currentDateService != null
              ? DateUtils.isSameDay(date, _currentDateService!.date)
              : false;

          bool displayNotif = widget.datesOnNotification == null ? false : widget.datesOnNotification!.where((element) => DateUtils.isSameDay(element.date, date) && element.service == ServiceType.all).isNotEmpty;

          return Column(
            children: [
              Transform.translate(
                offset: Offset(- widget.width / (numService * 2), 0),
                child: DateServiceAllWidget(
                  date: date,
                  monthTextStyle: isSelected
                      ? selectedMonthStyle
                      : widget.monthTextStyle,
                  dateTextStyle: isSelected
                      ? selectedDateStyle
                      : widget.dateTextStyle,
                  dayTextStyle: isSelected
                      ? selectedDayStyle
                      : widget.dayTextStyle,
                  width: widget.width,
                  locale: widget.locale,
                  selectionColor:
                  isSelected ? widget.selectionColor : Colors.transparent,
                  displayNotif: displayNotif,
                  onDateSelected: (selectedDate) {

                    // A date is selected
                    if(widget.onDateServiceChange != null){
                      widget.onDateServiceChange!(DateService(date: selectedDate, service: ServiceType.all));
                    }

                    setState(() {
                      _currentDateService = DateService(date: date, service: ServiceType.all);
                    });
                  },
                ),
              ),
              Row(
                children: List.generate(numService, (serviceIndex) {
                  final service = Utils.getServiceFromIndex(
                    pickerType: widget.pickerType,
                    index: serviceIndex,
                  );

                  bool isSelected = _currentDateService != null
                      ? Utils.isSameDateService(dateService: DateService(date: date, service: service), dateServiceSelected: _currentDateService!)
                      : false;

                  bool displayNotif = widget.datesOnNotification == null ? false : widget.datesOnNotification!.where((element) => DateUtils.isSameDay(element.date, date) && element.service == service).isNotEmpty;

                  return ServiceWidget(
                    date: date,
                    service: service,
                    width: widget.width / numService,
                    locale: widget.locale,
                    selected: isSelected,
                    selectionColor:
                    isSelected ? widget.selectionColor : Colors.transparent,
                    displayNotif: displayNotif,
                    dateServiceCallback: (selectedDateService) {
                      debugPrint("pass here : $selectedDateService");
                      // A date is selected
                      if(widget.onDateServiceChange != null){
                        widget.onDateServiceChange!(selectedDateService);
                      }

                      setState(() {
                        _currentDateService = selectedDateService;
                      });
                    },
                  );
                }),
              ),
            ],
          );
        },
      )
    );
  }
}

class DateServicePickerController {
  _DateServicePickerState? _datePickerState;

  void setDateServicePickerState(_DateServicePickerState state) {
    _datePickerState = state;
  }
}

class DateService {
  final DateTime date;
  final ServiceType service;

  const DateService({required this.date, required this.service});
}

enum ServiceType {
  all,
  noon,
  afternoon,
  daytime,
  before,
  night,
  after
}
