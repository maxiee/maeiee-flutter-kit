// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
}

subprojects {
    afterEvaluate {
        if (name == "flutter_boost") {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.namespace = "com.idlefish.flutterboost"
        }
    }
}