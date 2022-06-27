import 'package:flutter/material.dart';
import 'package:flutter_app_fbexample/api/firebase_api_users.dart';

import '../data.dart';
import 'message_widget.dart';
import 'model/message.dart';

class MessagesWidget extends StatelessWidget {
  final String idUser;

  const MessagesWidget({
    required this.idUser,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Message>>(
    stream: FirebaseApiUsers.getMessages(idUser),
    builder: (context, snapshot) {
      switch (snapshot.connectionState) {
        case ConnectionState.waiting:
          return Center(child: CircularProgressIndicator());
        default:
          if (snapshot.hasError) {
            return buildText('Something Went Wrong Try later');
          } else {
            final messages = snapshot.data;

            return messages!.isEmpty?buildText('Say Hi..'): ListView.builder(
              physics: BouncingScrollPhysics(),
              reverse: true,
              itemCount: messages?.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                return MessageWidget(
                  message: message,
                  isMe: message.idUser == myId,
                );
              },
            );
          }
      }
    },
  );

  Widget buildText(String text) => Center(
    child: Text(
      text,
      style: TextStyle(fontSize: 24),
    ),
  );
}