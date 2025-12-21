pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "FlutterBoostDemo"
include(":app")

// 绑定当前 Gradle 环境并解析 flutter_module 下的 include_flutter.groovy 脚本
apply(from = File(settingsDir.parentFile, "flutter_boost_demo_module/.android/include_flutter.groovy"))

include(":flutter_boost_demo_module")
project(":flutter_boost_demo_module").projectDir = File("../flutter_boost_demo_module")
 