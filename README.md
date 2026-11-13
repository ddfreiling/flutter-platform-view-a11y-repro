# Android platform view TalkBack repro

Minimal Flutter app showing that TalkBack swipe navigation skips an Android platform view whose root view is not important for accessibility under `IMPORTANT_FOR_ACCESSIBILITY_AUTO`, such as a plain `FrameLayout`, or a `TextView` (Flutter overwrites the `YES` a `TextView` gives itself).

The cause is in the engine's `AccessibilityBridge`: it links the platform view into its virtual node tree with `result.addChild(embeddedView)` after setting the view to `IMPORTANT_FOR_ACCESSIBILITY_AUTO`. A service that only sees important views (TalkBack) gets no node for that root, so the whole subtree is missing. See [issue-draft.md](issue-draft.md) for the full report and [results.md](results.md) for the measurements.

## What the app shows

One screen per combination: a Flutter title and button, a 250 dp high platform view, then a Flutter button and text. The platform view root is one of these variants (see `app/android/app/src/main/kotlin/.../MainActivity.kt`):

| Variant | Native root |
|---|---|
| `container` | `FrameLayout` > `LinearLayout` > 3 × `TextView` |
| `textview` | a single `TextView` |
| `webview` | a `WebView` with three paragraphs |
| `container_webview` | `FrameLayout` > `WebView` |
| `workaround` | like `container`, root forces `AUTO` to `YES` |

Each variant runs under two composition modes:

- `hc`: hybrid composition, `PlatformViewLink` + `PlatformViewsService.initExpensiveAndroidView`
- `tlhc`: texture layer hybrid composition, `AndroidView`

## Run

Flutter is pinned to 3.47.2 with fvm (`app/.fvmrc`).

```bash
cd app && fvm flutter run
```

Turn TalkBack on before opening a variant screen. Pick a combination from the menu, or open it directly:

```bash
adb shell am start -S -n com.example.platform_view_a11y_repro/.MainActivity --es route /container/hc
```

Then swipe right through the screen. With `container` or `textview`, TalkBack goes from "Flutter button above" straight to "Flutter button below". With `webview` or `workaround`, it stops on the platform view.

## Automated measurement

`tools/matrix.sh` runs every combination on a connected device with TalkBack on: `uiautomator dump` with and without `--compressed`, and 8 swipes next then 8 swipes previous through `tools/tb.sh`, which injects touches through a temporary uinput device so TalkBack sees them. `tools/summarize.py` labels each TalkBack focus rectangle with the matching node. The screen coordinates assume a 1080 × 2340 display.

```bash
TB_SERIAL=<adb serial> tools/matrix.sh results/<flutter version>
```
