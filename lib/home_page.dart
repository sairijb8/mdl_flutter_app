import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:get/get.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getwidget/getwidget.dart';
import 'package:wakelock/wakelock.dart';
import 'package:system_alert_window/system_alert_window.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  //String _scanBarcode = 'Unknown';
  final GlobalKey webViewKey = GlobalKey();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<int> _counter;
  int _tutup = 0;
  int _buka = 0;
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(

      crossPlatform: InAppWebViewOptions(
        userAgent: "safemoodlebrowser android",
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();


  @override
  void initState() {
    secureScreen();
    super.initState();
    Wakelock.enable();
    WidgetsBinding.instance.addObserver(this);
    //startBarcodeScanStream();
    //webViewController?.loadUrl(urlRequest: URLRequest(url: Uri.parse(widget.title)));
    //print(widget.title+"ada");
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  Future<void> _incrementCounter(int durasi) async {
    _tutup = durasi;
  }

  Future<void> _cekDurasi() async {
    _buka = DateTime
           .now()
           .millisecondsSinceEpoch;
    int durasi = ((_buka - _tutup)/ 1000).floor();
    print(durasi);
    if (durasi > 5){
      webViewController?.clearCache();
    }
  }

  Future<void> secureScreen() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("Resumed");
      _cekDurasi();
    }
    if (state == AppLifecycleState.detached) {
      print("Detached");
    }
    if (state == AppLifecycleState.inactive) {
      print("Inactive");
       _incrementCounter(DateTime.now().millisecondsSinceEpoch);
    }
    if (state == AppLifecycleState.paused) {
      print("Paused");
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //appBar: AppBar(title: Text("Official InAppWebView website")),
        body: DoubleBackToCloseApp(
          snackBar: const SnackBar(
            content: Text('Tekan tombol back kembali untuk keluar aplikasi'),
          ),
          child: SafeArea(
              child: Column(children: <Widget>[
                Expanded(
                  child: Stack(
                    children: [
                      InAppWebView(
                        key: webViewKey,
                        initialUrlRequest: URLRequest(url: Uri.parse(widget.title)),
                        initialOptions: options,
                        pullToRefreshController: pullToRefreshController,
                        onWebViewCreated: (controller) {
                          webViewController = controller;
                        },
                        onLoadStart: (controller, url) {
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        androidOnPermissionRequest: (controller, origin, resources) async {
                          return PermissionRequestResponse(
                              resources: resources,
                              action: PermissionRequestResponseAction.GRANT);
                        },
                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                          var uri = navigationAction.request.url!;

                          if (![ "http", "https", "file", "chrome",
                            "data", "javascript", "about"].contains(uri.scheme)) {
                            if (await canLaunch(url)) {
                              // Launch the App
                              await launch(
                                url,
                              );
                              // and cancel the request
                              return NavigationActionPolicy.CANCEL;
                            }
                          }

                          return NavigationActionPolicy.ALLOW;
                        },
                        onLoadStop: (controller, url) async {
                          pullToRefreshController.endRefreshing();
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onLoadError: (controller, url, code, message) {
                          pullToRefreshController.endRefreshing();
                        },
                        onProgressChanged: (controller, progress) {
                          if (progress == 100) {
                            pullToRefreshController.endRefreshing();
                          }
                          setState(() {
                            this.progress = progress / 100;
                            urlController.text = this.url;
                          });
                        },
                        onUpdateVisitedHistory: (controller, url, androidIsReload) {
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onConsoleMessage: (controller, consoleMessage) {
                          print(consoleMessage);
                        },
                      ),
                      progress < 1.0
                          ? LinearProgressIndicator(value: progress)
                          : Container(),
                    ],
                  ),
                ),
                GFButtonBar(
                  children: <Widget>[
                    GFButton(
                      onPressed: (){
                        webViewController?.goBack();
                      },
                      text: "Kembali",
                      icon: Icon(Icons.arrow_back),
                      type: GFButtonType.solid,
                    ),
                    GFButton(
                      onPressed: (){
                        webViewController?.goForward();
                      },
                      text: "Maju",
                      icon: Icon(Icons.arrow_forward),
                      type: GFButtonType.solid,
                    ),
                    GFButton(
                      onPressed: (){
                        webViewController?.reload();
                      },
                      text: "Refresh",
                      icon: Icon(Icons.refresh),
                      type: GFButtonType.solid,
                    ),
                  ],
                ),
              ])),
        )
    );
  }
}