import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
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
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];

  double extractPrice(String message) {
    final matches = RegExp(r'(\d+\.\d+)').firstMatch(message);
    if (matches != null) {
      return double.parse(matches.group(0)!);
    }
    return 0.0; // or return null, depending on your use case
  }

  // Future<void> pushSmsToFirebase(SmsMessage message) async {
  //   await FirebaseFirestore.instance.collection('transactions').add({
  //     'category_name': message.sender,
  //     'date': message.date,
  //     'price': extractPrice(message.body!),
      
  //     // add other fields as needed
  //   });
  // }
  


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SMS Inbox App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SMS Inbox Example'),
        ),
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: _messages.isNotEmpty
              ? _MessagesListView(
                  messages: _messages,
                )
              : Center(
                  child: Text(
                    'No messages to show.\n Tap refresh button...',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var permission = await Permission.sms.status;
            if (permission.isGranted) {
              final messages = await _query.querySms(
                kinds: [
                  SmsQueryKind.inbox,
                  SmsQueryKind.sent,
                ],
                count: 10,
              );
              debugPrint('sms inbox messages: ${messages.length}');

              // Filter transactional messages based on keywords and exclude certain messages
              final transactionalMessages = _filterTransactionalMessages(
                messages,
                exclusionKeywords: [
                  'added to your zepto wallet', 
                  'promo', 
                  'balance inquiry', 
                  'service alert', 
                  'non-transactional',
                  'failed',
                  'declined',
                  'reversed',
                  'credited',
                  'credited to your account',
                  'will be deducted', 
                  'will be debited',
                ],
              );
              setState(() => _messages = transactionalMessages);

              for (var message in _messages) {
                final double price = extractPrice(message.body!);
                final String sender = message.sender!;
                final Timestamp date = Timestamp.fromDate(message.date!);

                final QuerySnapshot result = await FirebaseFirestore.instance
                  .collection('transactions')
                  .where('category_name', isEqualTo: sender)
                  .where('date', isEqualTo: date)
                  .where('price', isEqualTo: price)
                  .get();

                final List<DocumentSnapshot> document = result.docs;
                if (document.length == 0) {
                  await FirebaseFirestore.instance.collection('transactions').add({
                    'category_name': sender,
                    'date': date,
                    'price': price,
                  });
                }
              }

            } else {  
              await Permission.sms.request();
            }
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  List<SmsMessage> _filterTransactionalMessages(List<SmsMessage> messages, {List<String> exclusionKeywords = const []}) {
    // Define keywords or patterns for transactional messages
    final transactionKeywords = ['purchase', 'transaction', 'payment', 'debit'];

    // Filter messages containing transactional keywords and exclude certain messages
    final transactionalMessages = messages.where((message) {
      final lowercaseBody = message.body!.toLowerCase();

      // Check for exclusion keywords
      if (exclusionKeywords.any((keyword) => lowercaseBody.contains(keyword))) {
        return false;
      }

      return transactionKeywords.any((keyword) => lowercaseBody.contains(keyword));
    }).toList();

    // Extract relevant details from transactional messages
    return transactionalMessages;
  }
}

class _MessagesListView extends StatefulWidget {
  _MessagesListView({
    Key? key,
    required this.messages,
  }) : super(key: key);

  final List<SmsMessage> messages;

  @override
  _MessagesListViewState createState() => _MessagesListViewState();
}

class _MessagesListViewState extends State<_MessagesListView> {
  double extractPrice(String message) {
    final matches = RegExp(r'(\d+\.\d+)').firstMatch(message);
    if (matches != null) {
      return double.parse(matches.group(0)!);
    }
    return 0.0; // or return null, depending on your use case
  }


  @override
  Widget build(BuildContext context) {
    final messagesByDate = groupBy<SmsMessage, DateTime>(
      widget.messages,
      (messages) => DateTime(
        messages.date!.year,
        messages.date!.month,
        messages.date!.day,
      )
    );

    return ListView.builder(
      shrinkWrap: true,
      itemCount: messagesByDate.keys.length,
      itemBuilder: (BuildContext context, int index) {
        final date = messagesByDate.keys.elementAt(index);
        final messages = messagesByDate[date]!;
        return Column(
          children: [
            Text(
              '${date.day}-${date.month}-${date.year}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Column(
              children: messages.map((message) {
                return Column(
                  children: [
                    ListTile(
                      title: Text('${extractPrice(message.body!)} [${message.date}]'),
                      subtitle: Text('${message.sender}'),
                    ),
                    Divider(),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

