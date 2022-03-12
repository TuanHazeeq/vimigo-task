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
  final ValueNotifier<String> _notify = ValueNotifier('');
  bool timeset = true;
  var message = "";

  late ScrollController? _scrollController = ScrollController();

  _loadBool() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      timeset = prefs.getBool('option')!;
    });
  }

  _savebool() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('option', timeset);
  }

  @override
  void initState() {
    _loadBool();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController!.offset >=
            _scrollController!.position.maxScrollExtent) {
          _notify.value = "Reach the bottom";
        } else {
          _notify.value = '';
        }
      });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> data = FirebaseFirestore.instance
      .collection('contacts')
      .orderBy('check-in', descending: true)
      .snapshots();
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
            SizedBox(
              height: 200.0,
              child: RefreshIndicator(
                onRefresh: loadData,
                child: Expanded(
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
                      itemList.shuffle();
                      itemList.length = 5;

                      return ListView(
                        children: itemList.map((doc) {
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
                  ),
                ),
              ),
            ),
            const Divider(
              thickness: 5.0,
              color: Colors.black,
            ),
            Expanded(
              child: StreamBuilder(
                stream: data,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return ListView(
                    controller: _scrollController,
                    shrinkWrap: true,
                    children: snapshot.data!.docs.map((doc) {
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
          ],
        ),
      ),
    );
  }
}
