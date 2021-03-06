import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Plugin must be initialized before using
  await FlutterDownloader.initialize(
      debug:
          true // optional: set to false to disable printing logs to console (default: true)
      // ignoreSsl: true // option: set to false to disable working with http links (default: false)
      );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future processDownload(String url) async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      var baseStorage = await getExternalStorageDirectory();

      /// buat folder
      const directoryName = "audios";
      // final docDir = await getApplicationDocumentsDirectory();
      final myDir = Directory("${baseStorage!.path}/$directoryName/");
      Directory? dir;

      if (await myDir.exists()) {
        print(">>> Folder sudah ada !");
        dir = myDir;
        print(">>> dir : $dir");
        download(url, dir.path);
      } else {
        dir = await myDir.create(recursive: true);
        download(url, dir.path);
        print(">>> dir : $dir");
      }

      // baseStorage = "${baseStorage!.path}/audios/" as Directory?;
      // print(">>> basesotrage : ${baseStorage} ");

    }
  }

  Future<void> download(String url, String dir) async {
    await FlutterDownloader.enqueue(
      url: url,
      requiresStorageNotLow: true,
      savedDir: dir, //baseStorage!.path,
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
      saveInPublicStorage: false,
    );
  }

  Future<void> ReadFile(String nameFile) async {
    try {
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/$nameFile.mp3');
      // print(file);
      // var text = await file.readAsString();
      // print(">>>> baca text : $text");
      var baseStorage = await getExternalStorageDirectory();
      const directoryName = "audios";
      final myDir = Directory("${baseStorage!.path}/$directoryName/");
      print(">>> mydir : ${myDir.path}");
      var fullStringPath = "${myDir.path}$nameFile.mp3";
      print("fullString : $fullStringPath");

      var result = await File(fullStringPath).exists();

      // var result = await File(
      //         "/storage/emulated/0/Android/data/com.example.flutter_dwnloader/files/audios/" +
      //             nameFile +
      //             ".mp3")
      //     .exists();

      print(">>> Apakah file audio ada ? $result");
    } catch (e) {
      print('exception');
      print(e.toString());
    }
  }

  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      if (status == DownloadTaskStatus.complete) {
        print(">>> download completed ");
      }
      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            ElevatedButton(
                onPressed: () => ReadFile("1"), child: Text("ReadFile Dwn"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => processDownload(
            "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3"),
        tooltip: 'download',
        child: const Icon(Icons.add),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
