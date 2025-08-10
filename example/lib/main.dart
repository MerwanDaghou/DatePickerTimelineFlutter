import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Date Picker Timeline Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateServicePickerController _controller = DateServicePickerController();

  DateService _selectedValue = DateService(date: DateTime.now(), service: ServiceType.all);


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title!),
        ),
        body: Container(
          padding: EdgeInsets.all(20.0),
          color: Colors.blueGrey[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("You Selected:"),
              Padding(
                padding: EdgeInsets.all(10),
              ),
              Text("${_selectedValue.date}\n${_selectedValue.service}", textAlign: TextAlign.center,),
              Padding(
                padding: EdgeInsets.all(20),
              ),
          DateServicePicker(
              DateTime.now(),
              pickerType: DateServicePickerType.detailed,
              controller: _controller,
              initialSelectedDateService: _selectedValue,
              selectionColor: Color(0xFFC70EBC),
              selectedTextColor: Colors.white,
              daysCount: 21,
              datesOnNotification: [DateService(date: DateTime.now(), service: ServiceType.noon)],
              onDateServiceChange: (dateService) {
                // New date selected
                setState(() {
                  _selectedValue = dateService;
                });
                debugPrint("new selected value : ${dateService.date} - ${dateService.service}");
              },
            )
              /*
              Container(
                child: DatePicker(
                  DateTime.now(),
                  width: 60,
                  height: 90,
                  controller: _controller,
                  initialSelectedDate: DateTime.now(),
                  selectionColor: Colors.black,
                  selectedTextColor: Colors.white,
                  inactiveDates: [
                    DateTime.now().add(Duration(days: 3)),
                    DateTime.now().add(Duration(days: 4)),
                    DateTime.now().add(Duration(days: 7))
                  ],
                  onDateChange: (date) {
                    // New date selected
                    setState(() {
                      _selectedValue = date;
                    });
                  },
                ),
              ),*/
            ],
          ),
        ));
  }
}
