import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //string for reaching bottom of listview
  final ValueNotifier<String> _notify = ValueNotifier('');
  //int for number of contact listview
  final ValueNotifier<int> _limiter = ValueNotifier(10);
  //bool for time format
  bool timeset = true;

  late ScrollController? _scrollController = ScrollController();

  //load chosen time format
  _loadBool() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      timeset = prefs.getBool('option')!;
    });
  }

  //save chosen time format
  _savebool() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('option', timeset);
  }

  @override
  void initState() {
    //load chosen time format at start of app
    _loadBool();

    //scroll controller to detect end of scroll to load more list or show end of scroll
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController!.offset >=
            _scrollController!.position.maxScrollExtent) {
          //show this message when end of scroll
          _notify.value = "You have reached end of the list";
          //add to the limit of contact shown when scroll to the end
          _limiter.value = _limiter.value + 10;
        } else {
          _notify.value = '';
        }
      });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> data = FirebaseFirestore.instance
      .collection('contacts')
      .orderBy('check-in', descending: true)
      .snapshots();

  //load stream for pull to refresh
  Future<void> loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      data = FirebaseFirestore.instance
          .collection('contacts')
          .orderBy('check-in', descending: true)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          title: const Text('Contact List'),
          actions: [
            //toggle time format
            IconButton(
              icon: const Icon(Icons.watch),
              onPressed: () {
                setState(() {
                  timeset = !timeset;
                  _savebool();
                });
              },
            )
          ],
        ),
        body: Column(
          children: [
            //show 5 random contacts
            SizedBox(
              height: 200.0,
              //pull to refresh widget
              child: RefreshIndicator(
                onRefresh: loadData,
                child: StreamBuilder(
                  stream: data,
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    List<QueryDocumentSnapshot<Object?>> itemList =
                        snapshot.data!.docs;
                    //randomize data and take 5 data only
                    itemList.shuffle();
                    itemList.length = 5;
                    //display 5 random contacts
                    return ListView(
                      children: itemList.map((doc) {
                        DateTime date =
                            DateTime.parse(doc['check-in'].toDate().toString());
                        var ago = timeset
                            ? timeago.format(date)
                            : DateFormat('dd MMM yyyy hh:mm').format(date);
                        return Center(
                            child: ListTile(
                          title: Text('Name: ' + doc['user']),
                          subtitle: Text('Phone Number: ' +
                              doc['phone'] +
                              '\nCheck-In: ' +
                              ago.toString()),
                          trailing: TextButton(
                              child: const Text('Share'),
                              onPressed: () async {
                                await Share.share('Name:' +
                                    doc['user'] +
                                    '\nPhone:' +
                                    doc['phone']);
                              }),
                        ));
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            const Divider(
              thickness: 5.0,
              color: Colors.black,
            ),
            Expanded(
              //use value listenable builder to rebuild only this widget when end of scroll to show more contacts if available
              child: ValueListenableBuilder(
                builder: (BuildContext context, value, Widget? child) {
                  return StreamBuilder(
                    //limit for 10 contacts and add when scroll to end using notifier variable
                    stream: FirebaseFirestore.instance
                        .collection('contacts')
                        .orderBy('check-in', descending: true)
                        .limit(value as int)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ListView(
                        //add scroll controller to detect end of scroll
                        controller: _scrollController,
                        shrinkWrap: true,
                        children: snapshot.data!.docs.map((doc) {
                          DateTime date = DateTime.parse(
                              doc['check-in'].toDate().toString());
                          var ago = timeset
                              ? timeago.format(date)
                              : DateFormat('dd MMM yyyy hh:mm').format(date);
                          return Center(
                              child: ListTile(
                            title: Text('Name: ' + doc['user']),
                            subtitle: Text('Phone Number: ' +
                                doc['phone'] +
                                '\nCheck-In: ' +
                                ago.toString()),
                            trailing: TextButton(
                                child: const Text('Share'),
                                onPressed: () async {
                                  await Share.share('Name:' +
                                      doc['user'] +
                                      '\nPhone:' +
                                      doc['phone']);
                                }),
                          ));
                        }).toList(),
                      );
                    },
                  );
                },
                //this widget rebuild if this value notifier changed
                valueListenable: _limiter,
              ),
            ),
            //rebuild this widget only when reach end of scroll to show message
            ValueListenableBuilder(
              builder: (BuildContext context, value, Widget? child) {
                return Container(
                  height: 50.0,
                  color: Colors.green,
                  child: Center(
                    child: Text(value.toString()),
                  ),
                );
              },
              valueListenable: _notify,
            ),
          ],
        ),
      ),
    );
  }
}
