import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class Routes {
  static const HOME = '/home';
  static const DETAILS = '/details';
}

class AppPages {
  static final pages = [
    GetPage(name: Routes.HOME, page: () => Placeholder()),
    GetPage(name: Routes.DETAILS, page: () => Placeholder()),
  ];
}
