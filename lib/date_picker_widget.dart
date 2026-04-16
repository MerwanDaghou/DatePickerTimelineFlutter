import 'package:date_picker_timeline/extra/color.dart';
import 'package:date_picker_timeline/extra/style.dart';
import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'date_picker_timeline.dart';
import 'date_type.dart';
import 'dart:ui' as ui;

class DatePicker extends StatefulWidget {
  final DateTime startDate;
  final double width;
  final double height;
  final DatePickerController? controller;
  final Color selectedTextColor;
  final Color selectionColor;
  final Color deactivatedColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color? serviceIconColor;
  final TextStyle monthTextStyle;
  final TextStyle dayTextStyle;
  final TextStyle dateTextStyle;
  final DateTime? initialSelectedDate;
  final List<DateTime>? inactiveDates;
  final List<DateTime>? activeDates;
  final DateChangeListener? onDateChange;
  final int daysCount;
  final ui.TextDirection? directionality;
  final String locale;
  final List<DateTime>? datesOnNotification;

  DatePicker(
      this.startDate, {
        Key? key,
        this.width = 100,
        this.height = 90,
        this.controller,
        this.monthTextStyle = defaultMonthTextStyle,
        this.dayTextStyle = defaultDayTextStyle,
        this.dateTextStyle = defaultDayTextStyle,
        this.selectedTextColor = Colors.white,
        this.selectionColor = AppColors.defaultSelectionColor,
        this.deactivatedColor = AppColors.defaultDeactivatedColor,
        this.backgroundColor = Colors.transparent,
        this.borderColor = AppColors.defaultBorderColor,
        this.serviceIconColor,
        this.initialSelectedDate,
        this.activeDates,
        this.inactiveDates,
        this.daysCount = 500,
        this.onDateChange,
        this.locale = "en_US",
        this.datesOnNotification,
        this.directionality,
      }) : assert(
  activeDates == null || inactiveDates == null,
  "Can't provide both activated and deactivated dates List at the same time.",
  );

  @override
  State<StatefulWidget> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime? _currentDate;
  late final TextStyle selectedDateStyle;
  late final TextStyle deactivatedDateStyle;
  late final ScrollController _scrollController;

  // La lune déborde de cette largeur sur le bloc suivant
  double get nightOverflowWidth => widget.width * 0.38;

  // Largeur totale d'un slot = bloc + moitié du débordement
  double get slotWidth => widget.width + nightOverflowWidth / 2;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(widget.locale, null);
    _currentDate = widget.initialSelectedDate;
    widget.controller?.setDatePickerState(this);
    selectedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.selectedTextColor);
    deactivatedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.deactivatedColor);
    _scrollController =
        ScrollController(initialScrollOffset: _getInitialOffset());
  }

  double _getInitialOffset() {
    if (_currentDate != null) {
      final current = DateTime(
        _currentDate!.year,
        _currentDate!.month,
        _currentDate!.day,
      );
      final first = DateTime(
        widget.startDate.year,
        widget.startDate.month,
        widget.startDate.day,
      );
      final diff = current.difference(first).inDays;
      if (diff > 0) return diff * slotWidth;
    }
    return 0;
  }

  bool _hasNotif(DateTime date) {
    if (widget.datesOnNotification == null) return false;
    return widget.datesOnNotification!
        .any((d) => DateUtils.isSameDay(d, date));
  }

  void _onDateSelected(DateTime date) {
    widget.onDateChange?.call(date);
    setState(() => _currentDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.directionality ?? ui.TextDirection.ltr,
      child: SizedBox(
        height: widget.height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: widget.daysCount,
          itemBuilder: (context, index) {
            final _d = widget.startDate.add(Duration(days: index));
            final date = DateTime(_d.year, _d.month, _d.day);

            bool isDeactivated = false;
            if (widget.inactiveDates != null) {
              for (DateTime inactiveDate in widget.inactiveDates!) {
                if (DateUtils.isSameDay(date, inactiveDate)) {
                  isDeactivated = true;
                  break;
                }
              }
            }
            if (widget.activeDates != null) {
              isDeactivated = true;
              for (DateTime activateDate in widget.activeDates!) {
                if (DateUtils.isSameDay(date, activateDate)) {
                  isDeactivated = false;
                  break;
                }
              }
            }

            final isSelected = _currentDate != null
                ? DateUtils.isSameDay(date, _currentDate!)
                : false;

            final displayNotif = _hasNotif(date);

            final textStyle = isDeactivated
                ? deactivatedDateStyle
                : isSelected
                ? selectedDateStyle
                : widget.dateTextStyle;

            return _DateBlock(
              date: date,
              isSelected: isSelected,
              isDeactivated: isDeactivated,
              dateTextStyle: textStyle,
              selectionColor: widget.selectionColor,
              backgroundColor: widget.backgroundColor,
              borderColor: widget.borderColor,
              serviceIconColor: widget.serviceIconColor,
              displayNotif: displayNotif,
              locale: widget.locale,
              slotWidth: slotWidth,
              nightOverflowWidth: nightOverflowWidth,
              onTap: () {
                if (!isDeactivated) _onDateSelected(date);
              },
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// _DateBlock
// ================================================================
class _DateBlock extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isDeactivated;
  final TextStyle dateTextStyle;
  final Color selectionColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color? serviceIconColor;
  final bool displayNotif;
  final String locale;
  final double slotWidth;
  final double nightOverflowWidth;
  final VoidCallback onTap;

  const _DateBlock({
    required this.date,
    required this.isSelected,
    required this.isDeactivated,
    required this.dateTextStyle,
    required this.selectionColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.serviceIconColor,
    required this.displayNotif,
    required this.locale,
    required this.slotWidth,
    required this.nightOverflowWidth,
    required this.onTap,
  });

  // Largeur du bloc principal (sans le débordement)
  double get blockWidth => slotWidth - nightOverflowWidth / 2;

  @override
  Widget build(BuildContext context) {
    // Largeur de la lune (déborde à droite)
    final nightWidth = nightOverflowWidth * 1.4;

    return SizedBox(
      width: slotWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Bloc principal ──────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                width: blockWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? selectionColor : borderColor,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  color: isSelected
                      ? selectionColor.withOpacity(0.12)
                      : backgroundColor,
                ),
                child: Column(
                  children: [
                    // ── Header date ────────────────────────────
                    Expanded(
                      flex: 4,
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Text(
                                "${DateFormat("E", locale).format(date).toUpperCase()} "
                                    "${date.day} "
                                    "${DateFormat("MMM", locale).format(date).toUpperCase()}",
                                style: dateTextStyle,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (displayNotif)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                height: 6,
                                width: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Séparateur ─────────────────────────────
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: isSelected
                          ? selectionColor.withOpacity(0.4)
                          : borderColor.withOpacity(0.4),
                    ),

                    // ── Bas : soleil + placeholder lune ────────
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          // Soleil
                          Expanded(
                            child: Center(
                              child: Image.asset(
                                Utils.getIconService(ServiceType.noon),
                                width: 18,
                                height: 18,
                                color: isSelected
                                    ? Colors.white
                                    : serviceIconColor,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.wb_sunny_outlined,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : serviceIconColor,
                                ),
                              ),
                            ),
                          ),
                          // Placeholder pour la lune
                          SizedBox(width: nightOverflowWidth / 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lune — déborde à droite sur le slot suivant ────
            Positioned(
              right: -nightOverflowWidth / 2,
              bottom: 3,
              top: null,
              height: 30,
              width: nightWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap, // même action : sélectionne le jour
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    color: isSelected
                        ? selectionColor.withOpacity(0.25)
                        : backgroundColor,
                    border: Border.all(
                      color: isSelected ? selectionColor : borderColor,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      Utils.getIconService(ServiceType.night),
                      width: 18,
                      height: 18,
                      color: isSelected ? Colors.white : serviceIconColor,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.nightlight_round,
                        size: 16,
                        color: isSelected ? Colors.white : serviceIconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// Controller
// ================================================================
class DatePickerController {
  _DatePickerState? _datePickerState;

  void setDatePickerState(_DatePickerState state) {
    _datePickerState = state;
  }

  void jumpToSelection() {
    assert(_datePickerState != null,
    'DatePickerController is not attached to any DatePicker View.');
    _datePickerState!._scrollController
        .jumpTo(_calculateDateOffset(_datePickerState!._currentDate!));
  }

  void animateToSelection({
    duration = const Duration(milliseconds: 500),
    curve = Curves.linear,
  }) {
    assert(_datePickerState != null,
    'DatePickerController is not attached to any DatePicker View.');
    _datePickerState!._scrollController.animateTo(
      _calculateDateOffset(_datePickerState!._currentDate!),
      duration: duration,
      curve: curve,
    );
  }

  void animateToDate(
      DateTime date, {
        duration = const Duration(milliseconds: 500),
        curve = Curves.linear,
      }) {
    assert(_datePickerState != null,
    'DatePickerController is not attached to any DatePicker View.');
    _datePickerState!._scrollController.animateTo(
      _calculateDateOffset(date),
      duration: duration,
      curve: curve,
    );
  }

  void setDateAndAnimate(
      DateTime date, {
        duration = const Duration(milliseconds: 500),
        curve = Curves.linear,
      }) {
    assert(_datePickerState != null,
    'DatePickerController is not attached to any DatePicker View.');
    _datePickerState!._scrollController.animateTo(
      _calculateDateOffset(date),
      duration: duration,
      curve: curve,
    );
    if (date.compareTo(_datePickerState!.widget.startDate) >= 0 &&
        date.compareTo(_datePickerState!.widget.startDate
            .add(Duration(days: _datePickerState!.widget.daysCount))) <=
            0) {
      _datePickerState!._currentDate = date;
    }
  }

  double _calculateDateOffset(DateTime date) {
    final startDate = DateTime(
      _datePickerState!.widget.startDate.year,
      _datePickerState!.widget.startDate.month,
      _datePickerState!.widget.startDate.day,
    );
    int offset = date.difference(startDate).inDays;
    return offset * _datePickerState!.slotWidth;
  }
}