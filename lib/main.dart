// @dart = 2.15
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as Path;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:async/async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flat_icons_flutter/flat_icons_flutter.dart';
import 'package:bordered_text/bordered_text.dart';
import 'package:flutter_app_fbexample/api/firebase_api_users.dart';
import 'package:flutter_app_fbexample/chat_body_widget.dart';
import 'package:flutter_app_fbexample/database.dart';
import 'package:flutter_app_fbexample/helperfunction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:recase/recase.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_app_fbexample/api/firebase_api.dart';
import 'package:flutter_app_fbexample/model/firebase_file.dart';
import 'package:flutter_app_fbexample/presentations/messenger_icons.dart';
import 'package:flutter_app_fbexample/splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app_fbexample/presentations/my_flutter_app_icons.dart';
import 'package:splashscreen/splashscreen.dart';
import 'dart:io';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

import 'IndPage.dart';
import 'auth.dart';
import 'constants.dart';
import 'messages_widget.dart';
import 'model/carousel_file.dart';
import 'model/collections_file.dart';
import 'model/user.dart';
import 'new_message_widget.dart';
Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
  configLoading();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.amber
    ));
    return MaterialApp(
      title: 'KYJ Exotics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        //primarySwatch: Colors.amber,

        primaryIconTheme: IconThemeData(
          color: Colors.white,

        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Colors.amber,
          ),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.white
        )
      ),
      home: const MyBasePage(title: 'Flutter Demo Home Page'),
      builder:EasyLoading.init()
    );
  }
}
void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
  //..customAnimation = CustomAnimation();
}



class MyBasePage extends StatefulWidget {
  const MyBasePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyBasePage> createState() => _MyBasePageState();
}

class _MyBasePageState extends State<MyBasePage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final key2 = GlobalKey<ScaffoldState>();
  var storage = FirebaseStorage.instance;
  final ref = FirebaseStorage.instance.ref().child('testimage');

// no need of the file extension, the name will do fine.
  Future<String> _imgurl() async {
    var url = await ref.getDownloadURL();
    return url;
  }

  late List<AssetImage> listOfImages;
  bool clicked = false;
  List<String?> listOfStr = [];
  String? images;
  bool isLoading = false;
  int _currentIndex = 0;
  int _selectedIndex = 0;
  bool userisloggedin = false;
  String username="hi";
  late Future<List<FirebaseFile>> futureFiles;
  final FirebaseFirestore fb = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('onMessageOpenedApp data: ${message.data}');
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print('getInitialMessage data: ${message?.data}');
    });

    // onMessage: When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage data: ${message.data}");
    });
    firebaseMessaging.getToken().then((token) {
      saveTokens(token);
    });
    /*FirebaseMessaging.instance.getInitialMessage().then(( message) {
        print('getInitialMessage data: ${message?.data}');

      });

      // onMessage: When the app is open and it receives a push notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("onMessage data: ${message.data}");
      });

    });*/
    getLoggedInstate();

  }

  getLoggedInstate() async {
    await HelperFunctions.getUserLoggedSharedPreference().then((value) {
      setState(() {
        userisloggedin = value!;

      });
      if (userisloggedin){
        _children = [
          MyHomePage(title: "Home Page"),
          CollectionsPage(pagenum:0),
          Aboutuspage(),
          Contactuspage(),
          ChatRoom()
        ];
      }
      getUserInfo();
    });
  }
  Future<String> getUserInfo() async{
    username = (await HelperFunctions.getUsernameSharedPreference())!;
    print("HELOOOOOO"+Constants.myName);

    return username;
  }
  Future<void> saveTokens(var token) async {
    try {
      var qtoken = await _firestore.collection('tokens').where(
          "token", isEqualTo: token).get();
      if (qtoken.docs.length == 0) {
        await _firestore.collection('tokens').add({
          'token': token,
        });
      }
    } catch (e) {
      print(e);
    }
  }
  var unread = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /*final List _children = [
    MyHomePage(title: "Home Page"),
    CollectionsPage(),
    Aboutuspage(),
    Contactuspage(),
    userisloggedin ? ChatRoom() : Authenticate()
  ];*/
  var _children = [
    MyHomePage(title: "Home Page"),
    CollectionsPage(pagenum:0),
    Aboutuspage(),
    Contactuspage(),
    Authenticate()
  ];


  @override
  Widget build(BuildContext context) {

    if(userisloggedin){
      print("I am "+username);
    FirebaseFirestore.instance.collection('allusers').where("name",isEqualTo: username).get().then(
        (qsnap){

            //setState(() {
              unread = qsnap.docs[0].get("unreadmessages");
              print(unread);
            //});
          }
          );
        }
    
      return Scaffold(
        key: key2,
        backgroundColor: Colors.black,
        body:  _children[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items:  <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
              backgroundColor: Colors.black,
            ),
            BottomNavigationBarItem(
              icon: Icon(MyFlutterApp.snake),
              label: 'Collections',
              backgroundColor: Colors.black,

            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.accessibility_new_rounded),
              label: 'About Us',
              backgroundColor: Colors.black,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone),
              label: 'Contact Us',
              backgroundColor: Colors.black,
            ),
            userisloggedin?BottomNavigationBarItem(
              icon: Stack(children: <Widget>[Icon(Icons.mail),Positioned(
                right: 0,
                child: new Container(
                  padding: EdgeInsets.all(1),
                  decoration: new BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: new Text(
                    unread.toString(),
                    style: new TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )],),
              label: 'Messages',
              backgroundColor: Colors.black,
            ):BottomNavigationBarItem(
              icon: Icon(Icons.mail),
              label: 'Messages',
              backgroundColor: Colors.black,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber,
          onTap: _onItemTapped,
        ),

      );
}

}
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream slides;
  var storage = FirebaseStorage.instance;
  late List<AssetImage> listOfImages;
  bool clicked = false;
  late Future _getTaskAsync;
  List<String?> listOfStr = [];
  String? images;
  bool isLoading = false;
  int currentPage=0;
  late AsyncMemoizer _memoizer;
  int _selectedIndex = 0;
  final PageController ctrl = PageController();
  late Future<List<FirebaseFile>> futureFiles;
  late Future<List<CarouselFile>> futureCars;
  late Future<List<CollectionsFile>> futureCol;
  late Future<String> bannerlink;
  final FirebaseFirestore fb = FirebaseFirestore.instance;
  //String bannerurl = 'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip';
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  double pageOffset =0;
  @override
  void initState(){

    super.initState();
    futureFiles = FirebaseApi.listAll('newsitems/');
    futureCars = getCarouselList();
    futureCol = getCollectionList();
    bannerlink = FirebaseStorage.instance.ref().child("Choose Banner/banner.jpg").getDownloadURL();
    getImages();
    _connectivity.initialise();
    _connectivity.myStream.listen((source) {
      setState(() => _source = source);
    });


  }


  Future<List<CollectionsFile>> getCollectionList() async {
    List<int> idList = [];
    //var qa = await FirebaseFirestore.instance.collection("newfiles").limit(3).get();
    var qa = await FirebaseFirestore.instance.collection("allanimals").limit(5).orderBy("time",descending:true).get();
    List<CollectionsFile> collectionsList = [];
    print("okayyyyy");
    qa.docs.forEach((element) {

      print(element.get("visibleName"));
      //print((element as Map)["url"]);
      print("nope");
      var prod = CollectionsFile(
        url: element.get("url"),
        visibleName: element.get("visibleName"), type: element.get("type"),section:element.get("section")
      );
      collectionsList.add(prod);
    });
    print(collectionsList);
    print("SUCCESSFUL");
    return collectionsList;
  }
  Future<List<CarouselFile>> getCarouselList() async {
    List<int> idList = [];
    var qa = await FirebaseFirestore.instance.collection("newsitems").get();
    List<CarouselFile> carouselList = [];
    print("okayyyyy");
    qa.docs.forEach((element) {

      print(element.get("url"));
      //print((element as Map)["url"]);
      print("nope");
      var prod = CarouselFile(
        url: element.get("url"),
        newsTitle: element.get("newsTitle"), newsBig: element.get("newsBig"), newsSmall: element.get("newsSmall"),
      );
      carouselList.add(prod);
    });
    print(carouselList);
    print("SUCCESSFUL");
    return carouselList;
}
  Future<String> _getbanner() async{
    final ref = FirebaseStorage.instance.ref().child("Choose Banner/banner.jpg");
// no need of the file extension, the name will do fine.
    var url = await ref.getDownloadURL();
    return url;
  }
  Future<QuerySnapshot>  getCarouselItems() async{
    //return this._memoizer.runOnce(() async{
      //await Future.delayed(Duration(seconds:2));
    //Future<QuerySnapshot> qa = fb.collection("newsitems").get();
    Future<QuerySnapshot> qa = fb.collection("allanimals").limit(5).get();
    //return fb2.collection("newfiles").get();
    //return qa;
    return qa;
  //});
  }


  void getImages(){
    listOfImages = [];
    listOfImages.add(AssetImage('snake.png'));
  }

  Map _source = {ConnectivityResult.none: false};
  final MyConnectivity _connectivity = MyConnectivity.instance;


  @override
  Widget build(BuildContext context)
  //=>
  {

    if (_source.keys.toList()[0]==ConnectivityResult.none){
      print("Do somtthinggg");
      return Scaffold(
          backgroundColor: Colors.black,
          body:NestedScrollView(body:Center(child:Text("Oops! Looks like you're offline",style:
      GoogleFonts.ubuntu(
      textStyle:
      TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 18)
      )
      )),
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {

      return <Widget>[
      SliverAppBar(
      backgroundColor: Colors.black,
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
      centerTitle: true,
      title: BorderedText(strokeWidth: 1.0,
      strokeColor: Colors.black38,
      child:Text("K Y J  E X O T I C S",
      //style: TextStyle(fontFamily: 'RoadRage',color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold,height: .7)
      style: GoogleFonts.ubuntu(
      textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold, ),
      )
      ) ),
      background:  Image.asset(
        //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
        'ims/sneklogo.jpg',

        fit: BoxFit.cover
        )


      ),
      ),
      ];
      }
      )
      );

    }
    else{
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
      body:
                  ListView(children: [
                    Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                   Container(child:
                   FutureBuilder<List<CarouselFile>>(
                        future: futureCars,
                        builder: (context, snapshot){
                          switch (snapshot.connectionState){
                            case ConnectionState.waiting:
                              return Center(child: CircularProgressIndicator(color: Colors.amber,));
                            default:
                              if (snapshot.hasError){
                                print("Errorrrr");
                                return Center(child: Text("eroorrr"));
                              } else {
                                print("Goodddd");
                                // final files = snapshot.data?.asMa;

                                if (snapshot.data!=null){
                                  final files = snapshot.data!;
                                  if (files.length>0){

                                  return CarouselSlider.builder(
                                      itemCount: files.length,
                                      itemBuilder: ( context,  index) {
                                        final file = files[index];
                                        if (file.url !=null){
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                            ),
                                            child: Stack(
                                              //mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Image.network(
                                                  //(a as Map)["url"]??"https://firebasestorage.googleapis.com/v0/b/fbexample-f0c85.appspot.com/o/newsitems%2Fimage_picker3695461532645765370.jpg?alt=media&token=fcd85532-be0d-4689-8000-b56054853af3",
                                                  //height: MediaQuery.of(context).size.height*0.25,
                                                  file.url,
                                                  width: MediaQuery.of(context).size.width,
                                                  height:200,
                                                  //width:200,
                                                  fit: BoxFit.fitWidth,
                                                ),
                                                Positioned(child: Container(
                                                    width: MediaQuery.of(context).size.width,
                                                    padding: EdgeInsets.all(15),
                                                    color:Colors.black45,
                                                    child:Text(ReCase(file.newsTitle).titleCase,style:
                                                    GoogleFonts.ubuntu(
                                                        textStyle:
                                                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 18)
                                                    )
                                                    )

                                                ),
                                                  //left:40,

                                                ),
                                                Positioned(child: ElevatedButton(

                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => IndividualPageNews(fileurl: file.url,collname: "newsitems",)),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    primary: Colors.black,
                                                  ),
                                                  child: const Text('View'),

                                                ),
                                                  bottom: 15,
                                                  right: 15,),



                                              ],
                                            ),
                                          );
                                        }
                                        else{
                                          return CircularProgressIndicator(color: Colors.amber,);
                                        }
                                        //var a =snapshot.data?.docs[index].data() ?? {"newsTitle":"hi","url":"none","newsBig":"none","newsSmall":"none"};

                                      },
                                      options: CarouselOptions(
                                        height: 200.0,
                                        autoPlay: true,
                                        autoPlayInterval: Duration(seconds: 3),
                                        autoPlayAnimationDuration: Duration(milliseconds: 800),
                                        autoPlayCurve: Curves.fastOutSlowIn,
                                        pauseAutoPlayOnTouch: true,
                                        aspectRatio: 2.0,
                                        onPageChanged: (index, reason) {
                                          setState(() {
                                            currentPage = index;
                                          });
                                        },
                                      )
                                  );
                                  }
                                  else{
                                    return Container();
                                  }

                                }
                                else {
                                  return CircularProgressIndicator(color:Colors.amber);
                                }

                              }}}
                    )
                   ),
                    const SizedBox(height: 12),


                   Container(
                       height: 100,
                       padding: EdgeInsets.all(10),
                       child:ListView(
                      scrollDirection: Axis.horizontal,
                      children:<Widget> [

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
                        ),
                        ElevatedButton(


                            style: ElevatedButton.styleFrom(

                                side: BorderSide(width: 2.0, color: Colors.amber,),
                                primary: Colors.black
                            ),

                            onPressed: (){}, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Icon(MyFlutterApp.snake, color: Colors.white),
                              TextButton(onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CollectionsPage(pagenum:0)),
                                );
                              }, child: Text("Snakes"))
                            ]
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
                        ),
                        ElevatedButton(


                            style: ElevatedButton.styleFrom(

                                side: BorderSide(width: 2.0, color: Colors.amber,),
                                primary: Colors.black
                            ),

                            onPressed: (){}, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                    maxWidth: 20,
                                    maxHeight: 20,
                                  ),
                                  child:  Image.asset("ims/curved-lizard.png")),
                              TextButton(onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CollectionsPage(pagenum: 1)),
                                );
                              }, child: Text("Lizards"))
                            ]
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
                        ),
                        ElevatedButton(


                            style: ElevatedButton.styleFrom(

                                side: BorderSide(width: 2.0, color: Colors.amber,),
                                primary: Colors.black
                            ),

                            onPressed: (){}, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                    maxWidth: 20,
                                    maxHeight: 20,
                                  ),
                                  child:  Image.asset("ims/turtle.png")),
                              TextButton(onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CollectionsPage(pagenum: 2)),
                                );
                              }, child: Text("Tortoises"))
                            ]
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
                        ),
                        ElevatedButton(


                            style: ElevatedButton.styleFrom(

                                side: BorderSide(width: 2.0, color: Colors.amber,),
                                primary: Colors.black
                            ),

                            onPressed: (){}, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                    maxWidth: 20,
                                    maxHeight: 20,
                                  ),
                                  child:  Image.asset("ims/animal.png")),
                              TextButton(onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CollectionsPage(pagenum: 3)),
                                );
                              }, child: Text("Feeders"))
                            ]
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
                        ),
                        ElevatedButton(


                            style: ElevatedButton.styleFrom(

                                side: BorderSide(width: 2.0, color: Colors.amber,),
                                primary: Colors.black
                            ),

                            onPressed: (){}, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Icon(Icons.pest_control_rodent_outlined, color: Colors.white),
                              TextButton(onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CollectionsPage(pagenum: 4)),
                                );
                              }, child: Text("Others"))
                            ]
                        )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
                        ),
                        ElevatedButton(


                            style: ElevatedButton.styleFrom(

                                side: BorderSide(width: 2.0, color: Colors.amber,),
                                primary: Colors.black
                            ),

                            onPressed: (){}, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Icon(Icons.auto_awesome, color: Colors.white),
                              TextButton(onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CollectionsPage(pagenum: 5)),
                                );
                              }, child: Text("Accessories"))
                            ]
                        )),



                      ],
                    )),

                    Container(
                        padding:EdgeInsets.all(30.0),
                        child:
                        Row(children:<Widget>[
                          Text(
                              "New ",
                              style:
                              //GoogleFonts.teko(
                            //    textStyle:
                                TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                          //    )
                          ),
                          Icon(Icons.local_fire_department_outlined, size: 20,color: Colors.amber),
                          TextButton(onPressed: () {Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CollectionsPage(pagenum:0)),
                          );  }, child: Text("More"))


                        ],)

                    ),
                          Container(child:FutureBuilder<List<CollectionsFile>>(
                            future: futureCol,
                            builder: (context,  snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Center(
                                      child: CircularProgressIndicator(color: Colors.amber,));
                                default:
                                  if (snapshot.hasError) {
                                    print("Errorrrr");
                                    return Center(child: Text("eroorrr"));
                                  } else {
                                    /*if ( snapshot.connectionState==ConnectionState.waiting){
                                return Center(child: CircularProgressIndicator());
                              }
                              else if (snapshot.connectionState == ConnectionState.done) {*/
                                    final files = snapshot.data!;
                                    print("hereee");
                                    return ListView.builder(
                                        physics: const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: files.length,
                                        itemBuilder: (context, index) {
                                          final file = files[index];
                                          return
                                            Card(
                                                color: Colors.black,
                                                child:
                                            Column(children:[
                                              Container(
                                                child:Image.network(
                                                    file.url,
                                                  width: MediaQuery.of(context).size.width,
                                                  height:200,
                                                  //width:200,
                                                  fit: BoxFit.fitWidth,)
                                              ),
                                              ListTile(
                                                  contentPadding: EdgeInsets
                                                      .symmetric(vertical: 20,
                                                      horizontal: 20),
                                                  /*leading: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        minWidth: 80,
                                                        minHeight: 80,
                                                        maxWidth: 100,
                                                        maxHeight: 100,
                                                      ),
                                                      child: Image.network(
                                                          file.url)),*/

                                                  title: Text(
                                                      ReCase(file.visibleName)
                                                          .titleCase,
                                                      style: GoogleFonts.teko(
                                                        textStyle: TextStyle(
                                                            fontSize: 20,
                                                            color: Colors.white,
                                                            letterSpacing: 1.0,
                                                            fontWeight: FontWeight
                                                                .bold),
                                                      )),
                                                  subtitle: Text(file.type,
                                                      style: GoogleFonts.teko(
                                                        textStyle: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.white,
                                                            letterSpacing: 1.0),
                                                      )),
                                                  trailing: TextButton(
                                                    child: Text('View'),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                IndividualPage(
                                                                    fileurl: file
                                                                        .url,
                                                                    collname: file.section)),
                                                      );
                                                    },
                                                  )

                                              )
                                            ])

                                          )
                                          ;
                                        });
                                  }
                              }


                              /*else if (snapshot.connectionState == ConnectionState.none) {
                                return Text("No data");
                              }
                              return Text("");*/
                            },

                          ))


                      ,


                    Container(
                      padding: EdgeInsets.all(6),
                      child:
                      Card(
                        color: Colors.black,
                        shadowColor: Colors.amber,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: ClipOval(
                                  child: Icon(Icons.accessibility_new_rounded, color: Colors.amber)
                              ),
                              title: Text('About Us',style: GoogleFonts.teko(
                                textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                              )),
                              trailing: TextButton(
                                child: const Text('Learn More'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => Aboutuspage()),
                                  );
                                },
                              ),
                              ),



                          ],
                        ),
                      ),



                    ),

                  ],
                  )])
          //;
              //}
          //}
       // }
      //)
        , //futurebuilder
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {

          return <Widget>[
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: BorderedText(strokeWidth: 1.0,
          strokeColor: Colors.black38,
          child:Text("K Y J  E X O T I C S",
              //style: TextStyle(fontFamily: 'RoadRage',color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold,height: .7)
              style: GoogleFonts.ubuntu(
                textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold, ),
              )
          ) ),
                background: /*Image.network(
                    //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
                    //'ims/sneklogo.png',
                  _getbanner().toString(),
                    fit: BoxFit.cover
                )*/
                FutureBuilder<String>(
                  future: bannerlink,
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot) {

                    switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    return Center(child: CircularProgressIndicator(color: Colors.amber,));
                      default:
                        if (snapshot.hasError)
                          return Text('Error: ${snapshot.error}');
                        else
                          if (snapshot.data != null){
                            final link = snapshot.data;
                            return Image.network(
                                link!,
                                fit: BoxFit.cover
                            );
                          }
                          else{
                            return Image.asset(
                              //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
                              'ims/sneklogo.jpg',

                                fit: BoxFit.cover
                            );
                          }

                    }
                  },
                )

          ),
          ),
        ];
      },
      ),
    drawer: Drawer(
      backgroundColor: Colors.white,

      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /*DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Text('Drawer Header'),
          ),*/
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            accountName: Text(""),
            accountEmail: Text("kyjexotics@gmail.com"),
            currentAccountPicture: ClipOval(
              child: Image.asset("ims/logo.jpg"),
            ),
          ),
          ExpansionTile(
            title: TextButton( onPressed: () {  Navigator.pop(
              context,
            );}, child: Text("Home"),),

            children: <Widget>[
              Text("About Us"), Text("Collections"),Text("Contact Us")
            ],
          ),
          ExpansionTile(
            title: TextButton( onPressed: () {Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CollectionsPage(pagenum:0)),
            );  }, child: Text("Collections"),),

            children: <Widget>[
              Text("Snakes"), Text("Other Animals"),Text("Accessories")
            ],

          ),
          ExpansionTile(
            title: TextButton( onPressed: () { Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Aboutuspage()),
            ); }, child: Text('About Us'),),

            children: <Widget>[
              Text("Who Are We"), Text("Vision"),Text("Mission"),Text("Terms & Conditions"),Text("How To Purchase")
            ],

          ),
          ExpansionTile(
            title: TextButton( onPressed: () { Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Contactuspage()),
            ); }, child: Text('Contact Us'),),
            children: <Widget>[
              Text("WhatsApp"), Text("Messenger")
            ],


          ),

        ],
      ),
    ),

    // This trailing comma makes auto-formatting nicer for build methods.
    );}}

  //Future<String> sendData
  Widget buildFile(BuildContext context, FirebaseFile file, String user) => Card(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
       ListTile(
        leading: ClipOval(
          child: Image.network(
            file.url,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          ),
        ),
        title: Text('The Enchanted Nightingale'),
        subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            child: const Text('View Details'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => IndividualPage(fileurl: file.url,collname: "newfiles")),
              );
            },
          ),
          const SizedBox(width: 8),
          TextButton(
            child: const Text('LISTEN'),
            onPressed: () {/* ... */},
          ),
          const SizedBox(width: 8),
        ],
      ),
    ],
    ),
  );

  Future<Widget> _getBanner(BuildContext context, FirebaseFile file) async {
    Image m;
    m = Image.network(
      file.url,
      fit: BoxFit.scaleDown,
    );


    return m;
  }
  Future<QuerySnapshot> getImages3(String fileurlfirebase) {
    //return fb.collection("newfiles").where("url", isEqualTo:widget.fileurl).get();
    return fb.collection("newsitems").where("url", isEqualTo:fileurlfirebase).get();
  }
  //final FirebaseFirestore fb3 = FirebaseFirestore.instance;
  Widget buildCard(BuildContext context, FirebaseFile file) =>  Container(
    decoration: BoxDecoration(
      color: Colors.black,
    ),
    child: Stack(
    //mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Image.network(
        file.url,
        //height: MediaQuery.of(context).size.height*0.25,
        width: MediaQuery.of(context).size.width,
        height:200,
        //width:200,
        fit: BoxFit.fitWidth,
      ),
      Positioned(child: Container(

        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(10),
        color:Colors.amber,

        child:
        FutureBuilder(
          future: getImages3(file.url),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    var a =snapshot.data?.docs[index].data() ?? {"newsTitle":"hi","url":"none","newsBig":"none","newsSmall":"none"};
                    return Text((a as Map)["newsTitle"],style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black))
                      ;

                  });
            } else if (snapshot.connectionState == ConnectionState.none) {
              return Text("No data");
            }
            return Text("");
          },

        )
        //Text(file.name,style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black))
        /*GoogleFonts.teko(
          textStyle: TextStyle(color: Colors.black, letterSpacing: 1.0, fontWeight: FontWeight.bold,height: .4),),*/


      ),
      left:40,

          ),
      Positioned(child: ElevatedButton(

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IndividualPage(fileurl: file.url,collname: "newsitems",)),
          );
        },
          style: ElevatedButton.styleFrom(
              primary: Colors.black,
              ),
        child: const Text('View'),

      ),

      bottom: 0,
      right:15)

    ],
    ),
  );

}

class MyConnectivity {
  MyConnectivity._();

  static final _instance = MyConnectivity._();
  static MyConnectivity get instance => _instance;
  final _connectivity = Connectivity();
  final _controller = StreamController.broadcast();
  Stream get myStream => _controller.stream;

  void initialise() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    _checkStatus(result);
    _connectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }

  void _checkStatus(ConnectivityResult result) async {
    bool isOnline = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      isOnline = false;
    }
    _controller.sink.add({result: isOnline});
  }

  void disposeStream() => _controller.close();
}
class Aboutuspage extends StatefulWidget{
  const Aboutuspage({Key ? key}) : super(key:key);

  @override
  _Aboutuspage createState() => new _Aboutuspage();
}

class _Aboutuspage extends State<Aboutuspage>{
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return /*Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('About Us'),
        backgroundColor: Colors.amber,
      ),*/
      Scaffold(
        backgroundColor: Colors.black,
        body:
      NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 100.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text("A B O U T  U S",
                      style: GoogleFonts.teko(
                        textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold,height: .4),

                      )),
                  background: Image.asset(
                    //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
                      'ims/aboutus.png',
                      fit: BoxFit.cover
                  )
              ),
            ),
          ];
        },
      body: Scaffold(backgroundColor: Colors.black, body: ListView(

          padding: EdgeInsets.all(6),
          children:[
            Card(
              color: Colors.black,
              shadowColor: Colors.amber,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: ClipOval(
                        child: Icon(Icons.accessibility_new_rounded, color: Colors.amber)
                    ),
                    title: Text('Who Are We',style: GoogleFonts.teko(
                      textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                    )),
                    subtitle: Text('3 friends who came together through a mutual passion for the exotic animal world. ',style: TextStyle(color: Colors.white),),
                  ),

                ],
              ),
            ),
            Card(
              color: Colors.black,
              shadowColor: Colors.amber,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: ClipOval(
                        child: Icon(Icons.local_fire_department_outlined, color: Colors.amber)
                    ),
                    title: Text('Mission',style: GoogleFonts.teko(
                      textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                    )),
                    subtitle: Text('To spread the passion that is the world of exotic animals and educate the public on the beauty of these creatures.',style: TextStyle(color: Colors.white),),
                  ),

                ],
              ),
            ),
            Card(
              color: Colors.black,
              shadowColor: Colors.amber,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: ClipOval(
                        child: Icon(Icons.remove_red_eye_rounded, color: Colors.amber)
                    ),
                    title: Text('Vision',style: GoogleFonts.teko(
                      textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                    )),
                    subtitle: Text('To produce visually stunning and healthy animals. ' ,style: TextStyle(color: Colors.white),
                    ),
                  ),

                ],
              ),
            ),
            Card(
              color: Colors.black,
              shadowColor: Colors.amber,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
              ExpansionTile(
              leading: Icon(Icons.credit_card, color: Colors.amber),
              iconColor: Colors.white,
              collapsedIconColor: Colors.amber,
              title: Text("Terms & Conditions",style: GoogleFonts.teko(
                textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
              )),

              children: <Widget>[RichText(
                text: TextSpan(
                  text: 'Animals sold by KYJ is guaranteed to be the following:\n',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: const <TextSpan>[

                    TextSpan(text: '- Stable and feeding well!\n'),
                    TextSpan(text: '- Sexed properly\n'),
                    TextSpan(text: '- Excellent health condition prior to leaving our premises\n'),
                    TextSpan(text: '- A 2-week monitoring period is accompanied with the purchase of the animal to guarantee the health and quality of the animal. Any defect in the animal will be liable for a 1 to 1 exchange.\n'),
                    TextSpan(text: '- A full Care Sheet will be provided on the relevant animal and customers can reach out to us for any further information.\n'),
                    TextSpan(text: '- Products sold are non-refundable.\n'),



                  ],
                ),
              ),
              ],
            ),


                ],
              ),
            ),
            Card(
              color: Colors.black,
              shadowColor: Colors.amber,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExpansionTile(
                    leading: Icon(Icons.shopping_cart, color: Colors.amber),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.amber,
                    title: Text("How to Purchase?",style: GoogleFonts.teko(
                      textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                    )),

                    children: <Widget>[RichText(
                      text: TextSpan(
                        text: 'Go to collections page, or, click View on the Home page\n',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: const <TextSpan>[

                          TextSpan(text: '- An individual page will open up\n'),
                          TextSpan(text: '- Press the + button on the bottom right\n'),
                          TextSpan(text: '- You will be shown 2 options - Enquire & Place Order\n'),
                          TextSpan(text: '-  When Place Order button is pressed, the Item with the Item code will be sent via WhatsApp for an order to be placed, you may add further details\n'),
                          TextSpan(text: '- When Enquire button is pressed, the Item with the Item code will be sent via WhatsApp for enquiry on that product, you may add further details\n'),




                        ],
                      ),
                    ),
                    ],
                  ),


                ],
              ),
            ),
          ]

      ))


    ),
        drawer: Drawer(
          backgroundColor: Colors.white,

          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              /*DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Text('Drawer Header'),
          ),*/
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                accountName: Text(""),
                accountEmail: Text("kyjexotics@gmail.com"),
                currentAccountPicture: ClipOval(
                  child: Image.asset("ims/logo.jpg"),
                ),
              ),
              ExpansionTile(
                title: TextButton( onPressed: () {  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage(title: "Home")),
                ); }, child: Text("Home"),),

                children: <Widget>[
                  Text("About Us"), Text("Collections"),Text("Contact Us")
                ],
              ),
              ExpansionTile(
                title: TextButton( onPressed: () {Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CollectionsPage(pagenum:0)),
                );  }, child: Text("Collections"),),

                children: <Widget>[
                  Text("Snakes"), Text("Other Animals"),Text("Accessories")
                ],

              ),
              ExpansionTile(
                title: TextButton( onPressed: () { Navigator.pop(
                  context,
                );}, child: Text('About Us'),),

                children: <Widget>[
                  Text("Who Are We"), Text("Vision"),Text("Mission"),Text("Terms & Conditions"),Text("How To Purchase")
                ],

              ),
              ExpansionTile(
                title: TextButton( onPressed: () { Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Contactuspage()),
                ); }, child: Text('Contact Us'),),
                children: <Widget>[
                  Text("WhatsApp"), Text("Messenger")
                ],


              ),

            ],
          ),
        ),
      );
  }

}
class Contactuspage extends StatefulWidget{
  const Contactuspage({Key ? key}) : super(key:key);

  @override
  _Contactuspage createState() => new _Contactuspage();
}

class _Contactuspage extends State<Contactuspage>{
  int _selectedIndex = 3;
  static const _url = 'whatsapp://send?phone=60133635145';
  static const _fburl = 'http://m.me/KYJEXO';
  String numval = "0102214405";
  String nameval = "Yuvanesh";
  String _urlval = 'whatsapp://send?phone=60102214405';
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  final FirebaseFirestore fbcontact = FirebaseFirestore.instance;
  Future<QuerySnapshot> getcontact() {
    Future<QuerySnapshot> qa = fbcontact.collection("contactdetails").get();
    return qa;
  }
  void _launchURL() async => await canLaunch(_url)
      ? await launch(_url) : throw 'Not found $_url';
  void _launchfbURL() async => await canLaunch(_fburl)
      ? await launch(_fburl) : throw 'Not found $_fburl';
  void _launchURL2() async => await canLaunch(_urlval)
      ? await launch(_urlval) : throw 'Not found $_urlval';

  @override
  Widget build(BuildContext context) {
    return
    Scaffold(
      backgroundColor: Colors.black,
      body:NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 100.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text("C O N T A C T  U S",
                      style: GoogleFonts.teko(
                        textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold,height: .4),

                      )),
                  background: Image.asset(
                    //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
                      'ims/contactus.png',
                      fit: BoxFit.cover
                  )
              ),
            ),
          ];
        },
        body: ListView(
            padding: EdgeInsets.all(6),
            children:[
              FutureBuilder(
                //future: getImages2(_searchText),
                future: getcontact(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var contcards = snapshot.data?.docs.map((doc) => Contactcard(
                      name: doc['name'],
                      number: doc['number'],
                    )).toList();

                    return ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        //itemCount: snapshot.data?.docs.length,
                        itemCount: contcards?.length,
                        itemBuilder: (BuildContext context, int index) {
                          _urlval ='whatsapp://send?phone=6'+contcards![index].number;
                          print("width");
                          print(_urlval);
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.black,
                            child:
                            Column(
                              children: [
                                ListTile(
                                  leading: Icon(Messenger.whatsapp, color: Colors.amber,),
                                  //title: Text("Name: "+ReCase((a as Map)["visibleName"]).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold)),
                                  title: Text('Whatsapp Us',style: GoogleFonts.teko(
                                    textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                                  )),
                                  subtitle: Text(
                                    //"Type: "+(a as Map)["type"],
                                    ReCase(contcards![index].name).titleCase+": "+contcards![index].number,
                                    style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                  ),
                                  //trailing: Icon(Icons.favorite_outline),
                                ),
                                TextButton(onPressed: _launchURL2,
                                    child: Text("Chat now"))

                              ],
                            ),
                          );
                        });
                  } else if (snapshot.connectionState == ConnectionState.none) {
                    return Text("No data");
                  }
                  /*return SizedBox(
                        child: LinearProgressIndicator(),
                        height: 5.0,
                        width: 5.0,
                      );*/
                  return Text("Loading...");
                },

              ),
              /*Card(
                color: Colors.black,
                shadowColor: Colors.amber,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      /*leading: ClipOval(snak
                          child: Image.asset("ims/walogo.jpg")
                      ),*/
                      leading: Icon(Messenger.whatsapp, color: Colors.amber,),
                      title: Text('Whatsapp Us',style: GoogleFonts.teko(
                        textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                      )),
                      subtitle: Text('Number: +6013 3635 145', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(onPressed: _launchURL,
                        child: Text("Chat with us"))
                  ],
                ),
              ),*/
              Card(
                color: Colors.black,
                shadowColor: Colors.amber,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: /*ClipOval(
                          child: Image.asset("ims/fblogo.jpg")
                      ),*/
                      Icon(Messenger.facebook_messenger, color: Colors.amber),
                      title: Text('Find us on Messenger',style: GoogleFonts.teko(
                        textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                      )),
                      subtitle: Text('Facebook Page: KYJ Exotics',style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(onPressed: _launchfbURL,
                        child: Text("Chat with us"))
                  ],
                ),
              ),

            ]

        )
        ,


      ),
      drawer: Drawer(
        backgroundColor: Colors.white,

        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            /*DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Text('Drawer Header'),
          ),*/
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              accountName: Text(""),
              accountEmail: Text("kyjexotics@gmail.com"),
              currentAccountPicture: ClipOval(
                child: Image.asset("ims/logo.jpg"),
              ),
            ),
            ExpansionTile(
              title: TextButton( onPressed: () {  Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage(title: "Home")),
              ); }, child: Text("Home"),),

              children: <Widget>[
                Text("About Us"), Text("Collections"),Text("Contact Us")
              ],
            ),
            ExpansionTile(
              title: TextButton( onPressed: () {Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CollectionsPage(pagenum:0)),
              );  }, child: Text("Collections"),),

              children: <Widget>[
                Text("Snakes"), Text("Other Animals"),Text("Accessories")
              ],

            ),
            ExpansionTile(
              title: TextButton( onPressed: () { Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Aboutuspage()),
              ); }, child: Text('About Us'),),

              children: <Widget>[
                Text("Who Are We"), Text("Vision"),Text("Mission"),Text("Terms & Conditions"),Text("How To Purchase")
              ],

            ),
            ExpansionTile(
              title: TextButton( onPressed: () { Navigator.pop(
                context,
              ); }, child: Text('Contact Us'),),
              children: <Widget>[
                Text("WhatsApp"), Text("Messenger")
              ],


            ),

          ],
        ),
      ),
    );

  }

}

class IndividualPageNews extends StatefulWidget{
  final fileurl;
  final collname;
  //final user;
  const IndividualPageNews({Key ? key, required this.fileurl,required this.collname}) : super(key:key);

  @override
  _IndividualPageNews createState() => new _IndividualPageNews();
//List<QuerySnapshot> pics = (await fb2.collection("files").where("url",isEqualTo: fileurl).get()) as List<QuerySnapshot<Object?>>;

}
class _IndividualPageNews extends State<IndividualPageNews>{
  //static const _url = 'whatsapp://send?phone=60133635145?text="hello"';

  Future<QuerySnapshot> getImages() {
    //return fb.collection("newfiles").where("url", isEqualTo:widget.fileurl).get();
    return fb.collection(widget.collname).where("url", isEqualTo:widget.fileurl).get();
  }
  final FirebaseFirestore fb = FirebaseFirestore.instance;
  TextEditingController _textFieldController = TextEditingController();
  String valueText = "No desc";
  String name = "Name";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        //title: Text(),
        backgroundColor: Colors.amber,
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: FutureBuilder(
          future: getImages(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    var a =snapshot.data?.docs[index].data() ?? {"newsTitle":"hi","url":"none","newsSmall":"none","newsBig":"none"};
                    name = (a as Map)["newsTitle"];
                    return Card(
                      color: Colors.black,
                      clipBehavior: Clip.antiAlias,
                      child:
                      Column(
                        children: [
                          ListTile(
                            //leading: Icon(Icons.bolt,color: Colors.amber,),

                            title: Text(ReCase((a as Map)["newsTitle"]).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold),),
                            subtitle: Text(
                              (a as Map)["newsSmall"],
                              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                            ),
                            //tileColor: Colors.black,

                          ),
                          Container(
                            //color: Colors.black,
                            height: 200.0,
                            child: Image.network(
                              //snapshot.data?.docs[index].data()!["url"],
                                (a as Map)["url"],
                                fit: BoxFit.fill),
                          ),
                          Container(
                            //color: Colors.black,
                            padding: EdgeInsets.all(16.0),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              (a as Map)["newsBig"],
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                        ],
                      ),
                    );


                  });
            } else if (snapshot.connectionState == ConnectionState.none) {
              return Text("No data");
            }
            return CircularProgressIndicator(color: Colors.amber,);
          },

        ),

      ),


    );

  }

}
class SnakeCont extends StatefulWidget{
  final dbtabname;
  final searchname;
  const SnakeCont({Key?key, required this.dbtabname, required this.searchname}):super(key:key);

  @override
  _SnakeCont createState() => new _SnakeCont();
}
class _SnakeCont extends State<SnakeCont>{
  final FirebaseFirestore fb2 = FirebaseFirestore.instance;
  Future<QuerySnapshot> getImages2dup(searchtext) {
    var name = widget.dbtabname;
    print("i am name"+ name);
    /*if (name=='Pythons'){
      setState(()=>name='newfiles');
    }*/
    //Future<QuerySnapshot> qa = fb2.collection(name).get();
    Future<QuerySnapshot> qa = fb2.collection("allanimals").where("section",isEqualTo: name).get();
    //return fb2.collection("newfiles").get();
    return qa;
  }
  @override
  Widget build(BuildContext context) {
    return Container( //snakes
      child:
      FutureBuilder(
        //future: getImages2(_searchText),
        future: getImages2dup(widget.searchname),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var snakecards = snapshot.data?.docs.map((doc) => Animalcard(
              name: doc['visibleName'],
              type: doc['type'],
              url: doc['url'],
              desc: doc['desc'],
              colour: doc['colour'],
            )).toList();
           // print("I am lengthhhhh "+snakecards?.length);
            snakecards = snakecards?.where((element) => element.name.toLowerCase().contains(widget.searchname.toLowerCase())).toList();
            return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                //itemCount: snapshot.data?.docs.length,
                itemCount: snakecards?.length,
                itemBuilder: (BuildContext context, int index) {
                  var a =snapshot.data?.docs[index].data() ?? {"name":"hi","url":"none","desc":"none"};
                  print("width");
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    color: Colors.black,
                    child:
                    Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.bolt,color: Colors.amber,),
                          //title: Text("Name: "+ReCase((a as Map)["visibleName"]).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold)),
                          title: Text("Name: "+ReCase(snakecards![index].name).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            //"Type: "+(a as Map)["type"],
                            "Type: "+snakecards![index].type,
                            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                          ),
                          //trailing: Icon(Icons.favorite_outline),
                        ),
                        Container(
                          height: 200.0,
                          child: Image.network(snakecards![index].url,
                              width: MediaQuery.of(context).size.width*0.75,
                              height:200,
                              //width:200,
                              fit: BoxFit.fitWidth,
                            //snapshot.data?.docs[index].data()!["url"],
                            //(a as Map)["url"],

                              //fit: BoxFit.fill
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(16.0),
                          alignment: Alignment.centerLeft,
                          //child: Text("Description: "+(a as Map)["desc"]),
                          child: Text("Description: "+snakecards![index].desc),
                        ),
                        Stack(children: <Widget>[ListTile(
                          title: Text("Price",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
                          //subtitle: Text((a as Map)["colour"],style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                          subtitle: Text(snakecards![index].colour,style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                          tileColor: Colors.amber,
                        ),
                          Positioned(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    //MaterialPageRoute(builder: (context) => IndividualPage(fileurl:(a as Map)["url"],collname: "newfiles")),
                                    MaterialPageRoute(builder: (context) => IndividualPage(fileurl:snakecards![index].url,collname: widget.dbtabname)),
                                  );
                                },
                                child: const Text('View',style: TextStyle(color: Colors.black)),
                              ),
                              bottom: 15,
                              right:15)
                        ])
                      ],
                    ),
                  );
                });
          } else if (snapshot.connectionState == ConnectionState.none) {
            return Text("No data");
          }
          /*return SizedBox(
                        child: LinearProgressIndicator(),
                        height: 5.0,
                        width: 5.0,
                      );*/
          return Text("Loading...");
        },

      ),
    );
  }

}
class TabPage extends StatefulWidget{
  final dbtabname;
  final searchname;
  const TabPage({Key?key, required this.dbtabname, required this.searchname}):super(key:key);
  @override
  _TabPage createState()=>new _TabPage();
}
class _TabPage extends State<TabPage>{
  final FirebaseFirestore fb2 = FirebaseFirestore.instance;
  Future<QuerySnapshot> getImages2dup(searchtext) {
    //Future<QuerySnapshot> qa = fb2.collection(widget.dbtabname).get();

    Future<QuerySnapshot> qa = fb2.collection("allanimals").where("section",isEqualTo:widget.dbtabname).get();
    //return fb2.collection("newfiles").get();
    return qa;
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child:Column(children:[
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
          child:Text(widget.dbtabname,style:TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 24))),
      Container( //snakes
        child:
        FutureBuilder(
          //future: getImages2(_searchText),
          future: getImages2dup(widget.searchname),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              var snakecards = snapshot.data?.docs.map((doc) => Animalcard(
                name: doc['visibleName'],
                type: doc['type'],
                url: doc['url'],
                desc: doc['desc'],
                colour: doc['colour'],
              )).toList();
              snakecards = snakecards?.where((element) => element.name.toLowerCase().contains(widget.searchname.toLowerCase())).toList();
              return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  //itemCount: snapshot.data?.docs.length,
                  itemCount: snakecards?.length,
                  itemBuilder: (BuildContext context, int index) {
                    var a =snapshot.data?.docs[index].data() ?? {"name":"hi","url":"none","desc":"none"};
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      color: Colors.black,
                      child:
                      Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.bolt,color: Colors.amber,),
                            //title: Text("Name: "+ReCase((a as Map)["visibleName"]).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold)),
                            title: Text("Name: "+ReCase(snakecards![index].name).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              //"Type: "+(a as Map)["type"],
                              "Type: "+snakecards![index].type,
                              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                            ),
                            //trailing: Icon(Icons.favorite_outline),
                          ),
                          Container(
                            height: 200.0,
                            child: Image.network(
                              //snapshot.data?.docs[index].data()!["url"],
                              //(a as Map)["url"],

                                snakecards![index].url,
                              width: MediaQuery.of(context).size.width*0.75,
                              height:200,
                              //width:200,
                              fit: BoxFit.fitWidth,
                               // fit: BoxFit.fitHeight
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(16.0),
                            alignment: Alignment.centerLeft,
                            //child: Text("Description: "+(a as Map)["desc"]),
                            child: Text("Description: "+snakecards![index].desc),
                          ),
                          Stack(children: <Widget>[ListTile(
                            title: Text("Price",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
                            //subtitle: Text((a as Map)["colour"],style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                            subtitle: Text(snakecards![index].colour,style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                            tileColor: Colors.amber,
                          ),
                            Positioned(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      //MaterialPageRoute(builder: (context) => IndividualPage(fileurl:(a as Map)["url"],collname: "newfiles")),
                                      MaterialPageRoute(builder: (context) => IndividualPage(fileurl:snakecards![index].url,collname: widget.dbtabname)),
                                    );
                                  },
                                  child: const Text('View',style: TextStyle(color: Colors.black)),
                                ),
                                bottom: 15,
                                right:15)
                          ])
                        ],
                      ),
                    );
                  });
            } else if (snapshot.connectionState == ConnectionState.none) {
              return Text("No data");
            }
            /*return SizedBox(
                        child: LinearProgressIndicator(),
                        height: 5.0,
                        width: 5.0,
                      );*/
            return Text("Loading...");
          },

        ),
      )]));
  }

}

class IndividualPage extends StatefulWidget{
  final fileurl;
  final collname;
  //final user;
  const IndividualPage({Key ? key, required this.fileurl,required this.collname}) : super(key:key);

  @override
  _IndividualPage createState() => new _IndividualPage();
  //List<QuerySnapshot> pics = (await fb2.collection("files").where("url",isEqualTo: fileurl).get()) as List<QuerySnapshot<Object?>>;

}
class _IndividualPage extends State<IndividualPage>{
  //static const _url = 'whatsapp://send?phone=60133635145?text="hello"';
  @override
  void initState(){
    getLoggedInstate();
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
    getcontactdeet();
    super.initState();
  }
  String _urlval = 'whatsapp://send?phone=60102214405';
  final FirebaseFirestore fbcontact = FirebaseFirestore.instance;
  Future<QuerySnapshot> getcontact() {
    Future<QuerySnapshot> qa = fbcontact.collection("contactdetails").get();
    return qa;
  }
  void getcontactdeet() {
    fbcontact.collection("contactdetails").get().then((value) {
      setState(() {
        _urlval = 'whatsapp://send?phone=6'+value.docs[0].get("number");
      });
    });

    //return qa;
  }

  void _launchURL2() async => await canLaunch(_urlval)
      ? await launch(_urlval) : throw 'Not found $_urlval';

  static const String _url = 'whatsapp://send?phone=60133635145&text=hello';
  void _launchURL(String func) async => await canLaunch(_url)
      ? await launch('whatsapp://send?phone=60133635145&text= ${func} On Product Name: ${ReCase(name).titleCase}') : throw 'Not found $_url';


  static const _actionTitles = ['Enquire on Product', 'Place Order'];

  Future<QuerySnapshot> getImages() {
    //return fb.collection("newfiles").where("url", isEqualTo:widget.fileurl).get();
    return fb.collection("allanimals").where("section",isEqualTo:widget.collname).where("url", isEqualTo:widget.fileurl).get();
  }
  bool userisloggedin = false;
  final FirebaseFirestore fb = FirebaseFirestore.instance;
  TextEditingController _textFieldController = TextEditingController();
  String valueText = "No desc";
  String name = "Name";
  getLoggedInstate()async{
    await HelperFunctions.getUserLoggedSharedPreference().then((value) {
      setState(() {
        userisloggedin = value!;
      });
    });
  }
  void _showAction(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text("Product Name: "+ReCase(name).titleCase),
          actions: [
            TextButton(
              onPressed:()=> _launchURL2(),
              child: //const Text('CLOSE'),
               Text(_actionTitles[index]),

            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        //title: Text(),
        backgroundColor: Colors.amber,
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: FutureBuilder(
          future: getImages(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    var a =snapshot.data?.docs[index].data() ?? {"name":"hi","url":"none","colour":"none","visibleName":"none","desc":"none","type":"none"};
                    name = (a as Map)["visibleName"];
                    return Card(
                      color: Colors.black,
                      clipBehavior: Clip.antiAlias,
                      child:
                      Column(
                        children: [
                          ListTile(
                            //leading: Icon(Icons.bolt,color: Colors.amber,),

                            title: Text("Name: "+ReCase((a as Map)["visibleName"]).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold),),
                            subtitle: Text(
                              "Item Code: "+(a as Map)["code"],
                              style: TextStyle(color: Colors.white),
                            ),
                            //tileColor: Colors.black,

                          ),
                          Container(
                            //color: Colors.black,
                            height: 200.0,
                            child: Image.network(
                              //snapshot.data?.docs[index].data()!["url"],
                                (a as Map)["url"],
                                fit: BoxFit.fill),
                          ),
                          Container(
                            //color: Colors.black,
                            padding: EdgeInsets.all(16.0),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Type: "+(a as Map)["type"],
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Container(
                            //color: Colors.black,
                            padding: EdgeInsets.all(16.0),
                            alignment: Alignment.centerLeft,
                            child: Text("Description: "+(a as Map)["desc"],style: TextStyle(color: Colors.white),),

                          ),

                          ListTile(

                            title: Text("Price",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text((a as Map)["colour"],style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            tileColor: Colors.amber,
                          ),
                        ],
                      ),
                    );


                  });
            } else if (snapshot.connectionState == ConnectionState.none) {
              return Text("No data");
            }
            return CircularProgressIndicator(color: Colors.amber,);
          },

        ),

      ),
      floatingActionButton: ExpandableFab(
        distance: 112.0,
        children: [
          /*ActionButton(
            onPressed: () => _showAction(context, 0),
            icon: const Icon(Icons.question_answer,),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),*/
          ActionButton(

            onPressed: () => _showAction(context, 0),
            icon:
            //const Icon(Icons.shopping_cart,            ),
            Icon(Messenger.whatsapp, color: Colors.white,)


          ),
          ActionButton(

            onPressed: ()  {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => userisloggedin?ChatRoom():Authenticate()),
              );
            },
            icon: const Icon(Icons.mail_outline,
            ),


          ),

        ],
      ),

    );

  }

}
class CollectionsPage extends StatefulWidget{
  final pagenum;

  const CollectionsPage({
    required this.pagenum,
    Key ? key
  }) : super(key:key);
  @override
  State<CollectionsPage> createState() => _CollectionsPage();
}
@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    Key? key,
    this.initialOpen,
    required this.distance,
    required this.children,
  }) : super(key: key);

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  _ExpandableFabState createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );

  }



  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                //color: Theme.of(context).primaryColor,
                color: Colors.amber,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
    i < count;
    i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,

          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: const Icon(Icons.add),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    Key? key,
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  }) : super(key: key);

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    Key? key,
    this.onPressed,
    required this.icon, MaterialColor backgroundColor=Colors.amber, Color foregroundColor=Colors.black,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),

      clipBehavior: Clip.antiAlias,
      color: Colors.amber,
      elevation: 4.0,
      child: IconTheme.merge(

        data: theme.accentIconTheme,
        child: IconButton(
          onPressed: onPressed,
          icon: icon,

        ),
      ),
    );
  }
}

@immutable
class FakeItem extends StatelessWidget {
  const FakeItem({
    Key? key,
    required this.isBig,
  }) : super(key: key);

  final bool isBig;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      height: isBig ? 128.0 : 36.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: Colors.grey.shade300,
      ),
    );
  }
}
class ChatPage extends StatefulWidget{
  final User2 user;
  const ChatPage({
    required this.user,
    Key? key,
}) : super(key: key);
  @override
  _ChatPageState createState()=>_ChatPageState();
}
class _ChatPageState extends State<ChatPage>{
  @override
  Widget build (BuildContext context)=>Scaffold(
    extendBodyBehindAppBar: true,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child:Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:Radius.circular(25),
                  topRight:Radius.circular(25),
                ),
              ),
              child: MessagesWidget(idUser:widget.user.idUser!),
            ),
          ),
          NewMessageWidget(idUser:widget.user.idUser!)
        ],
      )
    ),
  );
}
class ChatsPage extends StatelessWidget{
  List a=[];
  @override
  Widget build(BuildContext context) =>Scaffold(
    body: SafeArea(
      child: StreamBuilder<List<User2>>(
        stream: FirebaseApiUsers.getUsers(),
        builder: (context, snapshot){
          switch (snapshot.connectionState){
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError){
                return buildText('Try again later');
              }
              else{
                final users = snapshot.data;
                return Column(
                    children:[
                      ChatBodyWidget(users: users ?? <User2> [User2(idUser: "001"
                          //, name: "Vinitha", urlAvatar: 'https://preview.redd.it/dh5otp8kcf741.png?width=640&crop=smart&auto=webp&s=d795f12b5e3eea1ef4d7ceb8244fca98e2384dbf', lastMessageTime: DateTime.now()
                      )])
                    ]
                );
              }
          }

        }
      ),
    )
  );
  Widget buildText(String text) => Center(
    child: Text(
      text,
      style: TextStyle(fontSize: 24, color: Colors.white),
    ),
  );

}
class _CollectionsPage extends State<CollectionsPage>{

  int _selectedIndex = 1;
  final TextEditingController _controller = new TextEditingController();
  late List<dynamic> _list;
  late bool _isSearching;
  String _searchText = "";
  List searchresult = [];
  final List<String> snakepagelist = <String>['Pythons','Colubrids','Giant Snakes'];
  String selectedItem = 'Pythons';
  String selectedGroup = 'Pythons';
  Widget appBarTitle = new Text(
    "Search by Name",
    style: GoogleFonts.teko(
      textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0,fontSize: 14, fontStyle: FontStyle.italic),
    ),
  );

  String? value;
  @override
  void initState(){
    _connectivity.initialise();
    _connectivity.myStream.listen((source) {
      setState(() => _source = source);
    });
  }
  Map _source = {ConnectivityResult.none: false};
  final MyConnectivity _connectivity = MyConnectivity.instance;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<QuerySnapshot> getImages2(searchtext) {
    //Future<QuerySnapshot> qa = fb2.collection("newfiles").where("visibleName",isGreaterThanOrEqualTo: searchtext).where("visibleName",isLessThanOrEqualTo: searchtext+ '\uf8ff').get();
    Future<QuerySnapshot> qa = fb2.collection("allanimals").where("section",isEqualTo: "Pythons").where("visibleName",isGreaterThanOrEqualTo: searchtext).where("visibleName",isLessThanOrEqualTo: searchtext+ '\uf8ff').get();
    //return fb2.collection("newfiles").get();
    return qa;
  }
  Future<QuerySnapshot> getImages2dup(searchtext) {
    //Future<QuerySnapshot> qa = fb2.collection("newfiles").get();
    Future<QuerySnapshot> qa = fb2.collection("allanimals").where("section",isEqualTo: "Pythons").get();
    //return fb2.collection("newfiles").get();
    return qa;
  }
  Future<QuerySnapshot> getImages3(tabname,searchtext) {
    //Future<QuerySnapshot> qa = fb2.collection(tabname).where("visibleName",isGreaterThanOrEqualTo: searchtext).where("visibleName",isLessThanOrEqualTo: searchtext+ '\uf8ff').get();
    Future<QuerySnapshot> qa = fb2.collection("allanimals").where("section",isEqualTo: tabname).where("visibleName",isGreaterThanOrEqualTo: searchtext).where("visibleName",isLessThanOrEqualTo: searchtext+ '\uf8ff').get();
    //return fb2.collection("newfiles").get();
    return qa;
    return fb2.collection(tabname).get();
  }
  Future<QuerySnapshot> getImages3dup(tabname,searchtext) {
    //Future<QuerySnapshot> qa = fb2.collection(tabname).get();
    Future<QuerySnapshot> qa = fb2.collection("allanimals").where("section",isEqualTo: tabname).get();
    //return fb2.collection("newfiles").get();
    return qa;
    return fb2.collection(tabname).get();
  }
  final FirebaseFirestore fb2 = FirebaseFirestore.instance;
  Icon icon =  Icon(
    Icons.search,
    color: Colors.white,
  );
  void _handleSearchStart() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    setState(() {
      this.icon = new Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = new Text(
        "",
        style: GoogleFonts.teko(
          textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0, fontSize: 6, fontStyle: FontStyle.italic,height: .4),
        ),
      );
      _isSearching = false;
      _controller.clear();
    });
  }

  void searchOperation(String searchText) {
    searchresult.clear();
    if (_isSearching != null) {
      for (int i = 0; i < _list.length; i++) {
        String data = _list[i];
        if (data.toLowerCase().contains(searchText.toLowerCase())) {
          searchresult.add(data);
        }
      }
    }
  }
  _CollectionsPage(){
  _controller.addListener(() {
  if (_controller.text.isEmpty) {
  setState(() {
  _isSearching = false;
  _searchText = "";
  });
  } else {
  setState(() {
  _isSearching = true;
  _searchText = _controller.text;
  });
  }
  });

}
  @override
  Widget build(BuildContext context) {
    int selectedPage=widget.pagenum;
    if (_source.keys.toList()[0]==ConnectivityResult.none){
      return Scaffold(
          backgroundColor: Colors.black,
          body:NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text("C O L L E C T I O N S",
                    style: GoogleFonts.teko(
                      textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold,height: .4),

                    )),
                background: Image.asset(
                  //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
                    'ims/collections.png',
                    fit: BoxFit.cover
                )
            ),
          ),
        ];
      },
    body:Center(child:Text("Oops! Looks like you're offline",style:
    GoogleFonts.ubuntu(
        textStyle:
        TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 18)
    )
    ))
          ));
    }
    else{

      return Scaffold(
        backgroundColor: Colors.black,
        body:NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 100.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text("C O L L E C T I O N S",
                      style: GoogleFonts.teko(
                        textStyle: TextStyle(color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold,height: .4),

                      )),
                  background: Image.asset(
                    //'https://images.theconversation.com/files/416907/original/file-20210819-13-vseajg.jpg?ixlib=rb-1.1.0&rect=0%2C0%2C1191%2C797&q=45&auto=format&w=926&fit=clip',
                      'ims/collections.png',
                      fit: BoxFit.cover
                  )
              ),
            ),
          ];
        },
      body:
      DefaultTabController(
        initialIndex: selectedPage,
        length: 6,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: PreferredSize(
              preferredSize: Size.fromHeight(100.0),

              child:AppBar(centerTitle: true, title: appBarTitle,actions: <Widget>[
                new IconButton(
                  icon:  icon,
                  onPressed: () {
                    setState(() {
                      if (this.icon.icon == Icons.search) {
                        this.icon = new Icon(
                          Icons.close,
                          color: Colors.white,
                        );
                        this.appBarTitle = new TextField(
                          controller: _controller,
                          style: new TextStyle(
                            color: Colors.white,
                          ),
                          decoration: new InputDecoration(
                              prefixIcon: new Icon(Icons.search, color: Colors.white),
                              hintText: "Search...",
                              hintStyle: new TextStyle(color: Colors.white)),
                          onChanged: searchOperation,
                        );
                        _handleSearchStart();
                      } else {
                        _handleSearchEnd();
                      }
                    });
                  },
                ),
              ],
              bottom: TabBar(
              indicatorColor: Colors.amber,
              tabs: [
                Tab(icon: Icon(MyFlutterApp.snake,color: Colors.white,)),
                Tab(icon: Image.asset("ims/curved-lizard.png")),
                Tab(icon: Image.asset("ims/turtle.png")),
                Tab(icon: Image.asset("ims/animal.png")),
                Tab(icon: Icon(Icons.pest_control_rodent,color: Colors.white,)),
                Tab(icon: Icon(Icons.auto_awesome,color: Colors.white,)),
              ],
            ),
            backgroundColor: Colors.black,
          )),
          body:
          TabBarView(
            children: [
              SingleChildScrollView(child:Column(children:[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 6.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),

                    child:Center(child:DropdownButton<String>(

                  value:selectedItem,
                  dropdownColor: Colors.black87,
                  selectedItemBuilder: (BuildContext context) {
                    return snakepagelist.map<Widget>((String item) {
                      return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 8),
                          child:Center(child:Text(item,style:TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 24))));
                    }).toList();
                  },
                  isExpanded: true,
                  iconSize: 36,
                  icon: Icon(Icons.arrow_drop_down, color:Colors.amber),
                  items: snakepagelist.map((String item) {
                    return DropdownMenuItem<String>(

                        value:item,child: Text(item,style:
                      TextStyle(color: Colors.amber, fontWeight: FontWeight.bold,height: .4),

                    ),

                    );
                  }).toList(),
                onChanged: (String? value)=> setState(()=>
                selectedItem=value!
                ),
                ))),
              SnakeCont(dbtabname: selectedItem, searchname: _searchText)
              ]))
              ,
              TabPage(dbtabname: "Lizards", searchname: _searchText),
              TabPage(dbtabname: "Tortoise & Turtles", searchname: _searchText),
              TabPage(dbtabname: "Feeders", searchname: _searchText),
              TabPage(dbtabname: "Other Animals", searchname: _searchText),
              TabPage(dbtabname: "Accessories", searchname: _searchText),

              ],
          ),
        ),
      ),
      //])
    ),
      drawer: Drawer(
        backgroundColor: Colors.white,

        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              accountName: Text(""),
              accountEmail: Text("kyjexotics@gmail.com"),
              currentAccountPicture: ClipOval(
                child: Image.asset("ims/logo.jpg"),
              ),
            ),
            ExpansionTile(
              title: TextButton( onPressed: () {  Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage(title: "Home")),
              ); }, child: Text("Home"),),


            ),
            ExpansionTile(
              title: TextButton( onPressed: () { Navigator.pop(context); }, child: Text("Collections"),),

              children: <Widget>[
                Text("Snakes"), Text("Other Animals"),Text("Accessories")
                ],

            ),
            ExpansionTile(
              title: TextButton( onPressed: () { Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Aboutuspage()),
              ); }, child: Text('About Us'),),

              children: <Widget>[
                Text("Who Are We"), Text("Vision"),Text("Mission"),Text("How To Purchase")
              ],

            ),
            ExpansionTile(
              title: TextButton( onPressed: () { Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Contactuspage()),
              ); }, child: Text('Contact Us'),),



            ),


          ],
        ),
      ),
    );}

  }

}
class ChatMessageList3 extends StatefulWidget{
  //const Conversation({Key ? key}) : super(key:key);
  final String chatroomid;
  final ValueChanged onSwipedMessage;
  final FocusNode focusnode;
  final String replymessage;
  final VoidCallback onCancelReply;
  final int replyind;

  const ChatMessageList3(this.chatroomid,this.onSwipedMessage, this.focusnode,this.replymessage,this.onCancelReply,this.replyind);
  @override
  State<ChatMessageList3> createState() => ChatmessageList3State();
}
class ChatmessageList3State extends State<ChatMessageList3>{
  TextEditingController messageEditingController = new TextEditingController();
  DatabaseMethods dbmethods = new DatabaseMethods();
  late Stream<QuerySnapshot> chatmessagesstream;

  Timer? _timer;
  //late final ValueChanged onSwipedMessage;

  var chatroomid;

  final ScrollController _scrollController = ScrollController(initialScrollOffset: 20);
  bool _needsScroll = true;

  late StreamController<int> _events;

  @override
  initState() {
    super.initState();
    _events = new StreamController<int>();
    _events.add(0);
    EasyLoading.addStatusCallback((status) {
      print('EasyLoading Status $status');
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });

  }

  _scrollToEnd() async {
    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.ease, duration: Duration (milliseconds: 20));

  }
  final double _height = 80;
  _scrollToIndex(int index)  {
    _scrollController.animateTo(
        _height*index,
        curve: Curves.ease, duration: Duration (milliseconds: 20));


  }
  bool checkcurve = false;
  Widget buildReply(String str, int ind) {
    checkcurve = true;
    print(ind);
    print(str);
    return GestureDetector(child:Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: inputTopRadius,
            topRight: inputTopRadius,
          ),
        ),
        child:str.contains("firebase")?ReplyMessageWidget(
            message:"Image",
            onCancelreply:widget.onCancelReply
        ):ReplyMessageWidget(
            message:str,
            onCancelreply:widget.onCancelReply
        )),
        //onTap: (ind!=0&&ind!=null)?scroll2(ind):(){}
        );
  }
  Widget buildReply2(String str, int ind) {
    checkcurve = true;
    print(ind);
    print(str);
    return GestureDetector(child:Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: inputTopRadius,
            topRight: inputTopRadius,
          ),
        ),
        child:str.contains("firebase")?ReplyMessageWidget2(
            message:"Image",
            //onCancelreply:widget.onCancelReply
        ):ReplyMessageWidget2(
            message:str,
            //onCancelreply:widget.onCancelReply
        )),
      //onTap: (ind!=0&&ind!=null)?scroll2(ind):(){}
    );
  }
  bool ispic=false;
  static final inputTopRadius = Radius.circular(12);
  static final inputBottomRadius = Radius.circular(24);
  sendmessage(){
    String message = messageEditingController.text;
    Map<String, dynamic> messagemap={
      "message": messageEditingController.text,
      "sendby":Constants.myName,
      "time":DateTime.now().millisecondsSinceEpoch,
      "type":"text",
      "replyingto":widget.replymessage,
      "ind":widget.replyind

    };
    final _firestore = FirebaseFirestore.instance;

    dbmethods.addConversationmessages(widget.chatroomid, messagemap);
    var owntoken = "";
    //if (qtoken.docs.length == 0){

    FirebaseFirestore.instance.collection('allusers').where("name",isEqualTo: Constants.myName).get().then(
            (qsnap){
              var totoken = qsnap.docs[0].get("ownertoken");
              print(totoken+"naan dhaan token");
              var time = DateTime.now().millisecondsSinceEpoch;
          qsnap.docs.forEach((element) {
            FirebaseFirestore.instance.collection('allusers').doc(element.id).update({
              'totoken':owntoken,
              'ownertoken':owntoken,
              'lastmessage': message,
              "time":time,
              'lastmessageauthor':Constants.myName,
              "lastopenedbyclient":time
            });
            var chatmap = {
              'totoken':totoken,
              'lastmessage': message,
              "time":time,
              'lastmessageauthor':Constants.myName,
              "lastopenedbyclient":time
            };
            FirebaseFirestore.instance.collection("alluserschats")
                .add(chatmap).catchError((e){
              print(e.toString());
            });
          });
        }
    );

    messageEditingController.text="";
    _needsScroll = true;
    SchedulerBinding.instance?.addPostFrameCallback(
            (_) =>
            _scrollToEnd()
    );

  }
  final itemController = ItemScrollController();
  final ImagePicker _picker = ImagePicker();
  var storage = FirebaseStorage.instance;
  bool isLoading = false;
  List<XFile>? images = [];
  scroll2 (int index){
    itemController.jumpTo(index: index);
  }

  void selectImages() async{
    ispic=true;
    final List<XFile>? selectedimages = await _picker.pickMultiImage();
    if (selectedimages!.isNotEmpty){
      images!.addAll(selectedimages);
      setState(() {
        this.isLoading = true;
      });
      EasyLoading.show(status: 'Sending...');
      print("Sendinggggg");
      int count = 0;
      images!.forEach((img) async {
        File img2 = File(img.path);
        String imageName = Path.basename(img2.path);
        count = count+1;
        print("Filename is "+imageName);

        TaskSnapshot snapshot = await storage
            .ref()
            .child(widget.chatroomid+"/$imageName")
            .putFile(img2);
        if (snapshot.state == TaskState.success) {
          EasyLoading.show(status: 'Sending...');

          final String downloadUrl =
          await snapshot.ref.getDownloadURL();
          Map<String, dynamic> messagemap={
            "message": downloadUrl,
            "sendby":Constants.myName,
            "time":DateTime.now().millisecondsSinceEpoch,
            "type":"img",
            "replyingto":widget.replymessage,
            "ind":0,
          };
          setState(() {
            isLoading = false;
          });
          dbmethods.addConversationmessages(widget.chatroomid, messagemap);
          var owntoken = "";
          //if (qtoken.docs.length == 0){

          FirebaseFirestore.instance.collection('allusers').where("name",isEqualTo: Constants.myName).get().then(
                  (qsnap){
                    var totoken = qsnap.docs[0].get("ownertoken");
                    print(totoken+"naan dhaan token");
                    var time = DateTime.now().millisecondsSinceEpoch;
                qsnap.docs.forEach((element) {
                  FirebaseFirestore.instance.collection('allusers').doc(element.id).update({
                    'totoken':owntoken,
                    'ownertoken':owntoken,
                    'lastmessage': "Attachment",
                    "time":time,
                    'lastmessageauthor':Constants.myName,
                    "lastopenedbyclient":time

                  });
                  var chatmap = {
                    'totoken':totoken,
                    'lastmessage': "Attachment",
                    "time":time,
                    'lastmessageauthor':Constants.myName,
                    "lastopenedbyclient":time
                  };
                  FirebaseFirestore.instance.collection("alluserschats")
                      .add(chatmap).catchError((e){
                    print(e.toString());
                  });
                });
              }
          );
          if (count==images!.length){
            EasyLoading.showSuccess("Sent");

          }

          _needsScroll = true;
          SchedulerBinding.instance?.addPostFrameCallback(
                  (_) =>
                  _scrollToEnd()
          );

        } else {
          print(
              'Error from image repo ${snapshot.state.toString()}');
          final snackBar =
          SnackBar(content: Text('Failedddddd'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          throw ('This file is not an image');
        }

      }

      );
    }
    print("Image length "+images!.length.toString());


  }
  @override
  Widget build(BuildContext context) {
    print(widget.chatroomid);
    print("i am chatromm");
    final isReplying = widget.replymessage!="";

    dbmethods.getConversationmessages(chatroomid).then((val){
      chatmessagesstream = val;
    });
    print("building again");

    return Column(children:[
      Expanded(child:StreamBuilder(

        stream: FirebaseFirestore.instance.collection("ChatRoom")
            .doc(widget.chatroomid)
            .collection("chats")
            .orderBy("time",descending: false)
        //.orderBy("time",descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot){

          //var files = snapshot.data!.docs.length ;
          return snapshot.hasData?
          ListView.builder(
          //    ScrollablePositionedList.builder(
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,

            //reverse: true,
            controller: _scrollController,
                //itemScrollController: itemController,
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (BuildContext context, int index) {

              if (_needsScroll) {
                print('at the bottom');
                SchedulerBinding.instance?.addPostFrameCallback(
                        (_) =>
                        _scrollToEnd()
                );
                _needsScroll = false;
              };
              print("check keyy");
              print(snapshot.data?.docs[index].data()["replyingto"]);
              print("pass");
              print(index);
              checkcurve = false;
              var sendBy = snapshot.data?.docs[index]["sendby"]== Constants.myName;
              var type = snapshot.data?.docs[index]["type"];
              var replyingto = snapshot.data?.docs[index]["replyingto"];
              var time = snapshot.data?.docs[index]["time"];
              return
                SwipeTo(

                    //onRightSwipe: () => {widget.onSwipedMessage(snapshot.data?.docs[index]["message"]),
                    onRightSwipe: () => {widget.onSwipedMessage([snapshot.data?.docs[index]["message"],index]),
                      //_needsScroll = true
                      print(index),
                      print("i am indexxxx")


                    },
                    child:

                   // Messagetile(snapshot.data?.docs[index]["message"],snapshot.data?.docs[index]["sendby"]== Constants.myName, snapshot.data?.docs[index]["type"],snapshot.data?.docs[index]["time"],snapshot.data?.docs[index]["replyingto"])
                    SingleChildScrollView
                      (child:

                    GestureDetector(child:Container(
                      //width: MediaQuery.of(context).size.width,

                      margin:  EdgeInsets.symmetric(vertical:5),
                      padding: EdgeInsets.only(
                        //top: 5,
                        //bottom: 5,
                          left: sendBy ? 0 : 24,
                          right: sendBy ? 24 : 0),
                      alignment: sendBy?Alignment.centerRight:Alignment.centerLeft,
                      child:
                      //Column(
                      Container(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width*0.7
                          ),
                          child:Column(
                              children:[
                                snapshot.data?.docs[index]["replyingto"]!=""?buildReply2(snapshot.data?.docs[index]["replyingto"],snapshot.data?.docs[index]["ind"]):Container(),
                                Container(

                                  alignment: sendBy?Alignment.bottomRight:Alignment.bottomLeft,
                                  padding: EdgeInsets.symmetric(horizontal:10,vertical:8),
                                  decoration: BoxDecoration(
                                    borderRadius: sendBy ? BorderRadius.only(
                                        topLeft: checkcurve?Radius.circular(0):Radius.circular(23),
                                        topRight: checkcurve?Radius.circular(0):Radius.circular(23),
                                        bottomLeft: Radius.circular(23)
                                    ) :
                                    BorderRadius.only(
                                        topLeft: checkcurve?Radius.circular(0):Radius.circular(23),
                                        topRight: checkcurve?Radius.circular(0):Radius.circular(23),
                                        bottomRight: Radius.circular(23)),
                                    color: sendBy?Colors.amber:Colors.white,
                                  ),
                                  child: type=="text"?Column(children: [Container(child:Text(snapshot.data?.docs[index]["message"], style:TextStyle(
                                      color:  sendBy?Colors.white:Colors.black,

                                      fontSize:17
                                  )),alignment:sendBy?Alignment.bottomRight:Alignment.bottomLeft,),Container(child:Text(DateFormat(' HH:mm, dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(time)).toString(), style:TextStyle(
                                    color:  Colors.black26,
                                    fontSize:8,
                                  ),textAlign: TextAlign.right,),alignment: Alignment.bottomRight,)],):Container(child:Column(children: [Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                          children: [GestureDetector(
                                            child: Hero(
                                              tag: snapshot.data?.docs[index]["message"],
                                              child: Image.network(
                                                //snapshot.data?.docs[index].data()!["url"],
                                                  snapshot.data?.docs[index]["message"],
                                                  fit: BoxFit.fitWidth),
                                            ),
                                            onTap: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (_) {
                                                return DetailScreen(snapshot.data?.docs[index]["message"]);
                                              }));
                                            },
                                          ),


                                          ])
                                  ),Text(DateFormat(' HH:mm, dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(time)).toString(), style:TextStyle(
                                    color:  Colors.black26,
                                    fontSize:8,
                                  ),textAlign: TextAlign.right,)],)
                                  ),
                                )])),
                      //)
                    )))
                )
              ;
            },

          ):Container();

        },
        //)
      )),
    SafeArea(child:Container(alignment: Alignment.bottomCenter,
    width: MediaQuery
        .of(context)
        .size
        .width,
   // height: 100,
    child:Container(
        padding: EdgeInsets.only(left: 6, right:6, bottom: 20,top:3),
//height: 120,
        color:Colors.black,
        child:
        Row(children: [Expanded(
            child:


            Column(children:[
              if (isReplying)buildReply(widget.replymessage,0),
              TextField(
                cursorColor: Colors.amber,
                focusNode: widget.focusnode,

                style: TextStyle(color: Colors.black),

                controller: messageEditingController,
                //style: simpleTextStyle(),

                decoration: InputDecoration(
                  hintText: "Message ...",
                  hintStyle: TextStyle(
                    color: Colors.black45,
                    fontSize: 16,
                  ),
                  focusColor: Colors.white,
                  focusedBorder:OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber, width: 2.0),
                      borderRadius: BorderRadius.circular(20.0)
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  hoverColor: Colors.amber,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              )
            ])),
          GestureDetector(
            onTap: () {
              selectImages();
            },
            child: Container(
                //height: 150,
                width: 40,
                color: Colors.black,
                padding: EdgeInsets.all(12),
                child: Icon(Icons.attach_file,
                  size: 28,color: Colors.amber,)),
          ),
          GestureDetector(
            onTap: () {
              messageEditingController.text!=""?sendmessage():(){};
            },
            child: Container(
                //height: 150,
                width: 40,
                color: Colors.black,
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send,
                  size: 28,color: Colors.amber,)),
          ),
        ],)
      //)

    )))
    ]);
      //Scaffold(
      //resizeToAvoidBottomInset: false,
      //resizeToAvoidBottomPadding: false,
      //body:
      ;
  }
  @override
  void dispose(){
    super.dispose();
    FirebaseFirestore.instance.collection('allusers').where("name",isEqualTo: Constants.myName).get().then(
            (qsnap){
          var time = DateTime.now().millisecondsSinceEpoch;
          qsnap.docs.forEach((element) {
            FirebaseFirestore.instance.collection('allusers').doc(element.id).update({
              "lastopenedbyclient":time

            });
          });
        }
    );
  }

}
class ChatmessageList2 extends StatelessWidget{
  TextEditingController messageEditingController = new TextEditingController();
  DatabaseMethods dbmethods = new DatabaseMethods();
  late Stream<QuerySnapshot> chatmessagesstream;

  Timer? _timer;
  final ValueChanged onSwipedMessage;

  var chatroomid;
  ChatmessageList2({
    required this.chatroomid,
    required this.onSwipedMessage
  });
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 20);
  bool _needsScroll = true;

  _scrollToEnd() async {
    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.ease, duration: Duration (milliseconds: 20));

  }
  @override
  Widget build(BuildContext context) {
    dbmethods.getConversationmessages(chatroomid).then((val){
      chatmessagesstream = val;
    });
    print("building again");

    return
      //Scaffold(
        //resizeToAvoidBottomInset: false,
        //resizeToAvoidBottomPadding: false,
        //body:
        StreamBuilder(

      stream: FirebaseFirestore.instance.collection("ChatRoom")
          .doc(chatroomid)
          .collection("chats")
          .orderBy("time",descending: false)
          //.orderBy("time",descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot snapshot){

        //var files = snapshot.data!.docs.length ;
        return snapshot.hasData?ListView.builder(
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,

          //reverse: true,
          controller: _scrollController,

          itemCount: snapshot.data?.docs.length,
          itemBuilder: (BuildContext context, int index) {
            if (_needsScroll) {
              print('at the bottom');
              SchedulerBinding.instance?.addPostFrameCallback(
                      (_) =>
                      _scrollToEnd()
              );
              //_needsScroll = false;
            };
            print("check keyy");
            print(snapshot.data?.docs[index].data()["replyingto"]);
            print("pass");

            return
              SwipeTo(

                onRightSwipe: () => {onSwipedMessage(snapshot.data?.docs[index]["message"]),
                //_needsScroll = true

              },
                child:

                Messagetile(snapshot.data?.docs[index]["message"],snapshot.data?.docs[index]["sendby"]== Constants.myName, snapshot.data?.docs[index]["type"],snapshot.data?.docs[index]["time"],snapshot.data?.docs[index]["replyingto"])
            )
            ;
          },

        ):Container();

      },
    //)
    );
  }
}
class Conversation extends StatefulWidget{
  //const Conversation({Key ? key}) : super(key:key);
  final String chatroomid;
  //final ValueChanged onSwipedMessage;

  Conversation(this.chatroomid);
  @override
  State<Conversation> createState() => _ConversationState();
}
class _ConversationState extends State<Conversation>{
  String replyMessage ="";
  int replyind = 0;
  TextEditingController messageEditingController = new TextEditingController();
  DatabaseMethods dbmethods = new DatabaseMethods();
  late Stream<QuerySnapshot> chatmessagesstream;
  final focusnode = FocusNode();
  Timer? _timer;
  var owntoken=  "fHt7e-XERtuU6sJ1g1lgrc:APA91bGlcfnIAPNJtr4ncMC96pbGe26_nAr20goNfEG_SHIdJV_vAX6P7XJ4-8af0KPjT9BZBD8hX_47mF-630RAxB2hjo8LRHYfglCZ8E8ovBNWo_HSPNrjvpNZ_l9Fn3ffA1wthfTl";
  @override
  void initState(){
    dbmethods.getConversationmessages(widget.chatroomid).then((val){
      //setState(() {
        chatmessagesstream = val;
      //});
    });
    EasyLoading.addStatusCallback((status) {
      print('EasyLoading Status $status');
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });
    FirebaseFirestore.instance.collection('ownerdeets').get().then(
            (qsnap){
          setState(() {
            owntoken = qsnap.docs[0].get("ownertoken");
          });

          print(owntoken);
        });

    super.initState();
    bool _needsScroll = true;
  }
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 0);
  bool _needsScroll = true;

  _scrollToEnd() async {
    _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.ease, duration: Duration (milliseconds: 20));
  }

  @override
  Widget build(BuildContext context) {
    print("I am buildinggg");
    /*if (_needsScroll) {
      print('at the bottom 2');
      SchedulerBinding.instance?.addPostFrameCallback(
              (_) =>
              _scrollToEnd()
      );
      _needsScroll = false;
    };*/
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,

      appBar: AppBar(title:Text("Chat"),backgroundColor: Colors.amber,),
      body:
      //SingleChildScrollView(
      //Container(
Container(
      //SafeArea(
      //child: Stack(
          child: ChatMessageList3(widget.chatroomid,(message){
            replyToMessage(message);
            focusnode.requestFocus();
          },focusnode,this.replyMessage, cancelReply,this.replyind)

      ),
    );
  }

  void replyToMessage(message) {
    setState(() {
      replyMessage = message[0];
      replyind = message[1];
    });
    print(message[0]+"naan");
  }
  void cancelReply() {
    setState(() {
      replyMessage = "";
    });
  }
  
}
class ReplyMessageWidget extends StatelessWidget{
  final String message;
  var onCancelreply;
  ReplyMessageWidget({
    required this.message,
    required this.onCancelreply,
});

  @override
  Widget build(BuildContext context) {
    print("one message"+this.message);
    return IntrinsicHeight(child:
    Row(
      children: [
        Container(
          color: Colors.amber,
          width: 3
        ),
        const SizedBox(width:8),
        Expanded(child:buildReplymessage())
      ],
    ));
  }
  Widget buildReplymessage(){
    print("I am messageee"+message);
    print(this.onCancelreply);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: this.message!=""?Text(this.message,style:TextStyle(color:Colors.white)):Text(""),
            ),
            this.onCancelreply!=null?

              GestureDetector(
                child:Icon(Icons.close,size:16,color: Colors.white,),
                onTap: onCancelreply,
              ):GestureDetector(
              child:Icon(Icons.close,size:16,color: Colors.red,),
              onTap: onCancelreply,
            ),


          ],
        )
      ],
    );
  }
}
class ReplyMessageWidget2 extends StatelessWidget{
  final String message;
  var onCancelreply;
  ReplyMessageWidget2({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    print("one message hi"+this.message);
    return IntrinsicHeight(child:
    Row(
      children: [
        Container(
            color: Colors.amber,
            width: 3
        ),
        const SizedBox(width:8),
        Expanded(child:buildReplymessage())
      ],
    ));
  }
  Widget buildReplymessage(){
    print("I am messageee fifteen"+message);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: this.message!=""?Text(this.message,style:TextStyle(color:Colors.white)):Text(""),
            ),


          ],
        )
      ],
    );
  }
}
class NewMessage extends StatefulWidget{
  final FocusNode focusnode;
  final String replymessage;
  final VoidCallback onCancelReply;
  final String chatroomid;

const NewMessage({Key ? key, required this.focusnode, required this.replymessage, required this.onCancelReply, required this.chatroomid}) : super(key:key);
@override
State<NewMessage> createState() => _NewMessageState();
}
class _NewMessageState extends State<NewMessage>{
  DatabaseMethods dbmethods = new DatabaseMethods();
  bool _needsScroll = true;
  static final inputTopRadius = Radius.circular(12);
  static final inputBottomRadius = Radius.circular(24);
  TextEditingController messageEditingController = new TextEditingController();
  sendmessage(){
    String message = messageEditingController.text;
    Map<String, dynamic> messagemap={
      "message": messageEditingController.text,
      "sendby":Constants.myName,
      "time":DateTime.now().millisecondsSinceEpoch,
      "type":"text",
      "replyingto":widget.replymessage
    };
    dbmethods.addConversationmessages(widget.chatroomid, messagemap);
    FirebaseFirestore.instance.collection('allusers').where("name",isEqualTo: Constants.myName).get().then(
            (qsnap){
          qsnap.docs.forEach((element) {
            FirebaseFirestore.instance.collection('allusers').doc(element.id).update({
              'lastmessage': message,
              "time":DateTime.now().millisecondsSinceEpoch,
              'lastmessageauthor':Constants.myName,

            });
          });
        }
    );
    messageEditingController.text="";
    //_needsScroll = true;

  }

  final ImagePicker _picker = ImagePicker();
  var storage = FirebaseStorage.instance;
  bool isLoading = false;
  List<XFile>? images = [];

  void selectImages() async{
    final List<XFile>? selectedimages = await _picker.pickMultiImage();
    if (selectedimages!.isNotEmpty){
      images!.addAll(selectedimages);
      setState(() {
        this.isLoading = true;
      });
      EasyLoading.show(status: 'Sending...');
      int count = 0;
      images!.forEach((img) async {
        File img2 = File(img.path);
        String imageName = Path.basename(img2.path);
        count = count+1;
        print("Filename is "+imageName);

        TaskSnapshot snapshot = await storage
            .ref()
            .child(widget.chatroomid+"/$imageName")
            .putFile(img2);
        if (snapshot.state == TaskState.success) {
          final String downloadUrl =
          await snapshot.ref.getDownloadURL();
          Map<String, dynamic> messagemap={
            "message": downloadUrl,
            "sendby":Constants.myName,
            "time":DateTime.now().millisecondsSinceEpoch,
            "type":"img",
            "replyingto":""
          };
          setState(() {
            isLoading = false;
          });
          dbmethods.addConversationmessages(widget.chatroomid, messagemap);
          FirebaseFirestore.instance.collection('allusers').where("name",isEqualTo: Constants.myName).get().then(
                  (qsnap){
                qsnap.docs.forEach((element) {
                  FirebaseFirestore.instance.collection('allusers').doc(element.id).update({
                    'lastmessage': "Attachment",
                    "time":DateTime.now().millisecondsSinceEpoch,
                    'lastmessageauthor':Constants.myName,

                  });
                });
              }
          );
          if (count==images!.length){
            EasyLoading.showSuccess("Sent");

          }

        } else {
          print(
              'Error from image repo ${snapshot.state.toString()}');
          final snackBar =
          SnackBar(content: Text('Failedddddd'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          throw ('This file is not an image');
        }

      }

      );
    }
    print("Image length "+images!.length.toString());


  }
  @override
  Widget build(BuildContext context) {
    final isReplying = widget.replymessage!="";
    // TODO: implement build
    return
      Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),

    color:Colors.white,
    child:
    Row(children: [Expanded(
            child:


              Column(children:[
                if (isReplying)buildReply(),
                TextField(
                  focusNode: widget.focusnode,
                  style: TextStyle(color: Colors.black),

                  controller: messageEditingController,
                  //style: simpleTextStyle(),

                  decoration: InputDecoration(
                    hintText: "Message ...",
                    hintStyle: TextStyle(
                      color: Colors.black45,
                      fontSize: 16,

                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),

                  ),
                )
              ])),
              SizedBox(width: 16,),
              GestureDetector(
                onTap: () {
                  selectImages();
                },
                child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40)
                    ),
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.attach_file,
                      size: 25,)),
              ),
              GestureDetector(
                onTap: () {
                  sendmessage();
                },
                child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40)
                    ),
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send,
                      size: 25,)),
              ),
            ],)
        //)

      );
  }

  Widget buildReply() {
    return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: inputTopRadius,
            topRight: inputTopRadius,
          ),
        ),
        child:ReplyMessageWidget(
      message:widget.replymessage,
      onCancelreply:widget.onCancelReply
    ));
  }

}
class ChatRoom extends StatefulWidget{
  const ChatRoom({Key ? key}) : super(key:key);
  @override
  State<ChatRoom> createState() => _ChatRoomState();
}
class _ChatRoomState extends State<ChatRoom>{
  @override
  void initState(){
    getUserInfo();
    super.initState();
  }
  Future<String> getUserInfo() async{
    Constants.myName = (await HelperFunctions.getUsernameSharedPreference())!;
    print("HELOOOOOO"+Constants.myName);

    return Constants.myName;
  }
  AuthMethods authMethods = new AuthMethods();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Icon(
          Icons.mail
        ),
        backgroundColor: Colors.amber,
        elevation: 0.0,
        centerTitle: false,
        actions: [
          GestureDetector(
            onTap: () {
              authMethods.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Authenticate()));
            },
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.exit_to_app)),
          )
        ],
      ),
      body: Container(
        child: Center(
          child: FutureBuilder<String>(
            future: getUserInfo(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Center(child: CircularProgressIndicator(color: Colors.amber,));
                  default:
                    if (snapshot.hasError)
                      return Text('Error: ${snapshot.error}');
                    else
                      if (snapshot.data != null){
                        return Column(children:[
                          Spacer(),
                          Text("Hi, " + Constants.myName+"!", style: TextStyle(color: Colors.white, fontSize: 26)),
                          Spacer(),
                          ElevatedButton(child: Text("Message"),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.amber, // background
                             // foreground
                            ),
                            onPressed: (){

                            createChat(username: "Vasanthi");
                            FirebaseFirestore.instance.collection('allusers').where("name",isEqualTo: Constants.myName).get().then(
                            (qsnap){
                            qsnap.docs.forEach((element) {
                            FirebaseFirestore.instance.collection('allusers').doc(element.id).update({
                            'lastopenedbyclient': DateTime.now().millisecondsSinceEpoch,
                              'unreadmessages':0
                            });
                            });
                            }
    );}

                          ),
                          TextButton(onPressed:() {
                          authMethods.signOut();
                          Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => Authenticate()));
                          }, child: Text("Sign Out", style: TextStyle(color: Colors.white, fontSize: 16,decoration: TextDecoration.underline))),
                          Spacer(),
                        ]);
                      }
                    else{
                      return Center(child: CircularProgressIndicator(color: Colors.amber,));
                    }
                }})
        ),
      ),
      /*floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Search()));
        },
      ),*/
    );
  }
  String getChatRoomId(String a, String b) {
    print("in getchatroom $b");
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }
  void createChat({required String username}) {
    print(Constants.myName+"i am contsatnts");
    String chatRoomId = getChatRoomId(username, Constants.myName);
    List<String> users = [username, Constants.myName];
    print("I am chat room id $chatRoomId");
    Map<String, dynamic> chatRoomMap={
      "users":users,
      "chatRoomId":chatRoomId
    };
    DatabaseMethods().createChatRoom(chatRoomId, chatRoomMap);
    Navigator.push( context,MaterialPageRoute(
        builder: (context)=>Conversation(chatRoomId)
    ));
  }


}

class Messagetile extends StatelessWidget{
  final String message;
  final bool sendBy;
  final String type;
  final int time;
  final String replyingto;
  Future<QuerySnapshot> getImages() {
    return FirebaseFirestore.instance.collection("newsitems").get();
  }
  Messagetile(this.message, this.sendBy,this.type,this.time,this.replyingto);
  static final inputTopRadius = Radius.circular(12);
  static final inputBottomRadius = Radius.circular(24);
  bool checkcurve = false;
  Widget buildReply() {
    checkcurve = true;
    print(message + "I am in messagetile");
    print(replyingto + "I am in messagetile");
    return GestureDetector(
        onTap: (){print("Tappeddd");},
        child:Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: sendBy?Colors.amber.withOpacity(0.2):Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.only(
            topLeft: inputTopRadius,
            topRight: inputTopRadius,
          ),
        ),
        child:ReplyMessageWidget2(
            message:replyingto,
            //onCancelreply:null
        )));
  }
  @override
  Widget build(BuildContext context){
    print(message+"im in build");
    print(replyingto+"im in build");
    return

      SingleChildScrollView
      (child:

    UnconstrainedBox(child:
      Container(
     //width: MediaQuery.of(context).size.width,
      //constraints: BoxConstraints(
        //  maxWidth: MediaQuery.of(context).size.width*0.7
      //),
      margin:  EdgeInsets.symmetric(vertical:5),
       padding: EdgeInsets.only(
            //top: 5,
            //bottom: 5,
            left: sendBy ? 0 : 24,
            right: sendBy ? 24 : 0),
      alignment: sendBy?Alignment.centerRight:Alignment.centerLeft,
      child:
      //Column(
          Flexible(child:
            Container(
              //constraints: BoxConstraints(
              //  maxWidth: MediaQuery.of(context).size.width*0.7
              //),
                child:Column(
                    children:[
                      this.replyingto!=""?buildReply():Container(),
                      Container(

                        alignment: sendBy?Alignment.bottomRight:Alignment.bottomLeft,
                        padding: EdgeInsets.symmetric(horizontal:10,vertical:8),
                        decoration: BoxDecoration(
                          borderRadius: sendBy ? BorderRadius.only(
                              topLeft: checkcurve?Radius.circular(0):Radius.circular(23),
                              topRight: checkcurve?Radius.circular(0):Radius.circular(23),
                              bottomLeft: Radius.circular(23)
                          ) :
                          BorderRadius.only(
                              topLeft: checkcurve?Radius.circular(0):Radius.circular(23),
                              topRight: checkcurve?Radius.circular(0):Radius.circular(23),
                              bottomRight: Radius.circular(23)),
                          color: sendBy?Colors.amber[200]:Colors.white,
                        ),
                        child: type=="text"?Column(children: [Container(child:Text(message, style:TextStyle(
                            color:  sendBy?Colors.white:Colors.black,

                            fontSize:17
                        )),alignment:sendBy?Alignment.bottomRight:Alignment.bottomLeft,),Container(child:Text(DateFormat(' HH:mm, dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(time)).toString(), style:TextStyle(
                          color:  Colors.black26,
                          fontSize:8,
                        ),textAlign: TextAlign.right,),alignment: Alignment.bottomRight,)],):Container(child:Column(children: [Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                                children: [GestureDetector(
                                  child: Hero(
                                    tag: message,
                                    child: Image.network(
                                      //snapshot.data?.docs[index].data()!["url"],
                                        message,
                                        fit: BoxFit.fitWidth),
                                  ),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) {
                                      return DetailScreen(message);
                                    }));
                                  },
                                ),


                                ])
                        ),Text(DateFormat(' HH:mm, dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(time)).toString(), style:TextStyle(
                          color:  Colors.black26,
                          fontSize:8,
                        ),textAlign: TextAlign.right,)],)
                        ),
                      )]))
          ),
          //)
    )));
  }
}
class DetailScreen extends StatefulWidget{
  final String filename;
  DetailScreen(this.filename);
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}
class _DetailScreenState extends State<DetailScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title:Text("Chat"),backgroundColor: Colors.amber),
      body: Column(
        children: [Center(child:Expanded(child:Image.network(widget.filename,fit: BoxFit.contain,)))]

      ),
    );
  }

}
class SignIn extends StatefulWidget{
  final Function toggle;
  SignIn(this.toggle);
  @override
  State<SignIn> createState() => _SignInState();
}
class _SignInState extends State<SignIn>{
  AuthMethods authMethods = new AuthMethods();
  DatabaseMethods dbmets = new DatabaseMethods();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  TextEditingController emailEditingController = new TextEditingController();
  TextEditingController passwordEditingController = new TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  late QuerySnapshot qsnap;
  bool isloading = false;
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('onMessageOpenedApp data: ${message.data}');
    });
    FirebaseMessaging.instance.getInitialMessage().then(( message) {
      print('getInitialMessage data: ${message?.data}');

    });

    // onMessage: When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage data: ${message.data}");
    });
    firebaseMessaging.getToken().then((token) {
      saveTokens(token);

    });

  }
  Future<void> saveTokens(var token) async {
    try {
      var qtoken = await _firestore.collection('tokens').where("token", isEqualTo: token).get();
      //if (qtoken.docs.length == 0){
        await _firestore.collection('allusers').where("email",isEqualTo: emailEditingController.text).get().then(
            (qsnap){
              qsnap.docs.forEach((element) {
                _firestore.collection('allusers').doc(element.id).update({
                  'token': token,
                });
              });
            }
        );


      //}

    } catch (e) {
      print(e);
    }
  }
  signIn(){
    if (formKey.currentState!.validate()){

      //HelperFunctions.saveusernameSharedPreference(usernamecont.text);
      HelperFunctions.saveuseremailSharedPreference(emailEditingController.text);
      setState(() {
        isloading = true;
      });
      if (dbmets.getUserByEmail(emailEditingController.text)==null){
        print("wrongggg");
        emailEditingController.clear();
        passwordEditingController.clear();
        final snackBar = SnackBar(
          content: const Text('Yay! A SnackBar!'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );

        // Find the ScaffoldMessenger in the widget tree
        // and use it to show a SnackBar.
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }else{
        print("idk why");
        dbmets.getUserByEmail(emailEditingController.text).then((val){
          qsnap = val;
          HelperFunctions.saveusernameSharedPreference(qsnap.docs[0].get("name"));
        });

        authMethods.signInWithEmailAndPassword(emailEditingController.text, passwordEditingController.text).then((value) {
          if (value!=null){
            HelperFunctions.saveuserLoggedInSharedPreference(true);
            firebaseMessaging.getToken().then((token) {
              saveTokens(token);
              print("TOKEN SAVEDD");

            });

            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatRoom()

            ));
          }
          else{
            print("No user");
            emailEditingController.clear();
            passwordEditingController.clear();
            final snackBar = SnackBar(
              content: const Text('Username or Password does not exist'),
              action: SnackBarAction(
                label: 'Okay',
                onPressed: () {
                  // Some code to undo the change.
                },
              ),
            );

            // Find the ScaffoldMessenger in the widget tree
            // and use it to show a SnackBar.
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }

        );
      }


    }
  }
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: Text(
            "Sign In",

          ),
      backgroundColor: Colors.amber,),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Spacer(),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    style: TextStyle(color: Colors.white),

                    validator: (val) {
                      return RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(val!)
                          ? null
                          : "Please Enter Correct Email";
                    },
                    controller: emailEditingController,
                    //style: simpleTextStyle(),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                          color: Colors.white
                      ),enabledBorder: new UnderlineInputBorder(
                        borderSide: new BorderSide(color: Colors.white)
                    ),
                    ),
                  ),
                  TextFormField(
                    style: TextStyle(color: Colors.white),

                    obscureText: true,
                    validator: (val) {
                      return val!.length > 6
                          ? null
                          : "Enter Password 6+ characters";
                    },
                    //style: simpleTextStyle(),
                    controller: passwordEditingController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(
                          color: Colors.white
                      ),enabledBorder: new UnderlineInputBorder(
                        borderSide: new BorderSide(color: Colors.white)
                    ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 16,
            ),
            /*Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPassword()));
                  },
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      )),
                )
              ],
            ),*/
            SizedBox(
              height: 16,
            ),
            GestureDetector(
              onTap: () {
                  signIn();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.amber),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Sign In",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center,

                ),
              ),
            ),
           /* SizedBox(
              height: 16,
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white),
              width: MediaQuery.of(context).size.width,
              child: Text(
                "Sign In with Google",
                style:
                TextStyle(fontSize: 17, color: Colors.amber),
                textAlign: TextAlign.center,
              ),
            ),*/
            SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have account? ",
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    widget.toggle();
                  },
                  child: Text(
                    "Register now",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 50,
            )
          ],
        ),
      ),
    );
  }
  
}
class Authenticate extends StatefulWidget{
  const Authenticate({Key ? key}) : super(key:key);
  @override
  State<Authenticate> createState() => _AuthenticateState();
}
class _AuthenticateState extends State<Authenticate>{
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  bool showsignin = true;
  void toggleView(){
    setState(() {
      showsignin = !showsignin;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (showsignin){
      return SignIn(toggleView);
    }else{
      return SignUp(toggleView);
    };
  }

}
class SignUp extends StatefulWidget{
  final Function toggle;
  SignUp(this.toggle);
  @override
  State<SignUp> createState() => _SignUpState();
}
class _SignUpState extends State<SignUp>{
  bool isloading =false;
  DatabaseMethods dbmets = new DatabaseMethods();
  AuthMethods authMethods = new AuthMethods();
  HelperFunctions helper = new HelperFunctions();
  final _firestore = FirebaseFirestore.instance;

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final formKey = GlobalKey<FormState>();
  TextEditingController usernamecont = new TextEditingController();
  TextEditingController emailcont = new TextEditingController();
  TextEditingController pwcont = new TextEditingController();
  signmeup(){
    if (formKey.currentState!.validate()){
      Map<String, dynamic> userinfomap={
        "name":usernamecont.text,
        "email":emailcont.text,
        "lastopenedbyowner":0,
        'token': "eM9x5rPaQOewe7fbRtUczB:APA91bF9CN_xPs",
        'ownertoken':"eM9x5rPaQOewe7fbRtUczB:APA91bF9CN_xPs",
        'totoken':"eM9x5rPaQOewe7fbRtUczB:APA91bF9CN_xPs",
        'lastmessage': '',
        "time":0,
        'lastopenedbyowner':0,
        'lastopenedbyclient':0,
        'lastmessageauthor':"",
        'unreadmessages':0
      };
      dbmets.getUserByUsername(usernamecont.text).then((val){
        if (val.docs.length>0){

          print(val);
          final snackBar =
          SnackBar(content: Text('User name exists'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          usernamecont.clear();

        }
        else{
          dbmets.getUserByEmail(emailcont.text).then((val){
            if (val.docs.length>0){
              print("EXISTSSS");
              final snackBar =
              SnackBar(content: Text('User Email exists'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              emailcont.clear();
            }
            else{
              HelperFunctions.saveusernameSharedPreference(usernamecont.text);
              HelperFunctions.saveuseremailSharedPreference(emailcont.text);
              setState(() {
                isloading=true;
              });

              authMethods.signUpWithEmailAndPassword(emailcont.text, pwcont.text).then((val){
                print("$val");
                dbmets.uploadUserInfo(userinfomap);
                HelperFunctions.saveuserLoggedInSharedPreference(true);
                firebaseMessaging.getToken().then((token) {
                  saveTokens(token);
                  print("TOKEN SAVEDD");

                });
                Navigator.pushReplacement(context, MaterialPageRoute(
                    builder:(context)=>ChatRoom()
                ));
              });
            }
          });
        }
      });

    }


  }
  Future<void> saveTokens(var token) async {
    try {
      var owntoken = "";
      print("in savetokenssss");
      //if (qtoken.docs.length == 0){
      await FirebaseFirestore.instance.collection('ownerdeets').get().then(
              (qsnap){
                //setState(() {
                  owntoken = qsnap.docs[0].get("ownertoken");
                //});
                  print("saved own token"+owntoken);

              });

      await _firestore.collection('allusers').where("email",isEqualTo: emailcont.text).get().then(
              (qsnap){
            qsnap.docs.forEach((element) {
              //totoken - token of target, in this case, white app owner
              //fromtoken - token of source, in this case, blackapp owner
              //each time blackapp messages, allusers to token should be updated to white app token (ownertoken)
              //each time white app message, allusers totoken should be updated to blackapp token (token)
              _firestore.collection('allusers').doc(element.id).update({
                'token': token,
                'ownertoken':owntoken,
                'totoken':token,


              });
            });
          }
      );
      print("saved token"+token);


      //}

    } catch (e) {
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Sign Up!"),
        backgroundColor: Colors.amber,
      ),
      body: isloading ? Container(child: Center(child: CircularProgressIndicator(),),) :  Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Spacer(),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    style: TextStyle(color: Colors.white),

                    //style: simpleTextStyle(),
                    controller: usernamecont,
                    validator: (val){
                      return val!.isEmpty || val!.length < 3 ? "Enter Username 3+ characters" : null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: TextStyle(
                          color: Colors.white
                      ),
                      enabledBorder: new UnderlineInputBorder(
                          borderSide: new BorderSide(color: Colors.white)
                      ),
                    ),
                  ),
                  TextFormField(
                    style: TextStyle(color: Colors.white),

                    cursorColor: Colors.white,
                    //style: simpleTextStyle(),
                    controller: pwcont,
                    validator: (val){
                      return val!.isEmpty || val!.length < 3 ? "Enter Password 3+ characters" : null;
                    },
                    decoration: InputDecoration(
                      enabledBorder: new UnderlineInputBorder(
                          borderSide: new BorderSide(color: Colors.white)
                      ),
                      hintText: 'Password',
                      hintStyle: TextStyle(
                          color: Colors.white
                      ),

                    ),
                  ),
                  TextFormField(
                    style: TextStyle(color: Colors.white),
                    controller: emailcont,

                    validator: (val){
                      return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val!) ?
                      null : "Enter correct email";
                    },
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                          color: Colors.white
                      ),enabledBorder: new UnderlineInputBorder(
                        borderSide: new BorderSide(color: Colors.white)
                    ),
                    ),
                  ),

                ],
              ),
            ),
            SizedBox(
              height: 16,
            ),
            GestureDetector(
              onTap: (){
                signmeup();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.amber),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Sign Up",

                  textAlign: TextAlign.center,
                ),
              ),
            ),
            /*SizedBox(
              height: 16,
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), color: Colors.white),
              width: MediaQuery.of(context).size.width,
              child: Text(
                "Sign Up with Google",
                style: TextStyle(fontSize: 17, color: Colors.amber),
                textAlign: TextAlign.center,
              ),
            ),*/
            SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    widget.toggle();
                  },
                  child: Text(
                    "SignIn now",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 50,
            )
          ],
        ),
      ),
    );
    ;
  }

}
class Animalcard {
  final String name;
  final String url;
  final String desc;
  final String type;
  final String colour;

  const Animalcard({required this.desc, required this.type, required this.colour, required this.name, required this.url,});
}
class Contactcard {
  final String name;
  final String number;

  const Contactcard({required this.name, required this.number});
}


