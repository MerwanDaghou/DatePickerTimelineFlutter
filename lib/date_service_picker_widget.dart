import 'package:date_picker_timeline/extra/color.dart';
import 'package:date_picker_timeline/extra/style.dart';
import 'package:date_picker_timeline/gestures/tap.dart';
import 'package:date_picker_timeline/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'date_type.dart';

enum DateServicePickerType { detailed, grouped }

/// Un service RÉELLEMENT ouvert un jour donné (fourni par l'app via
/// [DateServicePicker.dayServicesBuilder]) : la clé technique reste [service],
/// mais on affiche [label] (ex. « 11h–14h30 ») — bien plus parlant que 5 icônes
/// abstraites. [isEvent] = créneau d'un événement (icône distincte).
class DayService {
  final ServiceType service;
  final String label;
  final bool isEvent;

  /// Le créneau TRAVERSE minuit (ex. 22h–06h) : la chip déborde sur le bloc du
  /// jour suivant, comme l'ancienne « nuit » flottante → on comprend que c'est la
  /// nuit ENTRE ce jour et le suivant.
  final bool crossesMidnight;
  const DayService(
      {required this.service,
      required this.label,
      this.isEvent = false,
      this.crossesMidnight = false});
}

typedef DayServicesBuilder = List<DayService> Function(DateTime date);

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

  /// Si fourni : n'affiche que les services réels du jour (chips horaires) ; un
  /// jour sans service n'a pas de rangée (le jour seul se sélectionne). Sinon :
  /// comportement historique (5 icônes fixes).
  final DayServicesBuilder? dayServicesBuilder;

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
    this.dayServicesBuilder,
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
  double get nightOverflowWidth => (widget.width / numDayServices) + 18.0;

  // Largeur totale d'un slot = bloc + espace pour que le night du bloc
  // précédent puisse déborder sur ce slot
  double get slotWidth => widget.width + nightOverflowWidth / 2;

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
    // Tap sur un service d'un AUTRE jour que celui sélectionné → on sélectionne
    // d'abord le jour entier (tous les services). Le service ne se choisit que
    // sur un jour déjà sélectionné (évite « mauvais service → 0 réservation »).
    if (!_isDateSelected(ds.date)) {
      _onDateSelected(ds.date);
      return;
    }
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
                customServices: widget.dayServicesBuilder?.call(date),
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
  final List<DayService>? customServices;

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
    this.customServices,
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
        color: isSelected ? selectionColor.withOpacity(0.12) : backgroundColor,
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

          // ── Services RÉELS du jour (chips horaires) ──────────
          if (customServices != null)
            Expanded(flex: 4, child: _customServicesRow(context))
          else
            // ── Services + Night overflow ────────────────────────
            Expanded(
              flex: 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final serviceWidth =
                      (constraints.maxWidth - nightOverflowWidth / 2) /
                          (services.length + 1);
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
                                          color: sel
                                              ? Colors.white
                                              : serviceIconColor,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.error, size: 12),
                                        ),
                                      ),
                                      if (notif)
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            height: 5,
                                            width: 5,
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
                                    color: nightSel
                                        ? Colors.white
                                        : serviceIconColor,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.nightlight_round,
                                        size: 16),
                                  ),
                                ),
                                if (hasServiceNotif(ServiceType.night))
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      height: 5,
                                      width: 5,
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

  /// Chips = services réellement ouverts ce jour (label horaires). Aucun → le
  /// bloc n'affiche que la date (tap = jour entier).
  Widget _customServicesRow(BuildContext context) {
    final list = customServices!;
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }
    // Chips « dans la journée » + (au plus) une chip qui traverse minuit,
    // positionnée en absolu pour DÉBORDER sur le jour suivant.
    final inDay = list.where((d) => !d.crossesMidnight).toList();
    final DayService? cross = list.where((d) => d.crossesMidnight).isEmpty
        ? null
        : list.lastWhere((d) => d.crossesMidnight);
    return LayoutBuilder(builder: (context, constraints) {
      final n = inDay.length + (cross != null ? 1 : 0);
      final chipWidth =
          (constraints.maxWidth - nightOverflowWidth / 2 - 12) / n;
      return Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                SizedBox(width: nightOverflowWidth / 2),
                ...inDay
                    .map((ds) => SizedBox(width: chipWidth, child: _chip(ds))),
                if (cross != null) SizedBox(width: chipWidth), // place réservée
              ],
            ),
            if (cross != null)
              Positioned(
                right: -nightOverflowWidth / 2 - 6,
                top: 0,
                bottom: 0,
                width: chipWidth + nightOverflowWidth / 2,
                child: _chip(cross, crossing: true),
              ),
          ],
        ),
      );
    });
  }

  Widget _chip(DayService ds, {bool crossing = false}) {
    final sel = isServiceSelected(ds.service);
    final notif = hasServiceNotif(ds.service);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onServiceTap(ds.service),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: crossing
              ? const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12))
              : BorderRadius.circular(8),
          color: sel
              ? selectionColor
              : (crossing
                  ? backgroundColor
                  : selectionColor.withOpacity(isSelected ? 0.10 : 0.06)),
          border: Border.all(
            color: sel
                ? selectionColor
                : borderColor.withOpacity(crossing ? 1 : 0.6),
            width: sel ? 1.5 : 0.5,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ds.isEvent)
                    Icon(Icons.local_bar_rounded,
                        size: 12, color: sel ? Colors.white : serviceIconColor)
                  else
                    Image.asset(
                      Utils.getIconService(ds.service),
                      width: 12,
                      height: 12,
                      color: sel ? Colors.white : serviceIconColor,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      ds.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : serviceIconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (notif)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  height: 5,
                  width: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red,
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

enum ServiceType { all, noon, afternoon, daytime, before, night, after }
