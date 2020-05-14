import 'package:flutter/material.dart';
import 'package:med_reminder/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:med_reminder/models/meds.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Meds> _medsList;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Future onSelectNotification(String payload) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Alert'),
        content: Text('Content'),
      )
    );
  }

  showNotification() async {
    var android = AndroidNotificationDetails(
      'channel id', 'channel name', 'channel description'
    );
    var iOS = IOSNotificationDetails();
    var platform = NotificationDetails(android, iOS);
    var scheduledNotificationDateTime =
        new DateTime.now().add(Duration(seconds: 10));
    await flutterLocalNotificationsPlugin.schedule(0, 'Title ', 'Body', scheduledNotificationDateTime, platform);
  }

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _medName = TextEditingController();
  final _qty = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();

  static var _medTypes = ['Tablet', 'Syrup', 'Capsule', 'Injection'];
  var _currentselected = '';
  StreamSubscription<Event> _onMedsAddedSubscription;
  StreamSubscription<Event> _onMedsChangedSubscription;

  Query _medsQuery;

  //bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    this._currentselected = _medTypes[0];

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: onSelectNotification);

    //_checkEmailVerification();

    _medsList = List();
    _medsQuery = _database
        .reference()
        .child("meds")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onMedsAddedSubscription = _medsQuery.onChildAdded.listen(onEntryAdded);
    _onMedsChangedSubscription =
        _medsQuery.onChildChanged.listen(onEntryChanged);
  }

  // void _checkEmailVerification() async {
  //   final _isEmailVerified = await widget.auth.isEmailVerified();
  //   if (!_isEmailVerified) {
  //     _showVerifyEmailDialog();
  //   }
  // }

  // void _resentVerifyEmail() {
  //   widget.auth.sendEmailVerification();
  //   _showVerifyEmailSentDialog();
  // }

  // void _showVerifyEmailDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       // return object of type Dialog
  //       return AlertDialog(
  //         title: Text("Verify your account"),
  //         content: Text("Please verify account in the link sent to email"),
  //         actions: <Widget>[
  //           FlatButton(
  //             child: Text("Resent link"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               _resentVerifyEmail();
  //             },
  //           ),
  //           FlatButton(
  //             child: Text("Dismiss"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _showVerifyEmailSentDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       // return object of type Dialog
  //       return AlertDialog(
  //         title: Text("Verify your account"),
  //         content:
  //             Text("Link to verify account has been sent to your email"),
  //         actions: <Widget>[
  //           FlatButton(
  //             child: Text("Dismiss"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    _onMedsAddedSubscription.cancel();
    _onMedsChangedSubscription.cancel();
    super.dispose();
  }

  onEntryChanged(Event event) {
    var oldEntry = _medsList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _medsList[_medsList.indexOf(oldEntry)] =
          Meds.fromSnapshot(event.snapshot);
    });
  }

  onEntryAdded(Event event) {
    setState(() {
      _medsList.add(Meds.fromSnapshot(event.snapshot));
    });
  }

  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  addNewMeds(String medsName, String medsType, int medQty, String medTime,
      String medDay) {
    Meds meds =
        Meds(widget.userId, medsName, medsType, medQty, medTime, medDay, false);
    _database.reference().child("meds").push().set(meds.toJson());
  }

  updateMeds(Meds meds) {
    //Toggle completed
    meds.completed = !meds.completed;
    if (meds != null) {
      _database.reference().child("meds").child(meds.key).set(meds.toJson());
    }
  }

  deleteMeds(String medsId, int index) {
    _database.reference().child("meds").child(medsId).remove().then((_) {
      print("Delete $medsId successful");
      setState(() {
        _medsList.removeAt(index);
      });
    });
  }

  showAddMedsDialog(BuildContext context) {
    _medName.clear();
    _qty.clear();
    _time.clear();
    _date.clear();
    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            content: Container(
                height: 600.0,
                width: 500.0,
                padding: EdgeInsets.all(15.0),
                child: Column(children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          "Medicine type",
                          textScaleFactor: 1,
                        ),
                      ),
                      Container(
                        width: 10.0,
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          items: _medTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          value: _currentselected,
                          onChanged: (String newVal) {
                            setState(() {
                              _currentselected = newVal;
                            });
                          },
                          elevation: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Expanded(
                      child: TextField(
                    controller: _medName,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: 'Medicine Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  )),
                  SizedBox(
                    height: 10.0,
                  ),
                  Expanded(
                      child: TextField(
                          controller: _qty,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                          ))),
                  SizedBox(
                    height: 10.0,
                  ),
                  Expanded(
                      child: Column(children: <Widget>[
                    Text('Date'),
                    DateTimeField(
                      format: DateFormat("yyyy-MM-dd"),
                      controller: _date,
                      onShowPicker: (context, currentValue) {
                        return showDatePicker(
                            context: context,
                            firstDate: DateTime(1900),
                            initialDate: currentValue ?? DateTime.now(),
                            lastDate: DateTime(2100));
                      },
                    ),
                  ])),
                  SizedBox(
                    height: 10.0,
                  ),
                  Expanded(
                      child: Column(children: <Widget>[
                    Text('Time'),
                    DateTimeField(
                      format: DateFormat("HH:mm"),
                      controller: _time,
                      onShowPicker: (context, currentValue) async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              currentValue ?? DateTime.now()),
                        );
                        return DateTimeField.convert(time);
                      },
                    ),
                  ])),
                ])),
            actions: <Widget>[
              FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    addNewMeds(_medName.text, _currentselected,
                        int.parse(_qty.text), _time.text, _date.text);
                    showNotification();
                    Navigator.pop(context);
                  })
            ],
          );
        });
  }

  Widget showMedsList() {
    if (_medsList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _medsList.length,
          itemBuilder: (BuildContext context, int index) {
            String medsId = _medsList[index].key;
            String medName = _medsList[index].medName;
            String medType = _medsList[index].medType;
            int qty = _medsList[index].qty;
            String time = _medsList[index].time;
            String day = _medsList[index].day;
            bool completed = _medsList[index].completed;
            String userId = _medsList[index].userId;

            return Dismissible(
              key: Key(medsId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                deleteMeds(medsId, index);
              },
              child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Card(
                      child: ListTile(
                    title: Text(
                      medName,
                      style:
                          TextStyle(fontSize: 20.0, color: Colors.orange[300]),
                      textScaleFactor: 1.5,
                    ),
                    subtitle: Card(
                        child: Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Text(
                        'MedType: $medType \nQty: $qty'
                        '\nTime: $time \nDay: $day',
                        textScaleFactor: 1.5,
                        style: TextStyle(color: Colors.white),
                      ),
                    )),
                    trailing: IconButton(
                        alignment: Alignment.bottomRight,
                        icon: (completed)
                            ? Icon(
                                Icons.done_outline,
                                color: Colors.green,
                                size: 20.0,
                              )
                            : Icon(Icons.done, color: Colors.grey, size: 20.0),
                        onPressed: () {
                          updateMeds(_medsList[index]);
                        }),
                  ))),
            );
          });
    } else {
      return Center(
          child: Text(
        "Welcome. Add new medicine reminders",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28.0),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
        appBar: AppBar(
          title: Text('Med Reminder'),
          actions: <Widget>[
            FlatButton(
                child: Text('Logout',
                    style: TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: signOut)
          ],
        ),
        body: showMedsList(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showAddMedsDialog(context);
          },
          tooltip: 'Add Reminder',
          child: Icon(Icons.add),
        ));
  }
}

