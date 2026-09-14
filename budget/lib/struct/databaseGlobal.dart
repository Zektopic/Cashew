import 'package:budget/database/tables.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

late String clientID;
late FinanceDatabase database;
late SharedPreferences sharedPreferences;
late FlutterSecureStorage secureStorage;
final uuid = Uuid();
