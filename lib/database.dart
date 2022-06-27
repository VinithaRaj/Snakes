import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods{
  getUserByUsername(String username)async{
    return await FirebaseFirestore.instance.collection("allusers")
        .where("name", isEqualTo: username)
        .get();
  }
  getUserByEmail (String email)async{
    return await FirebaseFirestore.instance.collection("allusers")
        .where("email", isEqualTo: email)
        .get();
  }
  uploadUserInfo(usermap){
    FirebaseFirestore.instance.collection("allusers")
        .add(usermap).catchError((e){
          print(e.toString());
    });
  }
  createChatRoom(String chatroomid, chatroommap){
    FirebaseFirestore.instance.collection("ChatRoom").doc("chatroomid").set(chatroommap).catchError((e){
      print(e.toString());
    });

  }
  addConversationmessages(String chatroomid, messagemap){
    FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatroomid)
        .collection("chats")
        .add(messagemap).catchError((e){
      print(e.toString());
    });
  }

  getConversationmessages(String chatroomid) async {
    return await FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatroomid)
        .collection("chats")
        .orderBy("time",descending: false)
        .snapshots();
  }
}