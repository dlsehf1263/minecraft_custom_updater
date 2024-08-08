part of 'data.dart';

//////// 일반

bool copyFiles(Iterable<String> paths, String dest, {String Function(String srcPath)? getAdditionalDstPath}) {
  try {
    for (final srcPath in paths) {
      String dstPath = '';

      if (getAdditionalDstPath == null) {
        dstPath = '$dest/${p.basename(srcPath)}';
      } else {
        dstPath = '$dest/${getAdditionalDstPath(srcPath)}';
      }

      Directory(p.dirname(dstPath)).createSync();

      File(srcPath).copySync(dstPath);
    }
  } catch (e) {
    openMessageDialog('오류', '$e');
    return false;
  }

  return true;
}

bool hasFile(String path) {
  return File(path).existsSync();
}

Future<bool> execute(String path, [List<String> argvs = const []]) async {
  showSnackBar('파일을 실행합니다.');

  try {
    Process process = await Process.start(path, argvs);
    return true;
  } catch (e) {
    openMessageDialog('오류', '$e');
    return false;
  }
}

Future<void> createJavaExecuterBatch(String path, String jarPath) async {
  File file = File(path);

  final stream = file.openWrite();
  stream.write('"$javaPath" -jar $jarPath');
  await stream.close();
}

// 이걸로는 포지가 제대로 실행되지 않음.
Future<bool> executeJavaFile(String path) async {
  // execute('java', ['-jar', path]);

  createJavaExecuterBatch('_.bat', path);

  return execute('_.bat');
}

//////// 다운로드

const String gitRoot = 'https://github.com/dlsehf1263/minecraft/raw/main';
// blob은 업로드 즉시 갱신되지만 raw는 시간이 좀 걸리는 모양이다.

const String gitUpdateFileListFileName = 'filelist.json';
const String gitUpdateFilesDirName = 'files';

Future<bool> downloadFileIfNotExist(String file, String url) async {
  if (isDownloaded(file)) return true;
  return downloadFiles([url], saveAs: file);
}

bool isDownloaded(String name) {
  return File('$downloadPath/$name').existsSync();
}

Future<bool> downloadFiles(List<String> urls, {void Function(double)? onProgress, String? saveAs}) async {
  final dio = Dio();

  dio.options.headers.addAll({
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
    'Cache-Control': 'no-cache',
  });

  showSnackBar('다운로드를 시작합니다.');

  try {
    int downloaded = 0;

    for (final url in urls) {
      await dio.download(
        '$gitRoot/$url',
        '$downloadPath/${saveAs ?? url}',
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress((downloaded / urls.length + (received / total / urls.length)));
          }
        },
      );

      downloaded++;
    }

    if (onProgress != null) onProgress(1);
  } catch (e) {
    openMessageDialog('오류', '파일 다운로드 오류\n\n$e');
    return false;
  }

  return true;
}

void deleteDownloadCahces() {
  showSnackBar('다운로드 캐시를 제거합니다.');

  final dir = Directory(downloadPath);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}

Future<String?> getDataFromUrl(String url) async {
  try {
    Response response = await Dio().get(
      '$gitRoot/$url',
      options: Options(
        headers: {'Cache-Control': 'no-cache'},
      ),
    );
    return response.data;
  } catch (e) {
    openMessageDialog('오류', '데이터 가져오기에 실패했습니다.\n\n$e');
    return null;
  }
}

//////// 마크

Future<void> copyBasicIfNeed() async {
  // 마크 루트 폴더가 없으면 기본 파일 복사
  final mcRoot = File('$minecraftPath/launcher_profiles.json');

  if (!mcRoot.existsSync()) {
    mcRoot.createSync(recursive: true);

    copyFiles(
      ['launcher_profiles.json', 'options.txt']
          .map((e) => '${kReleaseMode ? 'data/flutter_assets/' : ''}$builtinDataPath/$e'),
      minecraftPath,
    );
  }
}

void processForgeInstaller(String forgePath) {
  final dir = Directory('forgeinstaller');
  dir.createSync();

  copyFiles(
    [forgePath],
    dir.path,
  );
  createJavaExecuterBatch('${dir.path}/${p.basenameWithoutExtension(forgePath)}.bat', p.basename(forgePath));

  execute('explorer', [dir.path]);
}

int? getFileSizeInMCRoot(String path) {
  final f = File('$minecraftPath/$path');
  if (f.existsSync()) return f.lengthSync();
  return null;
}

//////// 업데이트

void _iterateFileList(FileList fl, void Function(String path, String name, int len) onFile) {
  for (final dir in fl.keys) {
    final fileDatas = fl[dir]!.cast();

    for (final data in fileDatas) {
      final name = data[0];
      final len = data[1];

      final path = dir.isEmpty ? name : '$dir/$name';

      onFile(path, name, len);
    }
  }
}

UpdateInfo getUpdatableFiles(FileList fl) {
  final info = UpdateInfo();

  // 기존에 업데이트한 파일 목록
  FileList? old = downloadHistory;

  // 새로 받아온 목록
  Set<String> newItems = {};

  // 다운로드 해야할 파일 찾기
  _iterateFileList(
    fl,
    (path, name, len) {
      newItems.add(path);

      // 첫 패치 || 파일이 없거나 size가 다름
      final isFirstAndMod = old == null && p.dirname(path) == 'mods';

      if (isFirstAndMod || getFileSizeInMCRoot(path) != len) {
        info.needUpdate.add(path);
      }
    },
  );

  // 제거할 항목 찾기: 기존 업데이트 목록에 있으나 새 업데이트 목록에 없는 항목
  // 파일 크기가 다른 경우는 덮어쓰기하므로 고려하지 않아도 됨.
  if (old == null) {
    info.needRemove = null;
  } else {
    _iterateFileList(
      old,
      (path, name, len) {
        if (!newItems.contains(path)) {
          info.needRemove!.add(path);
        }
      },
    );
  }

  return info;
}

Future<bool> tryApplyFiles(BuildContext context, UpdateInfo info) async {
  /// 파일 제거

  // 첫 업데이트임
  if (info.needRemove == null) {
    final dir = Directory('$minecraftPath/mods');

    if (dir.existsSync()) {
      await openMessageDialog('알림',
          '현 업데이트가 첫 업데이트로 확인되었습니다.\n서버와 동일한 환경 구성을 위해 설치된 모드를 삭제하고 설치를 진행합니다.\n\n확인 버튼을 누르면 계속합니다.\n백업이 필요한 경우 백업 후 확인 버튼을 누르세요.');

      dir.deleteSync(recursive: true);
    }
  }
  // 제거할 항목 있음
  else if (info.needRemove!.isNotEmpty) {
    for (final path in info.needRemove!) {
      final file = File('$minecraftPath/$path');

      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  /// 파일 복사

  if (copyFiles(
    info.needUpdate.map((e) => '$downloadPath/$gitUpdateFilesDirName/$e'),
    minecraftPath,
    getAdditionalDstPath: (srcPath) {
      final dirName = p.dirname(srcPath);
      final path = '$dirName/${p.basename(srcPath)}';

      // $downloadPath/$gitUpdateFilesDirName/$e 감안.
      return path.substring(path.indexOf('/', path.indexOf('/') + 1) + 1);
    },
  )) {
    downloadHistory = info.list;
    return true;
  }

  return false;
}
