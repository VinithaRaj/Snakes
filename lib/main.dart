// @dart = 2.15
import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:async/async.dart';
import 'package:flat_icons_flutter/flat_icons_flutter.dart';
import 'package:bordered_text/bordered_text.dart';
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
import 'model/carousel_file.dart';
import 'model/collections_file.dart';
Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
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
      title: 'Flutter Demo',
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

    );
  }
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
  Future<String> _imgurl() async{
    var url = await ref.getDownloadURL();
    return url;
  }

  late List<AssetImage> listOfImages;
  bool clicked = false;
  List<String?> listOfStr = [];
  String? images;
  bool isLoading = false;
  int _currentIndex=0;
  int _selectedIndex = 0;
  late Future<List<FirebaseFile>> futureFiles;
  final FirebaseFirestore fb = FirebaseFirestore.instance;
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
      /*FirebaseMessaging.instance.getInitialMessage().then(( message) {
        print('getInitialMessage data: ${message?.data}');

      });

      // onMessage: When the app is open and it receives a push notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("onMessage data: ${message.data}");
      });

    });*/
  }
  Future<void> saveTokens(var token) async {
    try {
      var qtoken = await _firestore.collection('tokens').where("token", isEqualTo: token).get();
      if (qtoken.docs.length == 0){
        await _firestore.collection('tokens').add({
          'token': token,
        });
      }

    } catch (e) {
      print(e);
    }
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  final List _children = [
    MyHomePage(title: "Home Page"),
    CollectionsPage(),
    Aboutuspage(),
    Contactuspage()
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    key: key2,
  backgroundColor: Colors.black,
  body:_children[_selectedIndex],
    bottomNavigationBar: BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
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
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.amber,
      onTap: _onItemTapped,
    ),

  );

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


  }


  Future<List<CollectionsFile>> getCollectionList() async {
    List<int> idList = [];
    var qa = await FirebaseFirestore.instance.collection("newfiles").limit(3).get();
    List<CollectionsFile> collectionsList = [];
    print("okayyyyy");
    qa.docs.forEach((element) {

      print(element.get("visibleName"));
      //print((element as Map)["url"]);
      print("nope");
      var prod = CollectionsFile(
        url: element.get("url"),
        visibleName: element.get("visibleName"), type: element.get("type")
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
    Future<QuerySnapshot> qa = fb.collection("newsitems").get();
    //return fb2.collection("newfiles").get();
    //return qa;
    return qa;
  //});
  }


  void getImages(){
    listOfImages = [];
    listOfImages.add(AssetImage('snake.png'));
  }


  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
      body: //FutureBuilder<List<FirebaseFile>>(
      /*FutureBuilder(
        future: //futureFiles,
        getCarouselItems(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
          switch (snapshot.connectionState){
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError){
                return Center(child: Text("eroorrr"));
              } else {
                final files = snapshot.data!;
                return*/
                  ListView(children: [Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //buildHeader(0),



                    /*Container(
                        padding:EdgeInsets.all(10.0),
                        child:
                            Row(children:<Widget>[
                              Text(
                                  "News",
                                  style: 
                                  //GoogleFonts.teko(textStyle: 
                                    TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                                  //)
                              ),
                              Icon(Icons.local_fire_department_outlined, size: 20,color: Colors.amber),



                            ],)

                      ),*/

                   Container(child:FutureBuilder<List<CarouselFile>>(
                        future: futureCars,
                        builder: (context, snapshot){
                          switch (snapshot.connectionState){
                            case ConnectionState.waiting:
                              return Center(child: CircularProgressIndicator());
                            default:
                              if (snapshot.hasError){
                                print("Errorrrr");
                                return Center(child: Text("eroorrr"));
                              } else {
                                print("Goodddd");
                                final files = snapshot.data!;
                                // final files = snapshot.data?.asMa;
                                return CarouselSlider.builder(
                                    itemCount: files.length,
                                    itemBuilder: ( context,  index) {
                                      final file = files[index];
                                      //var a =snapshot.data?.docs[index].data() ?? {"newsTitle":"hi","url":"none","newsBig":"none","newsSmall":"none"};
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
                                )
                                ;
                              }}}
                    )),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Card(
                            color: Colors.black,
                            shadowColor: Colors.amber,
                            child: /*Padding(
                                padding: EdgeInsets.all(3.0),*/
                            Expanded(
                                child:Column(
                                  children: [
                                    Icon(Icons.accessibility_new_rounded, color: Colors.white),
                                    TextButton(
                                      child: const Text('ABOUT US'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => Aboutuspage()),
                                        );
                                      },

                                    ),

                                  ],))
                        ),


                        Card(
                            color: Colors.black,
                            shadowColor: Colors.amber,
                            child: /*Padding(
                                padding: EdgeInsets.all(3.0),*/
                            Expanded(
                                child:Column(
                                  children: [
                                    Icon(MyFlutterApp.snake, color: Colors.white,),
                                    TextButton(
                                      child: const Text('COLLECTIONS'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => CollectionsPage()),
                                        );
                                      },

                                    ),

                                  ],))
                        ),
                        Card(
                            color: Colors.black,
                            shadowColor: Colors.amber,
                            child:
                            Expanded(
                            /*Padding(
                                padding: EdgeInsets.all(3.0),*/
                                child:Column(
                                  children: [
                                    Icon(Icons.call_rounded, color: Colors.white),
                                    TextButton(
                                      child: const Text('CONTACT US'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => Contactuspage()),
                                        );
                                      },

                                    ),

                                  ],))
                        ),
                      ],
                    ),

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
                            MaterialPageRoute(builder: (context) => CollectionsPage()),
                          );  }, child: Text("More"))


                        ],)

                    ),
                          Container(child:FutureBuilder<List<CollectionsFile>>(
                            future: futureCol,
                            builder: (context,  snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                final files = snapshot.data!;
                                print("hereee");
                                return ListView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: files.length,
                                    itemBuilder: ( context,  index) {
                                      final file =files[index];
                                      return
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(vertical: 20,horizontal: 20),
                                          leading: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: 44,
                                                minHeight: 44,
                                                maxWidth: 64,
                                                maxHeight: 64,
                                              ),
                                              child: Image.network(file.url)),

                                          title: Text(ReCase(file.visibleName).titleCase,style: GoogleFonts.teko(
                                            textStyle: TextStyle(fontSize: 20,color: Colors.white, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                                          )),
                                          subtitle: Text(file.type,style: GoogleFonts.teko(
                                            textStyle: TextStyle(fontSize: 14,color: Colors.white, letterSpacing: 1.0),
                                          )),
                                          trailing: TextButton(
                                            child: Text('View'),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => IndividualPage(fileurl: file.url,collname: "newfiles")),
                                              );
                                            },
                                          )

                                        )
                                      ;

                                    });
                              } else if (snapshot.connectionState == ConnectionState.none) {
                                return Text("No data");
                              }
                              return Text("");
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
                    return Center(child: CircularProgressIndicator());
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
                              'ims/sneklogo.png',

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
            accountName: Text("Yuvanesh Jeyaraman"),
            accountEmail: Text("YuvaneshJeyaraman@gmail.com"),
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
              MaterialPageRoute(builder: (context) => CollectionsPage()),
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
    );

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
                accountName: Text("Yuvanesh Jeyaraman"),
                accountEmail: Text("YuvaneshJeyaraman@gmail.com"),
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
                  MaterialPageRoute(builder: (context) => CollectionsPage()),
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
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  void _launchURL() async => await canLaunch(_url)
      ? await launch(_url) : throw 'Not found $_url';
  void _launchfbURL() async => await canLaunch(_fburl)
      ? await launch(_fburl) : throw 'Not found $_fburl';

  @override
  Widget build(BuildContext context) {
    return /*Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Contact Us'),
        backgroundColor: Colors.amber,
      ),*/
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
              Card(
                color: Colors.black,
                shadowColor: Colors.amber,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      /*leading: ClipOval(
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
              ),
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

        ),


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
              accountName: Text("Yuvanesh Jeyaraman"),
              accountEmail: Text("YuvaneshJeyaraman@gmail.com"),
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
                MaterialPageRoute(builder: (context) => CollectionsPage()),
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
            return CircularProgressIndicator();
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
    if (name=='Pythons'){
      setState(()=>name='newfiles');
    }
    Future<QuerySnapshot> qa = fb2.collection(name).get();
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
                              fit: BoxFit.fill),
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
                                    MaterialPageRoute(builder: (context) => IndividualPage(fileurl:snakecards![index].url,collname: (widget.dbtabname!='Pythons')?widget.dbtabname:'newfiles')),
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
    Future<QuerySnapshot> qa = fb2.collection(widget.dbtabname).get();
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
                                fit: BoxFit.fill),
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
                                      MaterialPageRoute(builder: (context) => IndividualPage(fileurl:snakecards![index].url,collname: (widget.dbtabname!='Pythons')?widget.dbtabname:'newfiles')),
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
  static const String _url = 'whatsapp://send?phone=60133635145&text=hello';
  void _launchURL(String func) async => await canLaunch(_url)
      ? await launch('whatsapp://send?phone=60133635145&text= ${func} On Product Name: ${ReCase(name).titleCase}') : throw 'Not found $_url';


  static const _actionTitles = ['Enquire on Product', 'Place Order'];

  Future<QuerySnapshot> getImages() {
    //return fb.collection("newfiles").where("url", isEqualTo:widget.fileurl).get();
    return fb.collection(widget.collname).where("url", isEqualTo:widget.fileurl).get();
  }
  final FirebaseFirestore fb = FirebaseFirestore.instance;
  TextEditingController _textFieldController = TextEditingController();
  String valueText = "No desc";
  String name = "Name";
  void _showAction(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text("Product Name: "+ReCase(name).titleCase),
          actions: [
            TextButton(
              onPressed:()=> _launchURL(_actionTitles[index]),
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
            return CircularProgressIndicator();
          },

        ),

      ),
      floatingActionButton: ExpandableFab(
        distance: 112.0,
        children: [
          ActionButton(
            onPressed: () => _showAction(context, 0),
            icon: const Icon(Icons.question_answer,),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          ActionButton(

            onPressed: () => _showAction(context, 1),
            icon: const Icon(Icons.shopping_cart,
            ),


          ),

        ],
      ),

    );

  }

}
class CollectionsPage extends StatefulWidget{
  const CollectionsPage({Key ? key}) : super(key:key);
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<QuerySnapshot> getImages2(searchtext) {
    Future<QuerySnapshot> qa = fb2.collection("newfiles").where("visibleName",isGreaterThanOrEqualTo: searchtext).where("visibleName",isLessThanOrEqualTo: searchtext+ '\uf8ff').get();
    //return fb2.collection("newfiles").get();
    return qa;
  }
  Future<QuerySnapshot> getImages2dup(searchtext) {
    Future<QuerySnapshot> qa = fb2.collection("newfiles").get();
    //return fb2.collection("newfiles").get();
    return qa;
  }
  Future<QuerySnapshot> getImages3(tabname,searchtext) {
    Future<QuerySnapshot> qa = fb2.collection(tabname).where("visibleName",isGreaterThanOrEqualTo: searchtext).where("visibleName",isLessThanOrEqualTo: searchtext+ '\uf8ff').get();
    //return fb2.collection("newfiles").get();
    return qa;
    return fb2.collection(tabname).get();
  }
  Future<QuerySnapshot> getImages3dup(tabname,searchtext) {
    Future<QuerySnapshot> qa = fb2.collection(tabname).get();
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
              TabPage(dbtabname: "Turtles", searchname: _searchText),
              TabPage(dbtabname: "Feeders", searchname: _searchText),
              TabPage(dbtabname: "Other Animals", searchname: _searchText),
              Container(//Other Animals
                padding: EdgeInsets.all(10.0),
                child: FutureBuilder(
                  future: getImages3("Accessories",_searchText),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data?.docs.length,
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
                                    title: Text("Name: "+ReCase((a as Map)["visibleName"]).titleCase,style: TextStyle(color: Colors.amber,fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      "Type: "+(a as Map)["type"],
                                      style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                    ),
                                    //trailing: Icon(Icons.favorite_outline),
                                  ),
                                  Container(
                                    height: 200.0,
                                    child: Image.network(
                                      //snapshot.data?.docs[index].data()!["url"],
                                        (a as Map)["url"],
                                        fit: BoxFit.fill),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(16.0),
                                    alignment: Alignment.centerLeft,
                                    child: Text("Description: "+(a as Map)["desc"]),
                                  ),

                                  Stack(children: <Widget>[ListTile(

                                    title: Text("Price",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    subtitle: Text((a as Map)["colour"],style: TextStyle(color: Colors.white)),
                                    tileColor: Colors.amber,
                                  ),
                                    Positioned(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => IndividualPage(fileurl:(a as Map)["url"],collname: "Accessories")),
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

              ),
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
              accountName: Text("Yuvanesh Jeyaraman"),
              accountEmail: Text("YuvaneshJeyaraman@gmail.com"),
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
    );

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


