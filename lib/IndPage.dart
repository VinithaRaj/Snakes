import 'package:cloud_firestore/cloud_firestore.dart';

class IndPage{
  getIndData(String url){
    return FirebaseFirestore.instance
        .collection('files')
        .where("url",isEqualTo: url)
        .get();
  }
}