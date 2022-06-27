import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_fbexample/model/message.dart';
import 'package:flutter_app_fbexample/model/user.dart';
import '../data.dart';
import '../utils.dart';
//import '../utils.dart';
class FirebaseApiUsers{
  static Stream<List<User2>> getUsers() => FirebaseFirestore.instance
      .collection('users')
  .orderBy(UserField.lastMessageTime, descending: true)
  .snapshots()
  .transform(Utils.transformer(User2.fromJson) as StreamTransformer<QuerySnapshot<Map<String, dynamic>>,List<User2>>);


    static Future uploadMessage(String idUser, String message) async {
      final refMessages = FirebaseFirestore.instance.collection('chats/$idUser/message');
      final newMessage = Message(
        idUser: myId,
        //urlAvatar:myUrlAvatar,
        //username: myUsername,
        //message: message,
        //createdAt:DateTime.now(),
      );
      await refMessages.add(newMessage.toJson());

      final refUsers = FirebaseFirestore.instance.collection('users');
      await refUsers.doc(idUser)
      .update({UserField.lastMessageTime:DateTime.now()});
    }

    static Stream<List<Message>> getMessages(String idUser) =>
        FirebaseFirestore.instance
        .collection('chats/$idUser/messages')
            .orderBy(MessageField.createdAt, descending: true)
            .snapshots()
            .transform(Utils.transformer(Message.fromJson) as StreamTransformer<QuerySnapshot<Map<String, dynamic>>,List<Message>>);

  static Future addRandomUsers(List<User2> users) async {
    final refUsers = FirebaseFirestore.instance.collection('users');

    final allUsers = await refUsers.get();
    if (allUsers.size != 0) {
      return;
    } else {
      for (final user in users) {
        final userDoc = refUsers.doc();
        final newUser = user.copyWith(idUser: userDoc.id);

        await userDoc.set(newUser.toJson());
      }
    }
  }
}