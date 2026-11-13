import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const _viewType = 'repro/native';

/// Native root view variants, implemented in MainActivity.kt.
const variants = ['container', 'textview', 'webview', 'container_webview', 'workaround'];

/// hc: hybrid composition (PlatformViewLink + initExpensiveAndroidView).
/// tlhc: texture layer hybrid composition (AndroidView).
const modes = ['hc', 'tlhc'];

void main() => runApp(const ReproApp());

class ReproApp extends StatelessWidget {
  const ReproApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Open a variant directly with:
      // adb shell am start -n com.example.platform_view_a11y_repro/.MainActivity --es route /container/hc
      onGenerateInitialRoutes: (name) => [_route(name)],
      onGenerateRoute: (settings) => _route(settings.name ?? '/'),
    );
  }

  Route<void> _route(String name) {
    final parts = name.split('/').where((p) => p.isNotEmpty).toList();
    final page = parts.length == 2 && variants.contains(parts[0]) && modes.contains(parts[1])
        ? ReproPage(variant: parts[0], mode: parts[1])
        : const MenuPage();
    return MaterialPageRoute(builder: (_) => page, settings: RouteSettings(name: name));
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            for (final v in variants)
              for (final m in modes)
                ListTile(
                  title: Text('$v / $m'),
                  onTap: () => Navigator.pushNamed(context, '/$v/$m'),
                ),
          ],
        ),
      ),
    );
  }
}

class ReproPage extends StatelessWidget {
  const ReproPage({super.key, required this.variant, required this.mode});

  final String variant;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Variant $variant, mode $mode', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('Flutter button above')),
            const SizedBox(height: 16),
            SizedBox(height: 250, child: _platformView()),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('Flutter button below')),
            const SizedBox(height: 16),
            const Text('Flutter text below', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _platformView() {
    final params = {'variant': variant};
    if (mode == 'tlhc') {
      return AndroidView(
        viewType: _viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (p) => PlatformViewsService.initExpensiveAndroidView(
        id: p.id,
        viewType: _viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onFocus: () => p.onFocusChanged(true),
      )
        ..addOnPlatformViewCreatedListener(p.onPlatformViewCreated)
        ..create(),
    );
  }
}
