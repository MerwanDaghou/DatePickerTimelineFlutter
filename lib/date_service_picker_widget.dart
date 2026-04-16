import 'package:date_picker_timeline/extra/color.dart';
import 'package:date_picker_timeline/extra/style.dart';
import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'date_type.dart';

enum DateServicePickerType { detailed, grouped }

class DateServicePicker extends StatefulWidget {
  final DateTime startDate;
  final DateServicePickerType pickerType;
  final double width;
  final double height;
  final DateServicePickerController? controller;
  final Color selectedTextColor;
  final Color selectionColor;
  final Color backgroundColor;
  final Color? serviceIconColor;
  final Color borderColor;
  final TextStyle dateTextStyle;
  final DateService? initialSelectedDateService;
  final ValueChanged<DateService>? onDateServiceChange;
  final int daysCount;
  final TextDirection? directionality;
  final String locale;
  final List<DateService>? datesOnNotification;

  DateServicePicker(
      this.startDate, {
        Key? key,
        required this.pickerType,
        required this.backgroundColor,
        this.width = 140,
        this.height = 90,
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
  State<StatefulWidget> createState() => _DateServicePickerState();
}

class _DateServicePickerState extends State<DateServicePicker> {
  DateService? _currentDateService;
  late final int numDayServices;
  late final TextStyle selectedDateStyle;
  late final ScrollController scrollController;

  // Le night déborde de cette largeur sur le bloc suivant
  double get nightOverflowWidth =>
      (widget.width / numDayServices) + 18.0;

  // Largeur totale d'un slot = bloc + espace pour que le night du bloc
  // précédent puisse déborder sur ce slot
  double get slotWidth =>  widget.width + nightOverflowWidth / 2;

  @override
  void initState() {
    super.initState();

    // detailed = 5 services → 4 sous la date + night flottant
    // grouped  = 4 services → 3 sous la date + night flottant
    numDayServices =
    widget.pickerType == DateServicePickerType.detailed ? 4 : 3;

    initializeDateFormatting(widget.locale, null);
    _currentDateService = widget.initialSelectedDateService;
    widget.controller?.setDateServicePickerState(this);
    selectedDateStyle =
        widget.dateTextStyle.copyWith(color: widget.selectedTextColor);
    scrollController =
        ScrollController(initialScrollOffset: _getInitialOffset());
  }

  double _getInitialOffset() {
    if (_currentDateService != null) {
      final current = DateTime(
        _currentDateService!.date.year,
        _currentDateService!.date.month,
        _currentDateService!.date.day,
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

  bool _isDateSelected(DateTime date) =>
      _currentDateService != null &&
          DateUtils.isSameDay(date, _currentDateService!.date);

  bool _isServiceSelected(DateTime date, ServiceType service) =>
      _currentDateService != null &&
          Utils.isSameDateService(
            dateService: DateService(date: date, service: service),
            dateServiceSelected: _currentDateService!,
          );

  bool _hasNotif(DateTime date, {ServiceType? service}) {
    if (widget.datesOnNotification == null) return false;
    return widget.datesOnNotification!.any((e) {
      if (!DateUtils.isSameDay(e.date, date)) return false;
      if (service != null) return e.service == service;
      return true;
    });
  }

  void _onDateSelected(DateTime date) {
    final ds = DateService(date: date, service: ServiceType.all);
    widget.onDateServiceChange?.call(ds);
    setState(() => _currentDateService = ds);
  }

  void _onServiceSelected(DateService ds) {
    widget.onDateServiceChange?.call(ds);
    setState(() => _currentDateService = ds);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.daysCount,
        itemBuilder: (context, index) {
          final _d = widget.startDate.add(Duration(days: index));
          final date = DateTime(_d.year, _d.month, _d.day);
          final isDateSel = _isDateSelected(date);

          // Services du jour SANS night (les n-1 premiers)
          final dayServices = List.generate(numDayServices, (i) {
            return Utils.getServiceFromIndex(
              pickerType: widget.pickerType,
              index: i,
            );
          });

          return SizedBox(
            width: slotWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: _DateBlock(
                date: date,
                isSelected: isDateSel,
                dateTextStyle:
                isDateSel ? selectedDateStyle : widget.dateTextStyle,
                selectionColor: widget.selectionColor,
                backgroundColor: widget.backgroundColor,
                borderColor: widget.borderColor,
                displayNotif: _hasNotif(date),
                locale: widget.locale,
                services: dayServices,
                serviceIconColor: widget.serviceIconColor,
                isServiceSelected: (s) => _isServiceSelected(date, s),
                hasServiceNotif: (s) => _hasNotif(date, service: s),
                onDateTap: () => _onDateSelected(date),
                onServiceTap: (s) => _onServiceSelected(
                  DateService(date: date, service: s),
                ),
                nightOverflowWidth: nightOverflowWidth,
              ),
            ),
          );
        },
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
  final TextStyle dateTextStyle;
  final Color selectionColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool displayNotif;
  final String locale;
  final List<ServiceType> services;
  final Color? serviceIconColor;
  final bool Function(ServiceType) isServiceSelected;
  final bool Function(ServiceType) hasServiceNotif;
  final VoidCallback onDateTap;
  final ValueChanged<ServiceType> onServiceTap;
  final double nightOverflowWidth;

  const _DateBlock({
    required this.date,
    required this.isSelected,
    required this.dateTextStyle,
    required this.selectionColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.displayNotif,
    required this.locale,
    required this.services,
    required this.serviceIconColor,
    required this.isServiceSelected,
    required this.hasServiceNotif,
    required this.onDateTap,
    required this.onServiceTap,
    required this.nightOverflowWidth,
  });

  @override
  Widget build(BuildContext context) {
    final nightSel = isServiceSelected(ServiceType.night);

    return Container(
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
          // ── Header date ──────────────────────────────────────
          Expanded(
            flex: 5,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDateTap,
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: Colors.transparent)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
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
          ),

          // ── Séparateur ───────────────────────────────────────
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: isSelected
                ? selectionColor.withOpacity(0.4)
                : borderColor.withOpacity(0.4),
          ),

          // ── Services + Night overflow ────────────────────────
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final serviceWidth = (constraints.maxWidth - nightOverflowWidth / 2) / (services.length + 1);
                final nightSel = isServiceSelected(ServiceType.night);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Services normaux
                    Row(
                      children: [
                        SizedBox(width: nightOverflowWidth / 2),
                        ...services.map((service) {
                          final sel = isServiceSelected(service);
                          final notif = hasServiceNotif(service);

                          return SizedBox(
                            width: serviceWidth,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onServiceTap(service),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: sel
                                      ? selectionColor.withOpacity(0.25)
                                      : Colors.transparent,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        Utils.getIconService(service),
                                        width: 18,
                                        height: 18,
                                        color: sel ? Colors.white : serviceIconColor,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.error, size: 12),
                                      ),
                                    ),
                                    if (notif)
                                      Positioned(
                                        top: 2, right: 2,
                                        child: Container(
                                          height: 5, width: 5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                        // Placeholder pour le night (espace réservé)
                        SizedBox(width: serviceWidth),
                      ],
                    ),

                    // Night — positionné en absolu, déborde à droite
                    Positioned(
                      right: -nightOverflowWidth / 2,
                      top: 3,
                      bottom: 3,
                      width: serviceWidth + nightOverflowWidth / 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onServiceTap(ServiceType.night),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            color: nightSel
                                ? selectionColor.withOpacity(0.25)
                                : backgroundColor,
                            border: Border.all(
                              color: nightSel ? selectionColor : borderColor,
                              width: nightSel ? 1.5 : 0.5,
                            ),
                            // Fix NaN — pas de boxShadow si width/height pas encore calculés
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                  Utils.getIconService(ServiceType.night),
                                  width: 18,
                                  height: 18,
                                  color: nightSel ? Colors.white : serviceIconColor,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.nightlight_round, size: 16),
                                ),
                              ),
                              if (hasServiceNotif(ServiceType.night))
                                Positioned(
                                  top: 2, right: 2,
                                  child: Container(
                                    height: 5, width: 5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// Controller
// ================================================================
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
