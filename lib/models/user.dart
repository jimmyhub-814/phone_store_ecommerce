import 'package:flutter/material.dart';

class UserApp extends ChangeNotifier {
  static const idField = 'id';
  static const userEmailField = 'userEmail';
  static const userAvatarField = 'userAvatar';
  static const userNameField = 'userName';
  static const userGenderField = 'userGender';
  static const userDateField = 'userDate';
  static const userPhoneField = 'userPhone';
  static const userDeviceTokensField = 'userDeviceTokens';
  static const isCompletedField = 'isCompleted';

  String id;
  String userEmail;
  String userAvatar;
  String userName;
  String userGender;
  String userDate;
  String userPhone;
  List<String> userDeviceTokens;
  bool isCompleted;

  UserApp({
    required this.id,
    required this.userAvatar,
    required this.userEmail,
    required this.userName,
    required this.userGender,
    required this.userDate,
    required this.userDeviceTokens,
    required this.userPhone,
    required this.isCompleted,
  });
  Map<String, dynamic> toMap() {
    return {
      idField: id,
      userEmailField: userEmail,
      userAvatarField: userAvatar,
      userNameField: userName,
      userGenderField: userGender,
      userDateField: userDate,
      userDeviceTokensField: userDeviceTokens,
      userPhoneField: userPhone,
      isCompletedField: isCompleted,
    };
  }

  factory UserApp.fromMap(Map<String, dynamic> map) {
    return UserApp(
        id: map[idField] as String,
        userEmail: map[userEmailField] as String,
        userAvatar: map[userAvatarField] as String,
        userName: map[userNameField] as String,
        userGender: map[userGenderField] as String,
        userDate: map[userDateField] as String,
        userPhone: map[userPhoneField] as String,
        userDeviceTokens: (map[userDeviceTokensField] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isCompleted: map[isCompletedField] as bool);
  }
}
