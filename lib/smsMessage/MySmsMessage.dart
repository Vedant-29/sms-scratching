// import 'package:flutter/material.dart';
// import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
// import 'package:permission_handler/permission_handler.dart';

// class MySmsMessage extends SmsMessage {
//   MySmsMessage([
//     Key? key,
//     String? address,
//     String? body,
//     DateTime? date,
//     DateTime? dateSent,
//     int? id,
//     bool? isRead,
//     String? subject,
//     int? threadId,
//     SmsMessageKind? type,
//   ])  : super(
//           key : key,
//           address: address,
//           body: body,
//           date: date,
//           dateSent: dateSent,
//           id: id,
//           read: isRead,
//           kind: type,
//           threadId: threadId,
//         );

//   double extractPrice() {
//     final matches = RegExp(r'(\d+\.\d+)').firstMatch(this.body!);
//     if (matches != null) {
//       final match = matches.group(0)!;
//       return double.parse(match);
//     }
//     return 0.0;
//   }
// }