// import 'dart:io';
// import 'dart:async';
// import 'dart:convert';
// import 'dart:collection';

// enum TrafficDirection { incoming, outgoing }
// enum TrafficType { text, binary, unknown }

// /// Represents a single WebSocket frame or data event.
// class SocketEvent {
//   final DateTime timestamp;
//   final int byteSize;
//   final TrafficDirection direction; 
//   final TrafficType type;      

//   SocketEvent({
//     required this.timestamp,
//     required this.byteSize,
//     required this.direction,
//     required this.type,
//   });

//   /// Serializes the event for transport over the VM Service extension.
//   Map<String, dynamic> toJson() {
//     return {
//       'timestamp': timestamp.toIso8601String(),
//       'byteSize': byteSize,
//       'direction': direction.name,
//       'type': type.name,
//     };
//   }

//   @override
//   String toString() {
//     final timeStr = timestamp.toIso8601String().replaceFirst('T', ' ').substring(0, 23);
//     return '[$timeStr] ${direction.name.toUpperCase()} (${type.name}) - $byteSize bytes';
//   }
// }

// /// A wrapper around [WebSocket] that intercepts and profiles bidirectional network traffic.
// class ProfileableWebSocket implements WebSocket {
//   final WebSocket _inner;
  
//   // Internal traffic buffer.
//   final List<SocketEvent> _trafficLogs = [];

//   /// A read-only view of the traffic logs.
//   UnmodifiableListView<SocketEvent> get trafficLogs => UnmodifiableListView(_trafficLogs);

//   final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();

//   ProfileableWebSocket(this._inner) {
//     _inner.listen(
//       (data) {
//         _logTraffic(data, TrafficDirection.incoming);
//         _controller.add(data); 
//       },
//       onError: (error, stackTrace) => _controller.addError(error, stackTrace),
//       onDone: () => _controller.close(),
//     );
//   }

//   /// Dispatches traffic metadata to the internal log buffer.
//   /// 
//   /// Automatically calculates true network byte size for Strings and Lists 
//   /// if [knownSize] is not provided.
//   void _logTraffic(dynamic data, TrafficDirection direction, {TrafficType? knownType, int? knownSize}) {
//     int size = knownSize ?? 0;
//     TrafficType type = knownType ?? TrafficType.unknown;

//     if (knownSize == null) {
//       if (data is String) {
//         size = utf8.encode(data).length;
//         type = knownType ?? TrafficType.text;
//       } else if (data is List<int>) {
//         size = data.length;
//         type = knownType ?? TrafficType.binary;
//       }
//     }

//     // Enforce a 1000-item ring buffer to prevent DevTools memory exhaustion.
//     if (_trafficLogs.length >= 1000) {
//       _trafficLogs.removeAt(0); 
//     }

//     _trafficLogs.add(SocketEvent(
//       timestamp: DateTime.now(),
//       byteSize: size,
//       direction: direction,
//       type: type,
//     ));
//   }

//   // Intercept outgoing add events.
//   @override
//   void add(data) {
//     _logTraffic(data, TrafficDirection.outgoing);
//     _inner.add(data);
//   }

//   // Forward Stream methods to the intercepted controller.
//   @override
//   StreamSubscription listen(void Function(dynamic event)? onData,
//           {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
//       _controller.stream.listen(onData,
//           onError: onError, onDone: onDone, cancelOnError: cancelOnError);

//   @override
//   Future<bool> any(bool Function(dynamic element) test) => _controller.stream.any(test);
  
//   @override
//   Stream<dynamic> asBroadcastStream({void Function(StreamSubscription<dynamic> subscription)? onListen, void Function(StreamSubscription<dynamic> subscription)? onCancel}) => _controller.stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  
//   @override
//   Stream<E> asyncExpand<E>(Stream<E>? Function(dynamic event) convert) => _controller.stream.asyncExpand(convert);
  
//   @override
//   Stream<E> asyncMap<E>(FutureOr<E> Function(dynamic event) convert) => _controller.stream.asyncMap(convert);
  
//   @override
//   Stream<R> cast<R>() => _controller.stream.cast<R>();
  
//   @override
//   Future<bool> contains(Object? needle) => _controller.stream.contains(needle);
  
//   @override
//   Stream<dynamic> distinct([bool Function(dynamic previous, dynamic next)? equals]) => _controller.stream.distinct(equals);
  
//   @override
//   Future<E> drain<E>([E? futureValue]) => _controller.stream.drain(futureValue);
  
//   @override
//   Future<dynamic> elementAt(int index) => _controller.stream.elementAt(index);
  
//   @override
//   Future<bool> every(bool Function(dynamic element) test) => _controller.stream.every(test);
  
//   @override
//   Stream<S> expand<S>(Iterable<S> Function(dynamic element) convert) => _controller.stream.expand(convert);
  
//   @override
//   Future<dynamic> get first => _controller.stream.first;
  
//   @override
//   Future<dynamic> firstWhere(bool Function(dynamic element) test, {dynamic Function()? orElse}) => _controller.stream.firstWhere(test, orElse: orElse);
  
//   @override
//   Future<S> fold<S>(S initialValue, S Function(S previous, dynamic element) combine) => _controller.stream.fold(initialValue, combine);
  
//   @override
//   Future<dynamic> forEach(void Function(dynamic element) action) => _controller.stream.forEach(action);
  
//   @override
//   Stream<dynamic> handleError(Function onError, {bool Function(dynamic error)? test}) => _controller.stream.handleError(onError, test: test);
  
//   @override
//   bool get isBroadcast => _controller.stream.isBroadcast;
  
//   @override
//   Future<bool> get isEmpty => _controller.stream.isEmpty;
  
//   @override
//   Future<String> join([String separator = ""]) => _controller.stream.join(separator);
  
//   @override
//   Future<dynamic> get last => _controller.stream.last;
  
//   @override
//   Future<dynamic> lastWhere(bool Function(dynamic element) test, {dynamic Function()? orElse}) => _controller.stream.lastWhere(test, orElse: orElse);
  
//   @override
//   Future<int> get length => _controller.stream.length;
  
//   @override
//   Stream<S> map<S>(S Function(dynamic event) convert) => _controller.stream.map(convert);
  
//   @override
//   Future<dynamic> pipe(StreamConsumer<dynamic> streamConsumer) => _controller.stream.pipe(streamConsumer);
  
//   @override
//   Future<dynamic> reduce(dynamic Function(dynamic previous, dynamic element) combine) => _controller.stream.reduce(combine);
  
//   @override
//   Future<dynamic> get single => _controller.stream.single;
  
//   @override
//   Future<dynamic> singleWhere(bool Function(dynamic element) test, {dynamic Function()? orElse}) => _controller.stream.singleWhere(test, orElse: orElse);
  
//   @override
//   Stream<dynamic> skip(int count) => _controller.stream.skip(count);
  
//   @override
//   Stream<dynamic> skipWhile(bool Function(dynamic element) test) => _controller.stream.skipWhile(test);
  
//   @override
//   Stream<dynamic> take(int count) => _controller.stream.take(count);
  
//   @override
//   Stream<dynamic> takeWhile(bool Function(dynamic element) test) => _controller.stream.takeWhile(test);
  
//   @override
//   Stream<dynamic> timeout(Duration timeLimit, {void Function(EventSink<dynamic> sink)? onTimeout}) => _controller.stream.timeout(timeLimit, onTimeout: onTimeout);
  
//   @override
//   Future<List<dynamic>> toList() => _controller.stream.toList();
  
//   @override
//   Future<Set<dynamic>> toSet() => _controller.stream.toSet();
  
//   @override
//   Stream<dynamic> where(bool Function(dynamic event) test) => _controller.stream.where(test);
  
//   @override
//   Stream<S> transform<S>(StreamTransformer<dynamic, S> streamTransformer) => _controller.stream.transform(streamTransformer);

//   // WebSocket state properties forward directly to the underlying socket.
//   @override
//   int? get closeCode => _inner.closeCode;
//   @override
//   String? get closeReason => _inner.closeReason;
//   @override
//   Duration? get pingInterval => _inner.pingInterval;
//   @override
//   set pingInterval(Duration? pingInterval) => _inner.pingInterval = pingInterval;
//   @override
//   int get readyState => _inner.readyState;
//   @override
//   String get extensions => _inner.extensions;
//   @override
//   String? get protocol => _inner.protocol;

//   @override
//   Future close([int? code, String? reason]) {
//     if (!_controller.isClosed) {
//       _controller.close();
//     }
//     return _inner.close(code, reason);
//   }

//   @override
//   void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);
  
//   @override
//   void addUtf8Text(List<int> bytes) {
//     // Skip utf8 encoding calculation since byte length is already known.
//     _logTraffic(bytes, TrafficDirection.outgoing, knownType: TrafficType.text, knownSize: bytes.length);
//     _inner.addUtf8Text(bytes);
//   }

//   // Intercept data added via streams.
//   @override
//   Future addStream(Stream stream) {
//     final interceptedStream = stream.map((data) {
//       _logTraffic(data, TrafficDirection.outgoing);
//       return data;
//     });
//     return _inner.addStream(interceptedStream);
//   }

//   @override
//   Future get done => _inner.done;
// }

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';

enum TrafficDirection { incoming, outgoing }
enum TrafficType { text, binary, unknown }

class SocketEvent {
  final DateTime timestamp;
  final int byteSize;
  final TrafficDirection direction; 
  final TrafficType type;      

  SocketEvent({
    required this.timestamp,
    required this.byteSize,
    required this.direction,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'byteSize': byteSize,
      'direction': direction.name,
      'type': type.name,
    };
  }

  @override
  String toString() {
    final timeStr = timestamp.toIso8601String().replaceFirst('T', ' ').substring(0, 23);
    return '[$timeStr] ${direction.name.toUpperCase()} (${type.name}) - $byteSize bytes';
  }
}

class ProfileableWebSocket implements WebSocket {
  final WebSocket _inner;
  
  final List<SocketEvent> _trafficLogs = [];

  UnmodifiableListView<SocketEvent> get trafficLogs => UnmodifiableListView(_trafficLogs);

  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();

  ProfileableWebSocket(this._inner) {
    _inner.listen(
      (data) {
        _logTraffic(data, TrafficDirection.incoming);
        _controller.add(data); 
      },
      onError: (error, stackTrace) => _controller.addError(error, stackTrace),
      onDone: () => _controller.close(),
    );
  }

  void _logTraffic(dynamic data, TrafficDirection direction, {TrafficType? knownType, int? knownSize}) {
    int size = knownSize ?? 0;
    TrafficType type = knownType ?? TrafficType.unknown;

    if (knownSize == null) {
      if (data is String) {
        size = utf8.encode(data).length;
        type = knownType ?? TrafficType.text;
      } else if (data is List<int>) {
        size = data.length;
        type = knownType ?? TrafficType.binary;
      }
    }

    if (_trafficLogs.length >= 1000) {
      _trafficLogs.removeAt(0); 
    }

    _trafficLogs.add(SocketEvent(
      timestamp: DateTime.now(),
      byteSize: size,
      direction: direction,
      type: type,
    ));
  }

  @override
  void add(data) {
    _logTraffic(data, TrafficDirection.outgoing);
    _inner.add(data);
  }

  @override
  StreamSubscription listen(void Function(dynamic event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  Future<bool> any(bool Function(dynamic element) test) => _controller.stream.any(test);
  
  @override
  Stream<dynamic> asBroadcastStream({void Function(StreamSubscription<dynamic> subscription)? onListen, void Function(StreamSubscription<dynamic> subscription)? onCancel}) => _controller.stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  
  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(dynamic event) convert) => _controller.stream.asyncExpand(convert);
  
  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(dynamic event) convert) => _controller.stream.asyncMap(convert);
  
  @override
  Stream<R> cast<R>() => _controller.stream.cast<R>();
  
  @override
  Future<bool> contains(Object? needle) => _controller.stream.contains(needle);
  
  @override
  Stream<dynamic> distinct([bool Function(dynamic previous, dynamic next)? equals]) => _controller.stream.distinct(equals);
  
  @override
  Future<E> drain<E>([E? futureValue]) => _controller.stream.drain(futureValue);
  
  @override
  Future<dynamic> elementAt(int index) => _controller.stream.elementAt(index);
  
  @override
  Future<bool> every(bool Function(dynamic element) test) => _controller.stream.every(test);
  
  @override
  Stream<S> expand<S>(Iterable<S> Function(dynamic element) convert) => _controller.stream.expand(convert);
  
  @override
  Future<dynamic> get first => _controller.stream.first;
  
  @override
  Future<dynamic> firstWhere(bool Function(dynamic element) test, {dynamic Function()? orElse}) => _controller.stream.firstWhere(test, orElse: orElse);
  
  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, dynamic element) combine) => _controller.stream.fold(initialValue, combine);
  
  @override
  Future<dynamic> forEach(void Function(dynamic element) action) => _controller.stream.forEach(action);
  
  @override
  Stream<dynamic> handleError(Function onError, {bool Function(dynamic error)? test}) => _controller.stream.handleError(onError, test: test);
  
  @override
  bool get isBroadcast => _controller.stream.isBroadcast;
  
  @override
  Future<bool> get isEmpty => _controller.stream.isEmpty;
  
  @override
  Future<String> join([String separator = ""]) => _controller.stream.join(separator);
  
  @override
  Future<dynamic> get last => _controller.stream.last;
  
  @override
  Future<dynamic> lastWhere(bool Function(dynamic element) test, {dynamic Function()? orElse}) => _controller.stream.lastWhere(test, orElse: orElse);
  
  @override
  Future<int> get length => _controller.stream.length;
  
  @override
  Stream<S> map<S>(S Function(dynamic event) convert) => _controller.stream.map(convert);
  
  @override
  Future<dynamic> pipe(StreamConsumer<dynamic> streamConsumer) => _controller.stream.pipe(streamConsumer);
  
  @override
  Future<dynamic> reduce(dynamic Function(dynamic previous, dynamic element) combine) => _controller.stream.reduce(combine);
  
  @override
  Future<dynamic> get single => _controller.stream.single;
  
  @override
  Future<dynamic> singleWhere(bool Function(dynamic element) test, {dynamic Function()? orElse}) => _controller.stream.singleWhere(test, orElse: orElse);
  
  @override
  Stream<dynamic> skip(int count) => _controller.stream.skip(count);
  
  @override
  Stream<dynamic> skipWhile(bool Function(dynamic element) test) => _controller.stream.skipWhile(test);
  
  @override
  Stream<dynamic> take(int count) => _controller.stream.take(count);
  
  @override
  Stream<dynamic> takeWhile(bool Function(dynamic element) test) => _controller.stream.takeWhile(test);
  
  @override
  Stream<dynamic> timeout(Duration timeLimit, {void Function(EventSink<dynamic> sink)? onTimeout}) => _controller.stream.timeout(timeLimit, onTimeout: onTimeout);
  
  @override
  Future<List<dynamic>> toList() => _controller.stream.toList();
  
  @override
  Future<Set<dynamic>> toSet() => _controller.stream.toSet();
  
  @override
  Stream<dynamic> where(bool Function(dynamic event) test) => _controller.stream.where(test);
  
  @override
  Stream<S> transform<S>(StreamTransformer<dynamic, S> streamTransformer) => _controller.stream.transform(streamTransformer);

  @override
  int? get closeCode => _inner.closeCode;
  @override
  String? get closeReason => _inner.closeReason;
  @override
  Duration? get pingInterval => _inner.pingInterval;
  @override
  set pingInterval(Duration? pingInterval) => _inner.pingInterval = pingInterval;
  @override
  int get readyState => _inner.readyState;
  @override
  String get extensions => _inner.extensions;
  @override
  String? get protocol => _inner.protocol;

  @override
  Future close([int? code, String? reason]) {
    if (!_controller.isClosed) {
      _controller.close();
    }
    return _inner.close(code, reason);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);
  
  @override
  void addUtf8Text(List<int> bytes) {
    _logTraffic(bytes, TrafficDirection.outgoing, knownType: TrafficType.text, knownSize: bytes.length);
    _inner.addUtf8Text(bytes);
  }

  @override
  Future addStream(Stream stream) {
    final interceptedStream = stream.map((data) {
      _logTraffic(data, TrafficDirection.outgoing);
      return data;
    });
    return _inner.addStream(interceptedStream);
  }

  @override
  Future get done => _inner.done;
}