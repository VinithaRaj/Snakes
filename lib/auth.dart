//import 'dart:js';
import 'dart:ui';
import 'dart:async';
import 'package:path/path.dart' as Path;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_fbexample/model/user.dart';

class AuthMethods{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User2? _userfromfb(User user){
    return user!=null?User2(idUser: user.uid):null;
  }
  Future signInWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? fbuser = result.user  ;
      return _userfromfb(fbuser!);
    }catch(e){
      print(e);
    }
  }

  Future signUpWithEmailAndPassword(String email, String password) async{
    try{

      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? fbuser = result.user  ;
      return _userfromfb(fbuser!);
    }catch(e){
      print(e);
      print("whattt");
      switch (e) {
        case 'firebase_auth/email-already-in-use':
          print(e);
          break;
        case 'firebase_auth/invalid-email':
          print(e);
          break;
        default:
          print(e);
      }

    }
  }
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}