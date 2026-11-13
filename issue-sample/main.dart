import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// true: hybrid composition (PlatformViewLink + initExpensiveAndroidView).
// false: texture layer hybrid composition (AndroidView). Both fail the same way.
const useHybridComposition = true;

void main() => runApp(const MaterialApp(home: ReproPage()));

class ReproPage extends StatelessWidget {
  const ReproPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Flutter button above')),
            SizedBox(height: 250, child: _platformView()),
            ElevatedButton(onPressed: () {}, child: const Text('Flutter button below')),
          ],
        ),
      ),
    );
  }

  Widget _platformView() {
    const viewType = 'repro/native';
    if (!useHybridComposition) return const AndroidView(viewType: viewType);
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (params) => PlatformViewsService.initExpensiveAndroidView(
        id: params.id,
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        onFocus: () => params.onFocusChanged(true),
      )
        ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
        ..create(),
    );
  }
}
