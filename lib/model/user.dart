import 'package:meta/meta.dart';
import '../utils.dart';

class UserField{
  static final String lastMessageTime = 'lastmessagetime';
}

class User2{
  final String? idUser;
  //final String? name;
  //final String? urlAvatar;
  //final DateTime? lastMessageTime;

  const User2({
     this.idUser,
    //required this.name,
    //required this.urlAvatar,
    //required this.lastMessageTime,
  });
  User2 copyWith({
     String? idUser,
     //String? name,
     //String? urlAvatar,
     //DateTime? lastMessageTime,
  }) =>  User2(
    idUser: idUser??this.idUser,
    //name: name?? this.name,
    //urlAvatar: urlAvatar?? this.urlAvatar,
    //lastMessageTime: lastMessageTime?? this.lastMessageTime,

  );
  static User2 fromJson(Map<String, dynamic> json) =>
     User2(
        idUser: json['idUser'],
        //name: json['name'],
        //urlAvatar: json['urlAvatar'],
        //lastMessageTime: Utils.toDateTime(json['lastMessageTime'])
    );



  Map<String, dynamic> toJson()=>{
    'idUser':idUser,
    //'name':name,
    //'urlAvatar':urlAvatar,
    //'lastMessageTime':lastMessageTime
  };

}
