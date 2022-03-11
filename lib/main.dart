import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var message = "";

  late ScrollController? _scrollController = ScrollController();

  @override
  void initState(){
    _scrollController = ScrollController()..addListener(() {
      if(_scrollController!.offset >= _scrollController!.position.maxScrollExtent){
        setState(() {
          message = "Reach the bottom";
        });
      }else{
        setState(() {
          message = "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          title: const Text('Contact List'),
        ),
        body: Column(
          children: [
            Container(
              height: 50.0,
              color: Colors.green,
              child: Center(child: Text(message),),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('contacts').snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                  if(!snapshot.hasData){
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
            
                  return ListView(
                    controller: _scrollController,
                    shrinkWrap: true,
                  children: 
                  snapshot.data!.docs.map((doc) {
                    DateTime date = DateTime.parse(doc['check-in'].toDate().toString());
                    var time = DateFormat('dd MMM yyyy hh:mm').format(date);
                    return Center(
                      child: ListTile(
                        title: Text('Name: '+doc['user']),
                        subtitle: Text('Phone Number: '+doc['phone']+'\nCheck-In: '+time.toString()),
                        trailing: TextButton(
                          child: const Text('Share'),
                          onPressed: () async {
                            await Share.share('Name:'+doc['user']+'\nPhone:'+doc['phone']);
                          }
                        ),
                        
                      )
                    );
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

