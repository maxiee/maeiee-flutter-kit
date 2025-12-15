import 'package:get/get.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_controller.dart';

class RepoToPromptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RepoToPromptController>(() => RepoToPromptController());
  }
}
