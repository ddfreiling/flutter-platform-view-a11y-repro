package com.example.platform_view_a11y_repro

import android.content.Context
import android.view.View
import android.webkit.WebView
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry
            .registerViewFactory("repro/native", NativeViewFactory())
    }
}

class NativeViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val variant = (args as Map<*, *>)["variant"] as String
        val root: View = when (variant) {
            // Plain container: not important for accessibility under AUTO.
            "container" -> FrameLayout(context).apply { addView(nativeTexts(context)) }
            // Single TextView root.
            "textview" -> TextView(context).apply { text = "Native single text"; textSize = 20f }
            // WebView root: important under AUTO because it has a node provider.
            "webview" -> webView(context)
            // Plain container around a WebView, like the layout where the bug was first seen.
            "container_webview" -> FrameLayout(context).apply { addView(webView(context)) }
            // Plain container that turns the bridge's AUTO into YES.
            "workaround" -> WorkaroundRoot(context).apply { addView(nativeTexts(context)) }
            else -> error("unknown variant $variant")
        }
        return object : PlatformView {
            override fun getView() = root
            override fun dispose() {}
        }
    }

    private fun nativeTexts(context: Context) = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        for (i in 1..3) addView(TextView(context).apply { text = "Native text $i"; textSize = 20f })
    }

    private fun webView(context: Context) = WebView(context).apply {
        loadData("<p>Web text 1</p><p>Web text 2</p><p>Web text 3</p>", "text/html", "utf-8")
    }
}

/**
 * The accessibility bridge sets the embedded view to AUTO each time it links it into the tree,
 * so a value set once is overwritten. Storing YES whenever AUTO is requested keeps the root
 * reportable to services that only see important views.
 */
class WorkaroundRoot(context: Context) : FrameLayout(context) {
    override fun setImportantForAccessibility(mode: Int) =
        super.setImportantForAccessibility(
            if (mode == IMPORTANT_FOR_ACCESSIBILITY_AUTO) IMPORTANT_FOR_ACCESSIBILITY_YES else mode,
        )
}
