import 'dart:ui' as ui;
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

  // ── Mode compact (services réels) ──────────────────────────────────────
  static const TextStyle _segStyle = TextStyle(
      fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: -0.2);
  static const double _segGap = 4, _segPad = 18, _segIcon = 15, _dayMin = 88;

  /// Largeur d'un segment = texte mesuré + icône + padding (jamais tronqué).
  double _segWidth(DayService ds) {
    final tp = TextPainter(
        text: TextSpan(text: ds.label, style: _segStyle),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr)
      ..layout();
    return tp.width + _segIcon + _segPad;
  }

  DayService? _crossOf(List<DayService> l) {
    for (final d in l.reversed) {
      if (d.crossesMidnight) return d;
    }
    return null;
  }

  /// Un jour = [gauche : moitié de la nuit de la VEILLE] + segments du jour +
  /// [droite : moitié de sa propre nuit, l'autre moitié déborde sur le lendemain].
  double _slotWidthFor(DateTime date) {
    final b = widget.dayServicesBuilder;
    if (b == null) return slotWidth;
    final list = b(date);
    final prevCross = _crossOf(b(date.subtract(const Duration(days: 1))));
    double w = 12;
    if (prevCross != null) w += _segWidth(prevCross) / 2 + _segGap;
    final cross = _crossOf(list);
    for (final d in list) {
      if (identical(d, cross)) continue;
      w += _segWidth(d) + _segGap;
    }
    if (cross != null) w += _segWidth(cross) / 2 + _segGap;
    return w < _dayMin ? _dayMin : w;
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
      if (diff > 0) {
        if (widget.dayServicesBuilder == null) return diff * slotWidth;
        double off = 0;
        for (int i = 0; i < diff; i++) {
          off += _slotWidthFor(first.add(Duration(days: i)));
        }
        return off;
      }
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

          if (widget.dayServicesBuilder != null) {
            final list = widget.dayServicesBuilder!(date);
            final prevCross = _crossOf(widget
                .dayServicesBuilder!(date.subtract(const Duration(days: 1))));
            return SizedBox(
              width: _slotWidthFor(date),
              child: _CompactDay(
                date: date,
                isSelected: isDateSel,
                dateTextStyle: widget.dateTextStyle,
                selectionColor: widget.selectionColor,
                borderColor: widget.borderColor,
                serviceIconColor: widget.serviceIconColor,
                displayNotif: _hasNotif(date),
                locale: widget.locale,
                services: list,
                prevCrossHalf:
                    prevCross == null ? 0 : _segWidth(prevCross) / 2 + _segGap,
                segWidth: _segWidth,
                segStyle: _segStyle,
                segGap: _segGap,
                isServiceSelected: (s) => _isServiceSelected(date, s),
                hasServiceNotif: (s) => _hasNotif(date, service: s),
                onDateTap: () => _onDateSelected(date),
                onServiceTap: (s) => _onServiceSelected(
                  DateService(date: date, service: s),
                ),
              ),
            );
          }

          return SizedBox(
            width: _slotWidthFor(date),
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

// ================================================================
// _CompactDay — mode « services réels » : bande continue, sans cartes.
//  ligne 1 : le jour (tap = jour entier)          ligne 2 : segments horaires
//  la nuit (traverse minuit / commence après minuit) est À CHEVAL sur la
//  frontière avec le lendemain → « la nuit entre ce jour et le suivant ».
// ================================================================
class _CompactDay extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final TextStyle dateTextStyle;
  final Color selectionColor;
  final Color borderColor;
  final Color? serviceIconColor;
  final bool displayNotif;
  final String locale;
  final List<DayService> services;
  final double prevCrossHalf;
  final double Function(DayService) segWidth;
  final TextStyle segStyle;
  final double segGap;
  final bool Function(ServiceType) isServiceSelected;
  final bool Function(ServiceType) hasServiceNotif;
  final VoidCallback onDateTap;
  final ValueChanged<ServiceType> onServiceTap;

  const _CompactDay({
    required this.date,
    required this.isSelected,
    required this.dateTextStyle,
    required this.selectionColor,
    required this.borderColor,
    required this.serviceIconColor,
    required this.displayNotif,
    required this.locale,
    required this.services,
    required this.prevCrossHalf,
    required this.segWidth,
    required this.segStyle,
    required this.segGap,
    required this.isServiceSelected,
    required this.hasServiceNotif,
    required this.onDateTap,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    DayService? cross;
    for (final d in services.reversed) {
      if (d.crossesMidnight) {
        cross = d;
        break;
      }
    }
    // Seul le DERNIER segment nocturne est à cheval ; un autre segment qui
    // traverserait aussi minuit (rare) reste affiché dans le jour.
    final inDay = services.where((d) => !identical(d, cross)).toList();
    final crossW = cross == null ? 0.0 : segWidth(cross);
    final dayLabel =
        "${DateFormat("E", locale).format(date).toUpperCase()} ${date.day} "
        "${DateFormat("MMM", locale).format(date).toUpperCase()}";

    return Column(
      children: [
        // ── Jour ──
        Expanded(
          flex: 5,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDateTap,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? selectionColor.withOpacity(0.18)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: dateTextStyle.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color:
                            isSelected ? selectionColor : dateTextStyle.color,
                      ),
                      maxLines: 1,
                    ),
                    if (displayNotif) ...[
                      const SizedBox(width: 5),
                      Container(
                        height: 6,
                        width: 6,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Segments ──
        Expanded(
          flex: 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  SizedBox(width: 6 + prevCrossHalf),
                  ...inDay.map((d) => Padding(
                        padding: EdgeInsets.only(right: segGap),
                        child: SizedBox(width: segWidth(d), child: _seg(d)),
                      )),
                  if (cross != null) SizedBox(width: crossW / 2),
                ],
              ),
              if (cross != null)
                Positioned(
                  right: -(crossW / 2) - 6 + segGap,
                  top: 0,
                  bottom: 0,
                  width: crossW,
                  child: _seg(cross, night: true),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seg(DayService ds, {bool night = false}) {
    final sel = isServiceSelected(ds.service);
    final notif = hasServiceNotif(ds.service);
    final Color fg = sel ? Colors.white : (serviceIconColor ?? Colors.white);
    final Color bg = sel
        ? selectionColor
        : (ds.isEvent
            ? selectionColor.withOpacity(0.22)
            : borderColor.withOpacity(night ? 0.22 : 0.14));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onServiceTap(ds.service),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: bg,
          border: night && !sel
              ? Border.all(color: selectionColor.withOpacity(0.55), width: 1)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ds.isEvent)
                    Icon(Icons.local_bar_rounded, size: 13, color: fg)
                  else
                    Image.asset(
                      Utils.getIconService(ds.service),
                      width: 13,
                      height: 13,
                      color: fg,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  const SizedBox(width: 4),
                  Text(ds.label,
                      maxLines: 1, style: segStyle.copyWith(color: fg)),
                ],
              ),
            ),
            if (notif)
              Positioned(
                top: 2,
                right: 3,
                child: Container(
                  height: 5,
                  width: 5,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
