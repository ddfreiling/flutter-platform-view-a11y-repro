# Results

Device: Samsung Galaxy S23 (SM-S911B), Android 17 (API 37), TalkBack 17.1, 1080 × 2340. TalkBack was on before each app start; every combination was force-stopped and relaunched (`am start -S`) before measuring.

Columns:

- **full dump**: native text present in `uiautomator dump`, which includes views that are not important for accessibility
- **compressed**: native text present in `uiautomator dump --compressed`, important views only, which is what TalkBack sees
- **swipe**: TalkBack reached the platform view content with swipe next or previous (8 + 8 swipes, `tools/tb.sh`)

Node counts are full / compressed. Raw output: `results/<version>.log` and `results/<version>/`.

## Flutter 3.47.2

| Variant | Mode | Full dump | Compressed | Swipe |
|---|---|---|---|---|
| `container` | HC | ✅ 19 | ❌ 11 | ❌ |
| `container` | TLHC | ✅ 19 | ❌ 11 | ❌ |
| `textview` | HC | ✅ 15 | ❌ 11 | ❌ |
| `textview` | TLHC | ✅ 15 | ❌ 11 | ❌ |
| `webview` | HC | ✅ 19 | ✅ 16 | ✅ |
| `webview` | TLHC | ✅ 19 | ✅ 16 | ✅ |
| `container_webview` | HC | ❌ 16 | ❌ 11 | ❌ |
| `container_webview` | TLHC | ❌ 16 | ❌ 11 | ❌ |
| `workaround` | HC | ✅ 19 | ✅ 15 | ✅ as one group |
| `workaround` | TLHC | ✅ 19 | ✅ 15 | ✅ as one group |

Swipe order, identical for HC and TLHC:

- failing variants: title > Flutter button above > **Flutter button below** > Flutter text below (and the reverse)
- `webview`: title > button above > WebView > Web text 1 > Web text 2 > Web text 3 > button below > text below
- `workaround`: title > button above > [Native text 1 + 2 + 3] > button below > text below

## Flutter 3.50.0 (latest stable)

Identical to 3.47.2 in every cell: same node counts, same native text presence, same swipe order. The `AUTO` lines in `AccessibilityBridge` are unchanged in 3.50.0 and on `master` as of 2026-11-13.

The first `webview/tlhc` run dumped the system Settings volume panel instead of the app (an accidental volume key press during the run); that combination was rerun and the rerun replaced it.

The 3.50.0 build used a temporary copy of `app/` with the Android Gradle Plugin raised from 9.1.0 to 9.1.1, the minimum 3.50.0 accepts; the committed app stays on 3.47.2.

## Notes

- **Composition mode confirmed from logcat** (`PlatformViewsController`): HC runs log "Using hybrid composition for platform view", TLHC runs log "Hosting view in view hierarchy for platform view" and "PlatformView is using SurfaceProducer backend". No run fell back to a virtual display.
- **`textview` fails too.** `TextView`'s constructor upgrades `AUTO` to `YES`, but the engine overwrites it with `NO_HIDE_DESCENDANTS` at creation and with `AUTO` when it links the view (inferred from reading `TextView` and `AccessibilityBridge`; the run confirms the TextView is missing from the compressed dump).
- **`container_webview` has no web text even in the full dump.** A WebView only builds its accessibility tree once a service queries it; nothing reaches it through the dead link. This differs from the original observation in a larger app, where the full dump did contain the web text (that run may have had touch exploration or other services querying the WebView first; not verified).
- **The workaround is reached as a single stop.** TalkBack focuses Flutter's own platform-view semantics node (focusable, bounds of the platform view) and reads the non-focusable `TextView`s under it as one group. A `WebView` root is entered and its paragraphs are visited one by one.
- **Touch exploration did not reach the failing content.** A held touch injected at (300, 620), on "Native text 3", left TalkBack focus on the title in `container` HC/TLHC, `container_webview` HC and `textview` HC; in `workaround` HC the same touch focused the native text group. The original observation said touch exploration did reach WebView text; that case had a WebView whose own nodes are important. Raw output: `results/3.47.2-touch/`.

## Manual TalkBack checks (3.47.2, by hand)

- **Issue code sample** (`issue-sample/`, built with `flutter create bug`): swipe right from "Flutter button above" goes straight to "Flutter button below", and swipe left skips back the same way. Dragging a finger over the native text gives no speech, only short TalkBack sounds.
- **`workaround / hc`**: the platform view is one TalkBack stop that reads the three texts together.
- **TalkBack turned on after opening `workaround / hc`**: same as above. The stuck-before-the-platform-view state seen in a larger app did not reproduce here (only this variant was tried).
