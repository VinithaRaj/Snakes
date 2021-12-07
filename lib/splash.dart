import 'dart:io';

import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:flutter/painting.dart';

import 'main.dart';

class Splash extends StatefulWidget {
  const Splash({Key?key}) : super(key:key);
  @override
  _SplashState createState() => _SplashState();
}

  class _SplashState extends State<Splash>{
  @override
  void initState(){
    super.initState();
    _navigatetohome();
  }

  _navigatetohome() async{
    await Future.delayed(Duration(milliseconds: 2500),() {});
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const MyBasePage(title: 'Flutter Demo Home Page')));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
        child: /*Text("KYJ Exotics", style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black
        ),)*/
        Image.asset(
          //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
            'ims/logo.jpg',
            fit: BoxFit.cover,
          alignment: Alignment.center,
        )
      ),)
    );
  }


}


