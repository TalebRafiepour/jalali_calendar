import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persian_date/persian_date.dart';

typedef DateChangedCallback(int year, int month, int date);

const String _kDateFormatDefault = 'yyyy-mm-dd';

const double _kDatePickerHeight = 210.0;
const double _kDatePickerTitleHeight = 44.0;
const double _kDatePickerItemHeight = 36.0;
const double _kDatePickerFontSize = 18.0;

const int _kDefaultMinYear = 1300;
const int _kDefaultMaxYear = 1450;

const int _kMonthCount = 12;

const List<int> leapYearMonths = const <int>[1, 3, 5, 7, 8, 10, 12];

class DatePicker {
  static void showDatePicker(
    BuildContext context, {
    bool showTitleActions: true,
    int minYear: _kDefaultMinYear,
    int maxYear: _kDefaultMaxYear,
    int? initialYear,
    int? initialMonth,
    int? initialDay,
    required Widget cancel,
    required Widget confirm,
    required DateChangedCallback onChanged,
    required DateChangedCallback onConfirm,
    dateFormat: _kDateFormatDefault,
  }) {
    if (dateFormat == null || dateFormat.length == 0) {
      dateFormat = _kDateFormatDefault;
    }

    PersianDate now = PersianDate.pDate();
    if (initialYear == null) {
      initialYear = now.year;
    }
    if (initialMonth == null) {
      initialMonth = now.month;
    }
    if (initialDay == null) {
      initialDay = now.day;
    }

    Navigator.push(
      context,
      new _DatePickerRoute(
        showTitleActions: showTitleActions,
        minYear: minYear,
        maxYear: maxYear,
        initialYear: initialYear!,
        initialMonth: initialMonth!,
        initialDate: initialDay!,
        cancel: cancel,
        confirm: confirm,
        onChanged: onChanged,
        onConfirm: onConfirm,
        dateFormat: dateFormat,
        theme: Theme.of(context),
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
      ),
    );
  }
}

class _DatePickerRoute<T> extends PopupRoute<T> {
  _DatePickerRoute({
    required this.showTitleActions,
    required this.minYear,
    required this.maxYear,
    required this.initialYear,
    required this.initialMonth,
    required this.initialDate,
    required this.cancel,
    required this.confirm,
    required this.onChanged,
    required this.onConfirm,
    required this.theme,
    required this.barrierLabel,
    this.locale,
    required this.dateFormat,
    RouteSettings? settings,
  }) : super(settings: settings);

  final bool showTitleActions;
  final int minYear, maxYear, initialYear, initialMonth, initialDate;
  final Widget cancel, confirm;
  final DateChangedCallback onChanged;
  final DateChangedCallback onConfirm;
  final ThemeData theme;
  final String? locale;
  final String dateFormat;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get barrierDismissible => true;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = BottomSheet.createAnimationController(navigator!);
    return _animationController!;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    Widget bottomSheet = new MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _DatePickerComponent(
        minYear: minYear,
        maxYear: maxYear,
        initialYear: initialYear,
        initialMonth: initialMonth,
        initialDate: initialDate,
        cancel: cancel,
        confirm: confirm,
        onChanged: onChanged,
        locale: locale,
        dateFormat: dateFormat,
        route: this,
      ),
    );
    if (theme != null) {
      bottomSheet = new Theme(data: theme, child: bottomSheet);
    }
    return bottomSheet;
  }
}

class _DatePickerComponent extends StatefulWidget {
  _DatePickerComponent(
      {Key? key,
      required this.route,
      this.minYear: _kDefaultMinYear,
      this.maxYear: _kDefaultMaxYear,
      this.initialYear: -1,
      this.initialMonth: 1,
      this.initialDate: 1,
      this.cancel,
      this.confirm,
      this.onChanged,
      this.locale,
      required this.dateFormat});

  final DateChangedCallback? onChanged;
  final int minYear, maxYear, initialYear, initialMonth, initialDate;

  final Widget? cancel;
  final Widget? confirm;

  final _DatePickerRoute route;

  final String? locale;
  final String dateFormat;

  @override
  State<StatefulWidget> createState() => _DatePickerState(this.minYear,
      this.maxYear, this.initialYear, this.initialMonth, this.initialDate);
}

class _DatePickerState extends State<_DatePickerComponent> {
  final int minYear, maxYear;
  int _currentYear, _currentMonth, _currentDate;
  late int _dateCountOfMonth;
  late FixedExtentScrollController yearScrollCtrl,
      monthScrollCtrl,
      dateScrollCtrl;

  _DatePickerState(this.minYear, this.maxYear, this._currentYear,
      this._currentMonth, this._currentDate) {
    if (this._currentYear == -1) {
      this._currentYear = this.minYear;
    }
    if (this._currentYear < this.minYear) {
      this._currentYear = this.minYear;
    }
    if (this._currentYear > this.maxYear) {
      this._currentYear = this.maxYear;
    }

    if (this._currentMonth < 1) {
      this._currentMonth = 1;
    }
    if (this._currentMonth > 12) {
      this._currentMonth = 12;
    }

    if (this._currentDate < 1) {
      this._currentDate = 1;
    }
    if (this._currentDate > 31) {
      this._currentDate = 31;
    }

    yearScrollCtrl = new FixedExtentScrollController(
        initialItem: _currentYear - this.minYear);
    monthScrollCtrl =
        new FixedExtentScrollController(initialItem: _currentMonth - 1);
    dateScrollCtrl =
        new FixedExtentScrollController(initialItem: _currentDate - 1);
    _dateCountOfMonth = _calcDateCount();
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new AnimatedBuilder(
        animation: widget.route.animation!,
        builder: (BuildContext context, Widget? child) {
          return new ClipRect(
            child: new CustomSingleChildLayout(
              delegate: new _BottomPickerLayout(widget.route.animation!.value,
                  showTitleActions: widget.route.showTitleActions),
              child: new GestureDetector(
                child: Material(
                  color: Colors.transparent,
                  child: _renderPickerView(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _setYear(int index) {
    int year = widget.minYear + index;
    if (_currentYear != year) {
      _currentYear = year;
      _notifyDateChanged();
    }
  }

  void _setMonth(int index) {
    int month = index + 1;
    if (_currentMonth != month) {
      _currentMonth = month;
      int dateCount = _calcDateCount();
      if (_dateCountOfMonth != dateCount) {
        setState(() {
          _dateCountOfMonth = dateCount;
        });
      }
      if (_currentDate > dateCount) {
        _currentDate = dateCount;
      }
      _notifyDateChanged();
    }
  }

  void _setDate(int index) {
    int date = index + 1;
    if (_currentDate != date) {
      _currentDate = date;
      _notifyDateChanged();
    }
  }

  static const List<int> _daysInMonth = <int>[
    31,
    31,
    31,
    31,
    31,
    31,
    30,
    30,
    30,
    30,
    30,
    -1
  ];
  static const List<int> _kabise = <int>[1, 5, 9, 13, 17, 22, 26, 30];

  int _calcDateCount() {
    if (_currentMonth == 12) {
      var modeyear = _currentYear % 33;
      if (_kabise.indexOf(modeyear) != -1) {
        return 30;
      }
      return 29;
    }
    return _daysInMonth[_currentMonth - 1];
  }

  void _notifyDateChanged() {
    if (widget.onChanged != null) {
      widget.onChanged?.call(_currentYear, _currentMonth, _currentDate);
    }
  }

  Widget _renderPickerView() {
    Widget itemView = _renderItemView();
    if (widget.route.showTitleActions) {
      return Column(
        children: <Widget>[
          _renderTitleActionsView(),
          itemView,
        ],
      );
    }
    return itemView;
  }

  Widget _renderYearsPickerComponent(String yearAppend) {
    return new Expanded(
      flex: 1,
      child: Container(
        padding: EdgeInsets.all(8.0),
        height: _kDatePickerHeight,
        decoration: BoxDecoration(color: Colors.white),
        child: CupertinoPicker(
          backgroundColor: Colors.white,
          scrollController: yearScrollCtrl,
          itemExtent: _kDatePickerItemHeight,
          onSelectedItemChanged: (int index) {
            _setYear(index);
          },
          children:
              List.generate(widget.maxYear - widget.minYear + 1, (int index) {
            return Container(
              height: _kDatePickerItemHeight,
              alignment: Alignment.center,
              child: Text(
                '${widget.minYear + index}$yearAppend',
                style: TextStyle(
                    color: Color(0xFF000046), fontSize: _kDatePickerFontSize),
                textAlign: TextAlign.start,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _renderMonthsPickerComponent(String monthAppend, {String? format}) {
    return new Expanded(
      flex: 1,
      child: Container(
          padding: EdgeInsets.all(8.0),
          height: _kDatePickerHeight,
          decoration: BoxDecoration(color: Colors.white),
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            scrollController: monthScrollCtrl,
            itemExtent: _kDatePickerItemHeight,
            onSelectedItemChanged: (int index) {
              _setMonth(index);
            },
            children: List.generate(_kMonthCount, (int index) {
              return Container(
                height: _kDatePickerItemHeight,
                alignment: Alignment.center,
                child: Row(
                  children: <Widget>[
                    new Expanded(
                        child: Text(
                      (format == null)
                          // index is 0,1,2...11  month is 1,2,3...12
                          ? '${index + 1}$monthAppend'
                          : '${_formatMonthComplex(index, format)}$monthAppend',
                      style: TextStyle(
                          color: Color(0xFF000046),
                          fontSize: _kDatePickerFontSize),
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ))
                  ],
                ),
              );
            }),
          )),
    );
  }

  Widget _renderDaysPickerComponent(String dayAppend) {
    return new Expanded(
      flex: 1,
      child: Container(
          padding: EdgeInsets.all(8.0),
          height: _kDatePickerHeight,
          decoration: BoxDecoration(color: Colors.white),
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            scrollController: dateScrollCtrl,
            itemExtent: _kDatePickerItemHeight,
            onSelectedItemChanged: (int index) {
              _setDate(index);
            },
            children: List.generate(_dateCountOfMonth, (int index) {
              return Container(
                height: _kDatePickerItemHeight,
                alignment: Alignment.center,
                child: Text(
                  "${index + 1}$dayAppend",
                  style: TextStyle(
                      color: Color(0xFF000046), fontSize: _kDatePickerFontSize),
                  textAlign: TextAlign.start,
                ),
              );
            }),
          )),
    );
  }

  Widget _renderItemView() {
    String yearAppend = "";
    String monthAppend = "";
    String dayAppend = "";

    List<Widget> pickers = [];
    List<String> formatSplit = widget.dateFormat.split('-');
    for (int i = 0; i < formatSplit.length; i++) {
      var format = formatSplit[i];
      if (format.contains("yy")) {
        pickers.add(_renderYearsPickerComponent(yearAppend));
      } else if (format.contains("mm")) {
        pickers.add(_renderMonthsPickerComponent(monthAppend, format: format));
      } else if (format.contains("dd")) {
        pickers.add(_renderDaysPickerComponent(dayAppend));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: pickers,
    );
  }

  String _digits(int value, int length) {
    String ret = '$value';
    if (ret.length < length) {
      ret = '0' * (length - ret.length) + ret;
    }
    return ret;
  }

  // Title View
  Widget _renderTitleActionsView() {
    String done = "تایید";
    String cancel = "لغو";

    Widget? cancelWidget = this.widget.cancel;
    if (cancelWidget == null) {
      cancelWidget = Text(
        '$cancel',
        style: TextStyle(
          color: Theme.of(context).unselectedWidgetColor,
          fontSize: 16.0,
        ),
      );
    }

    Widget? confirmWidget = this.widget.confirm;
    if (confirmWidget == null) {
      confirmWidget = Text(
        '$done',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 16.0,
        ),
      );
    }

    return Container(
      height: _kDatePickerTitleHeight,
      decoration: BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            height: _kDatePickerTitleHeight,
            child: TextButton(
              child: cancelWidget,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Container(
            height: _kDatePickerTitleHeight,
            child: TextButton(
              child: confirmWidget,
              onPressed: () {
                if (widget.route.onConfirm != null) {
                  widget.route.onConfirm(
                      int.parse(_digits(_currentYear, 2)),
                      int.parse(_digits(_currentMonth, 2)),
                      int.parse(_digits(_currentDate, 2)));
                }
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // format month
  String _formatMonthComplex(int month, String format) {
    if (widget.locale == null) {
      return (month + 1).toString();
    }

    List<String> months = ["months"];
    if (months == null) {
      return (month + 1).toString();
    }

    if (format.length <= 2) {
      return (month + 1).toString();
    } else if (format.length <= 3) {
      return months[month].substring(0, 3);
    } else {
      return months[month];
    }
  }
}

class _BottomPickerLayout extends SingleChildLayoutDelegate {
  _BottomPickerLayout(this.progress,
      {this.itemCount = 0, required this.showTitleActions});

  final double progress;
  final int itemCount;
  final bool showTitleActions;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double maxHeight = _kDatePickerHeight;
    if (showTitleActions) {
      maxHeight += _kDatePickerTitleHeight;
    }

    return new BoxConstraints(
        minWidth: constraints.maxWidth,
        maxWidth: constraints.maxWidth,
        minHeight: 0.0,
        maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double height = size.height - childSize.height * progress;
    return new Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_BottomPickerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
