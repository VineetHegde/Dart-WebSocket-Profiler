import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../lib/profileable_web_socket.dart';

Future<void> main() async {
  final targetUrl = 'wss://ws.postman-echo.com/raw';
  print('Connecting to $targetUrl...');
  
  late WebSocket rawSocket;
  try {
    rawSocket = await WebSocket.connect(targetUrl);
    rawSocket.pingInterval = const Duration(seconds: 15);
  } catch (e) {
    stderr.writeln('Connection failed: $e');
    exit(1);
  }

  final socket = ProfileableWebSocket(rawSocket);
  
  print('Connected. Protocol: ${rawSocket.protocol ?? "none"}');
  print('Type a message to send, or "exit" to quit.\n');

  socket.listen(
    (message) {
      print('\n<<< $message');
      _printTrafficTable(socket.trafficLogs);
      stdout.write('> '); 
    },
    onError: (error) => stderr.writeln('\n[Error]: $error'),
    onDone: () {
      print('\n[Closed by Server]');
      exit(0);
    },
  );

  stdout.write('> ');
  
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((input) async {
    if (input.trim().toLowerCase() == 'exit') {
      await socket.close(WebSocketStatus.normalClosure);
      exit(0);
    }
    
    socket.add(input);
  });
}

/// Renders the 10 most recent traffic logs in an ASCII table.
void _printTrafficTable(List<SocketEvent> logs) {
  print('\n${'=' * 55}');
  print('                WEBSOCKET TRAFFIC LOGS                 ');
  print('${'=' * 55}');
  print('| ${'TIMESTAMP'.padRight(23)} | ${'DIR'.padRight(8)} | ${'TYPE'.padRight(6)} | ${'BYTES'.padRight(5)} |');
  print('${'-' * 55}');

  final recentLogs = logs.length > 10 ? logs.sublist(logs.length - 10) : logs;
  
  for (var log in recentLogs) {
    final timeStr = log.timestamp.toIso8601String().replaceFirst('T', ' ').substring(0, 23);
    print('| ${timeStr.padRight(23)} | ${log.direction.name.toUpperCase().padRight(8)} | ${log.type.name.toUpperCase().padRight(6)} | ${log.byteSize.toString().padRight(5)} |');
  }
  print('${'=' * 55}\n');
}