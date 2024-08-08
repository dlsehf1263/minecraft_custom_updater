import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:mc/dialog_utils.dart';
import 'package:mc/ui_utils.dart';

part 'data_file.dart';

// 프로그램
String get builtinDataPath => 'assets';
String get downloadPath => 'download';
String get currentDirectory => Platform.resolvedExecutable;

// 유틸
String get mcLauncherPath => 'C:/Program Files (x86)/Minecraft Launcher/MinecraftLauncher.exe';
String get javaPath => 'C:/Program Files/Common Files/Oracle/Java/javapath/java.exe';

// 마크
String get appDataPath => Platform.environment['APPDATA']!.replaceAll('\\', '/');
String get minecraftPath => '$appDataPath/.minecraft';

// 업데이트
typedef FileList = Map<String, List>; // Map<String, List<List>>로 하면 jsonDecode().cast<~>() 이후 사용하면 오류 발생

class UpdateInfo {
  FileList list = {};
  List<String> needUpdate = [];
  List<String>? needRemove = [];

  bool get isLatest => needUpdate.isEmpty && needRemove != null && needRemove!.isEmpty;
}

File get downloadHistoryFile => File('$minecraftPath/ming_history');
set downloadHistory(FileList? history) => downloadHistoryFile.writeAsStringSync(jsonEncode(history));
FileList? get downloadHistory {
  if (downloadHistoryFile.existsSync()) {
    return jsonDecode(downloadHistoryFile.readAsStringSync()).cast<String, List>();
  }

  return null;
}
