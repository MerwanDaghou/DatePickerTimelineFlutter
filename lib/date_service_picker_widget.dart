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

  /// Background color for unselect items
  final Color backgroundColor;

  /// Color for service icons
  final Color? serviceIconColor;

  /// Color for service icons
  final Color borderColor;

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
        required this.backgroundColor,
        this.width = 140,
        this.height = 120,
        this.controller,
        this.dateTextStyle = defaultDayTextStyle,
        this.selectedTextColor = Colors.white,
        this.selectionColor = AppColors.defaultSelectionColor,
        this.serviceIconColor,
        this.borderColor = AppColors.defaultBorderColor,
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

  late final ScrollController scrollController;

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

    scrollController = ScrollController(initialScrollOffset: getInitialOffset());
  }

  double getInitialOffset(){
    if(_currentDateService != null){
      DateTime _currentDate = DateTime(_currentDateService!.date.year, _currentDateService!.date.month, _currentDateService!.date.day);
      DateTime _firstDate = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day);

      int dateDiff = _currentDate.difference(_firstDate).inDays;
      if(dateDiff > 0){
        return dateDiff * widget.width;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        padding: EdgeInsets.only(left: widget.width / (numService * 2)),
        itemCount: widget.daysCount,
        itemBuilder: (context, index) {
          DateTime date;
          DateTime _date = widget.startDate.add(Duration(days: index));
          date = DateTime(_date.year, _date.month, _date.day);

          bool isSelected = _currentDateService != null
              ? DateUtils.isSameDay(date, _currentDateService!.date)
              : false;

          bool displayNotif = widget.datesOnNotification == null ? false : widget.datesOnNotification!.where((element) => DateUtils.isSameDay(element.date, date)).isNotEmpty;

          return Column(
            children: [
              Transform.translate(
                offset: Offset(- widget.width / (numService * 2), 0),
                child: DateServiceAllWidget(
                  date: date,
                  dateTextStyle: isSelected
                      ? selectedDateStyle
                      : widget.dateTextStyle,
                  width: widget.width,
                  locale: widget.locale,
                  backgroundColor: isSelected ? widget.selectionColor : widget.backgroundColor,
                  borderColor: widget.borderColor,
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
                    backgroundColor: isSelected ? widget.selectionColor : widget.backgroundColor,
                    borderColor: widget.borderColor,
                    iconColor: widget.serviceIconColor,
                    displayNotif: displayNotif,
                    dateServiceCallback: (selectedDateService) {
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
