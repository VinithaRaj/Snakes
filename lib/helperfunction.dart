import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions{
  static String sharedPreferenceUserLoggedIn = "ISLOGGEDIN";
  static String sharedPreferenceUserNameKey = "USERNAMEKEY";
  static String sharedPreferenceUserEmailKey = "USEREMAILKEY";

  static Future<bool> saveuserLoggedInSharedPreference(bool isUserLogged) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(sharedPreferenceUserLoggedIn, isUserLogged);
  }
  static Future<bool> saveusernameSharedPreference(String username) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(sharedPreferenceUserNameKey, username);
  }
  static Future<bool> saveuseremailSharedPreference(String email) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(sharedPreferenceUserEmailKey, email);
  }

  static Future<bool?> getUserLoggedSharedPreference() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(sharedPreferenceUserLoggedIn);
  }

  static Future<String?> getUsernameSharedPreference() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(sharedPreferenceUserNameKey);
  }

  static Future<String?> getUseremailSharedPreference() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(sharedPreferenceUserEmailKey);
  }
}