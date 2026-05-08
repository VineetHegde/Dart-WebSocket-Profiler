# WebSocket Profiler Sample
This is a prerequisite task for the GSoC 2026 Dart project.

## Documentation
To understand how this profiler bypasses standard application-layer wrappers and intercepts traffic directly at the Dart SDK level without memory exhaustion, read the [Technical Architecture Document](ARCHITECTURE.md).

## How to Run
1. Ensure you have the [Dart SDK](https://dart.dev/get-dart) installed.
2. Run `dart pub get` to fetch dependencies.
3. Run `dart run websocket_profiler.dart` to start the CLI
![WebSocket Profiler CLI Output](assets/cli_screenshot.png)
