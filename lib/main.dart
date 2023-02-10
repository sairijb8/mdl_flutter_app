import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mdl_flutter_app/splash_screen.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(GetMaterialApp(home: SplashScreen()));
}

