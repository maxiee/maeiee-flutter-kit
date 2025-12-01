import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_basic_demo/app/controllers/home_controller.dart';
import 'package:getx_basic_demo/app/views/pages/home_page.dart';

abstract class Routes {
  static const HOME = '/home';
  static const DETAILS = '/details';
}

class AppPages {
  static final pages = [
    GetPage(name: Routes.HOME, page: () => HomePage(), binding: HomeBinding()),
    GetPage(name: Routes.DETAILS, page: () => Placeholder()),
  ];
}
