package com.maxiee.flutterboost.demo

import android.app.Application
import android.content.Intent
import com.idlefish.flutterboost.FlutterBoost
import com.idlefish.flutterboost.FlutterBoostDelegate
import com.idlefish.flutterboost.FlutterBoostRouteOptions
import com.idlefish.flutterboost.containers.FlutterBoostActivity

class MyApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // 初始化 FlutterBoost
        FlutterBoost.instance().setup(this, object : FlutterBoostDelegate {

            /**
             * 当 Flutter 想要跳转到 Native 页面时调用
             */
            override fun pushNativeRoute(options: FlutterBoostRouteOptions) {
                // options.pageName() 是 Flutter 传过来的路由名
                if ("nativePage" == options.pageName()) {
                    val intent = Intent(FlutterBoost.instance().currentActivity(), NativePageActivity::class.java)
                    // 还可以传递参数
                    // intent.putExtra("key", options.arguments() as Serializable)
                    FlutterBoost.instance().currentActivity().startActivityForResult(intent, options.requestCode())
                } else {
                    // 处理其他原生页面跳转
                }
            }

            /**
             * 当 Flutter 想要跳转到 另一个 Flutter 页面（且需要新容器）时调用
             */
            override fun pushFlutterRoute(options: FlutterBoostRouteOptions) {
                val intent = FlutterBoostActivity.CachedEngineIntentBuilder(FlutterBoostActivity::class.java)
                    .destroyEngineWithActivity(false) // Activity销毁时不销毁引擎
                    .uniqueId(options.uniqueId()) // 必传：页面唯一ID
                    .url(options.pageName()) // 必传：页面路由名
                    .urlParams(options.arguments()) // 必传：参数
                    .build(FlutterBoost.instance().currentActivity())

                FlutterBoost.instance().currentActivity().startActivity(intent)
            }
        }) { engine ->
            // 引擎初始化后的回调，可以在这里注册其他 Flutter 插件
        }
    }
}
