import 'package:section_1/framework/element.dart';

abstract class MyWidget {
  const MyWidget();
  // 每一个 Widget 都要能创建属于自己的 Element
  MyElement createElement();
}
