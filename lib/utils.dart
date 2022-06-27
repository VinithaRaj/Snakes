import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'model/user.dart';

class Utils {
  static StreamTransformer transformer<T>(
      T Function(Map<String, dynamic> json) fromJson) =>
      //StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<User>> fromJson) =>
      StreamTransformer<QuerySnapshot, List<T>>.fromHandlers(
        handleData: (QuerySnapshot data, EventSink<List<T>> sink) {
          final snaps = data.docs.map((doc) => doc.data()).toList();
          final users = snaps.map((json) => fromJson(json as Map<String, dynamic>)).toList();

          sink.add(users);
        },
      );

  static DateTime? toDateTime(Timestamp value) {
    if (value == null) {
      return null;
    }

    return value.toDate();
  }

  static dynamic fromDateTimeToJson(DateTime date) {
    if (date == null) return null;

    return date.toUtc();
  }
}