package com.example.bug

import android.content.Context
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "repro/native",
            object : PlatformViewFactory(null) {
                override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                    // A plain container root. Its TextViews are important for accessibility,
                    // the container itself is not.
                    val root = FrameLayout(context).apply {
                        addView(LinearLayout(context).apply {
                            orientation = LinearLayout.VERTICAL
                            for (i in 1..3) addView(TextView(context).apply { text = "Native text $i"; textSize = 20f })
                        })
                    }
                    return object : PlatformView {
                        override fun getView() = root
                        override fun dispose() {}
                    }
                }
            },
        )
    }
}
