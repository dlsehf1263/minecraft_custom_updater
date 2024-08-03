import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mc/data.dart';
import 'package:mc/dialog_utils.dart';
import 'package:mc/ui_utils.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isDataLoaded = false;

  late UpdateInfo _info;

  @override
  void initState() {
    super.initState();

    _loadData(ss: true);
  }

  _loadData({bool ss = true}) async {
    _isDataLoaded = false;
    if (ss) setState(() {});

    copyBasicIfNeed();

    final str = await getDataFromUrl(gitUpdateFileListFileName);
    if (str == null) {
      ;
    } else {
      final filelist = (jsonDecode(str) as Map).cast<String, List>();
      filelist.remove('/');

      _info = getUpdatableFiles(filelist);

      _isDataLoaded = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(20),
          width: double.infinity,
          height: double.infinity,
          child: IgnorePointer(
            ignoring: !isUiClickable,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _makeWidgets(),
            ),
          ),
        ),
      ),
    );
  }

  bool _isDownloading = false;
  double? _updateProg;

  bool get isUiClickable {
    return !_isDownloading && _updateProg == null;
  }

  Future<void> _download(Future<void> Function() callback) async {
    setState(() {
      _isDownloading = true;
    });

    await callback();

    setState(() {
      _isDownloading = false;
    });
  }

  _makeGroup(List<Widget> widgets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Column(children: widgets),
        ),
      ),
    );
  }

  final itemIntervalVert = SizedBox(height: 6);
  final itemIntervalHori = SizedBox(width: 6);

  _makeWidgets() {
    if (!_isDataLoaded) return [CircularProgressIndicator()];

    return <Widget>[
      _makeGroup(
        [
          Text(
            '''1. 자바가 설치되지 않은 경우
자바 설치 (설치된 경우 클릭 불가)

2. 포지가 설치되지 않은 경우
포지 인스톨러 실행 → OK 클릭 후 완료되면 닫기

설치됐는지 확실하지 않으면 위 내용을 전부 실행하세요.
문제 발생 시 관리자 권한으로 재시도하세요.''',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      _makeGroup(
        [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: hasFile(javaPath)
                    ? null
                    : () async {
                        _download(() async {
                          if (await downloadFileIfNotExist('java.exe', 'utils/JavaSetup.exe')) {
                            execute('$downloadPath/java.exe');
                          }
                        });
                      },
                child: Text('자바 설치'),
              ),
              itemIntervalVert,
              ElevatedButton(
                onPressed: () async {
                  _download(() async {
                    if (await downloadFileIfNotExist('forge.jar', 'utils/forge.jar')) {
                      openMessageDialog('알림',
                              '확인 버튼을 누르면 파일 탐색기가 열립니다. 직접 포지를 실행한 뒤 OK 버튼을 누르세요.\n\n두가지중 하나라도 정상 작동하면 나머지 하나는 실행하지 않아도 됩니다.')
                          .then(
                        (value) {
                          processForgeInstaller('$downloadPath/forge.jar');
                        },
                      );
                    }
                  });
                },
                child: Text('포지 인스톨러 실행'),
              ),
            ],
          ),
        ],
      ),
      _makeGroup(
        [
          _makeUpdateButton(),
          if (_updateProg != null) ...[
            itemIntervalVert,
            LinearProgressIndicator(
              value: _updateProg,
            ),
          ],
          itemIntervalVert,
          ElevatedButton(
            onPressed: () async {
              if (hasFile(mcLauncherPath)) {
                execute(mcLauncherPath);
              } else {
                _download(() async {
                  await openMessageDialog('알림', '마인크래프트 구런처가 없으므로 다운로드합니다.\n설치 프로그램이 열리면 설치를 진행하고 다시시도하세요.');

                  if (await downloadFileIfNotExist('mc_launcher.exe', 'utils/MinecraftInstaller.msi')) {
                    execute('$downloadPath/mc_launcher.exe');
                  }
                });
              }
            },
            child: Text('마인크래프트 런처 실행'),
          ),
        ],
      ),
      itemIntervalVert,
      _makeGroup(
        [
          ElevatedButton(
            onPressed: () {
              _loadData();
            },
            child: Text('새로고침'),
          ),
          ElevatedButton(
            onPressed: () {
              deleteDownloadCahces();

              _loadData();
            },
            child: Text('다운로드 캐시 제거'),
          ),
        ],
      ),
    ];
  }

  _makeUpdateButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_info.isLatest) {
          await openMessageDialog('알림', '이미 최신버전입니다.');
          return;
        }

        _update();
      },
      child: Column(
        children: [
          Text(_updateProg == null ? '모드 업데이트' : '모드 업데이트중...'),
          Text(
            _info.isLatest ? '현재 최신버전입니다.' : '업데이트가 필요합니다.',
            style: TextStyle(color: _info.isLatest ? Colors.grey : Colors.red, fontSize: 12),
          ),
        ],
      ),
    );
  }

  _update() async {
    _updateProg = 0;
    setState(() {});

    final res = await downloadFiles(
      _info.needUpdate.map((e) => '$gitUpdateFilesDirName/$e').toList(),
      onProgress: (prog) {
        setState(() {
          _updateProg = prog;
        });
      },
    );

    _updateProg = null;
    setState(() {});

    if (res) {
      if (await tryApplyFiles(context, _info)) {
        _info = getUpdatableFiles(_info.list); // 갱신

        showSnackBar('업데이트 완료');
        setState(() {});
      }
    }
  }
}
