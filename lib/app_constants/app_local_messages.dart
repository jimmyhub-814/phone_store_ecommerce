import 'package:phone_store/app_constants/auth_helper.dart';

class AppLocalMessages {
  const AppLocalMessages._();

  static String get localMessages => 'messages_${AuthHelper.userId}';
}
